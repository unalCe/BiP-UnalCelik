import ImageCacheKit
import UIKit
import XCTest
@testable import CommonUI

/// Holds the load open so the view can be observed while its image is pending.
private final class SlowImageLoader: ImageLoaderInterface, @unchecked Sendable {
    private let released = AsyncStream<Void>.makeStream()

    func release() { released.continuation.finish() }

    func image(for request: ImageRequest) async throws -> UIImage {
        for await _ in released.stream {}
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10), format: format)
            .image { _ in UIColor.gray.setFill() }
    }
}

/// Fails on demand, counting attempts so a retry loop is visible to a test.
private final class FailingImageLoader: ImageLoaderInterface, @unchecked Sendable {
    private let lock = NSLock()
    private var attempts = 0
    private let error: any Error

    init(error: any Error = ImageLoadingError.invalidData) { self.error = error }

    var attemptCount: Int { lock.withLock { attempts } }

    func image(for request: ImageRequest) async throws -> UIImage {
        lock.withLock { attempts += 1 }
        throw error
    }
}

@MainActor
final class CachedImageViewTests: XCTestCase {
    private let url = URL(string: "https://example.com/1.jpg")!

    private var window: UIWindow!

    /// In a window on purpose: a detached layer drops its animations, which
    /// makes "the sweep stopped" true for the wrong reason.
    private func makeSUT(loader: any ImageLoaderInterface) -> CachedImageView {
        let sut = CachedImageView(loader: loader)
        sut.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.addSubview(sut)
        window.makeKeyAndVisible()
        return sut
    }

    func test_pendingImage_sweeps() async {
        let sut = makeSUT(loader: SlowImageLoader())

        sut.setImage(from: url)
        sut.layoutIfNeeded()

        XCTAssertTrue(sut.isSweeping, "a pending image must not sit there looking static")
    }

    func test_sweepStopsOnceTheImageLands() async {
        let loader = SlowImageLoader()
        let sut = makeSUT(loader: loader)
        sut.setImage(from: url)
        sut.layoutIfNeeded()

        loader.release()
        await waitUntil { sut.image != nil }

        XCTAssertNotNil(sut.image)
        XCTAssertFalse(sut.isSweeping, "the sweep must not run on behind a visible image")
    }

    /// Yield-counting is not a bound on real async work — a deadline is.
    private func waitUntil(
        _ condition: () -> Bool,
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(for: .milliseconds(5))
        }
        XCTAssertTrue(condition(), "timed out", file: file, line: line)
    }

    func test_cancelStopsTheSweep() {
        let sut = makeSUT(loader: SlowImageLoader())
        sut.setImage(from: url)
        sut.layoutIfNeeded()

        // what prepareForReuse calls
        sut.cancel()

        XCTAssertFalse(sut.isSweeping, "cell reuse must not leak an animation")
    }

    func test_noURL_doesNotSweep() {
        let sut = makeSUT(loader: SlowImageLoader())

        sut.setImage(from: nil)
        sut.layoutIfNeeded()

        XCTAssertFalse(sut.isSweeping)
    }

    func test_loadFailure_stopsTheSweepAndShowsThePlaceholder() async {
        let sut = makeSUT(loader: FailingImageLoader())
        sut.setImage(from: url)
        sut.layoutIfNeeded()

        await waitUntil { sut.isShowingFailure }

        XCTAssertFalse(sut.isSweeping, "a failed load must not shimmer forever")
        XCTAssertEqual(sut.accessibilityLabel, "Image unavailable",
                       "a broken image must not read as a loading one")
    }

    func test_loadFailure_doesNotRetryOnEveryLayoutPass() async {
        let loader = FailingImageLoader()
        let sut = makeSUT(loader: loader)
        sut.setImage(from: url)
        sut.layoutIfNeeded()

        await waitUntil { sut.isShowingFailure }
        // the placeholder invalidates intrinsicContentSize, so this is the pass
        // the failure itself provokes
        sut.setNeedsLayout()
        sut.layoutIfNeeded()

        XCTAssertEqual(loader.attemptCount, 1, "the same request must not loop")
    }

    func test_reconfiguringAfterAFailureRetries() async {
        let loader = FailingImageLoader()
        let sut = makeSUT(loader: loader)
        sut.setImage(from: url)
        sut.layoutIfNeeded()
        await waitUntil { sut.isShowingFailure }

        // what a reused cell does
        sut.setImage(from: url)
        sut.layoutIfNeeded()

        await waitUntil { loader.attemptCount == 2 }
        XCTAssertEqual(loader.attemptCount, 2, "a reused cell must get a fresh attempt")
    }

    func test_cancellationIsNotAFailure() async {
        let loader = FailingImageLoader(error: CancellationError())
        let sut = makeSUT(loader: loader)
        sut.setImage(from: url)
        sut.layoutIfNeeded()

        await waitUntil { loader.attemptCount == 1 }
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertFalse(sut.isShowingFailure,
                       "a resize cancels the load; flashing a broken image there is the bug")
        XCTAssertTrue(sut.isSweeping)
    }
}
