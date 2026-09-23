import ImageCacheKit
import UIKit
import XCTest

@testable import ImageCacheKitLive

/// Downloads are held open by `GatedHTTPClient` until a test releases them, so
/// the in-flight state can be read without racing the network.
final class ImagePrefetcherTests: XCTestCase {
    private var prefetcher: ImagePrefetcher!
    private var loader: ImageLoader!
    private var client: GatedHTTPClient!
    private var cache: StubImageCache!

    private let request = ImageRequest(url: URL(string: "https://example.com/images/1.jpg")!, maxPixelSize: 256)

    override func setUp() {
        super.setUp()
        client = GatedHTTPClient()
        cache = StubImageCache()
        loader = ImageLoader(client: client, cache: cache, downsampler: StubDownsampler())
        prefetcher = ImagePrefetcher(loader: loader)
    }

    override func tearDown() {
        client.release.open()
        prefetcher = nil
        loader = nil
        client = nil
        cache = nil
        super.tearDown()
    }

    func test_prefetch_startsADownload() {
        XCTAssertEqual(prefetcher.inFlightCount, 0)

        prefetcher.prefetch([request])

        XCTAssertEqual(prefetcher.inFlightCount, 1)
    }

    func test_duplicateRequestsInOneCall_startOneDownload() {
        prefetcher.prefetch([request, request, request])

        XCTAssertEqual(prefetcher.inFlightCount, 1)
    }

    func test_requestAlreadyInFlight_isNotStartedAgain() {
        prefetcher.prefetch([request])

        prefetcher.prefetch([request])

        XCTAssertEqual(prefetcher.inFlightCount, 1)
    }

    func test_cancelPrefetch_dropsTheRequest() {
        prefetcher.prefetch([request])

        prefetcher.cancelPrefetch([request])

        XCTAssertEqual(prefetcher.inFlightCount, 0)
    }

    /// A cell catching up with a prefetch joins it rather than re-downloading.
    func test_prefetchThenVisibleLoad_downloadsOnce() async throws {
        prefetcher.prefetch([request])
        await client.firstRequest.wait()

        async let visible = loader.image(for: request)
        client.release.open()
        _ = try await visible

        XCTAssertEqual(client.sendCount, 1)
    }

    /// Scroll away, scroll back: the download a cancelled prefetch started
    /// still lands in the cache, so the return trip is a hit.
    func test_cancelledPrefetch_stillWarmsTheCache() async throws {
        prefetcher.prefetch([request])
        prefetcher.cancelPrefetch([request])
        client.release.open()
        await cache.firstInsert.wait()

        _ = try await loader.image(for: request)

        XCTAssertEqual(client.sendCount, 1)
    }
}
