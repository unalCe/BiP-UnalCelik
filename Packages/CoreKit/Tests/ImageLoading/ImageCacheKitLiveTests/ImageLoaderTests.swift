import ImageCacheKit
import NetworkingKit
import NetworkingKitMocks
import UIKit
import XCTest
@testable import ImageCacheKitLive

final class ImageLoaderTests: XCTestCase {
    private let request = ImageRequest(
        url: URL(string: "https://example.com/images/1.jpg")!,
        maxPixelSize: 256
    )

    func test_cacheHit_doesNotTouchTheNetwork() async throws {
        let cached = UIImage()
        let client = MockHTTPClient(always: .ok(Data("network-bytes".utf8)))
        let sut = ImageLoader(
            client: client,
            cache: StubImageCache(seed: [request: cached]),
            downsampler: StubDownsampler()
        )

        let image = try await sut.image(for: request)

        XCTAssertTrue(image === cached)
        XCTAssertEqual(client.sendCount, 0)
    }

    func test_cacheMiss_fetchesDownsamplesThenStores() async throws {
        let client = MockHTTPClient(always: .ok(Data("network-bytes".utf8)))
        let cache = StubImageCache()
        let downsampler = StubDownsampler()
        let sut = ImageLoader(client: client, cache: cache, downsampler: downsampler)

        _ = try await sut.image(for: request)

        XCTAssertEqual(client.sendCount, 1)
        XCTAssertEqual(downsampler.callCount, 1)
        XCTAssertEqual(cache.insertCount, 1)
    }

    func test_transportFailure_propagates() async {
        let client = MockHTTPClient(always: .offline)
        let sut = ImageLoader(
            client: client,
            cache: StubImageCache(),
            downsampler: StubDownsampler()
        )

        do {
            _ = try await sut.image(for: request)
            XCTFail("expected a failure")
        } catch let error as NetworkError {
            XCTAssertTrue(error.isOffline)
        } catch {
            XCTFail("expected NetworkError, got \(error)")
        }
    }
}

// MARK: - Doubles

/// The cache and downsampler are internal to ImageCacheKitLive, so their
/// doubles live here rather than in ImageCacheKitMocks.
private final class StubImageCache: DecodedImageCaching, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [ImageRequest: UIImage]
    private var inserts = 0

    var insertCount: Int { lock.withLock { inserts } }

    init(seed: [ImageRequest: UIImage] = [:]) { self.storage = seed }

    func image(for request: ImageRequest) -> UIImage? {
        lock.withLock { storage[request] }
    }

    func insert(_ image: UIImage, for request: ImageRequest) {
        lock.withLock {
            inserts += 1
            storage[request] = image
        }
    }

    func removeAll() { lock.withLock { storage.removeAll() } }
}

private final class StubDownsampler: ImageDownsampling, @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0

    var callCount: Int { lock.withLock { calls } }

    func downsample(_ data: Data, maxPixelSize: Int, scale: CGFloat) async throws -> UIImage {
        lock.withLock { calls += 1 }
        return UIImage()
    }
}
