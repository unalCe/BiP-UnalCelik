import ImageCacheKit
import NetworkingKit
import NetworkingKitMocks
import TestSupport
import UIKit
import XCTest

@testable import ImageCacheKitLive

final class ImageLoaderTests: XCTestCase {
    private var loader: ImageLoader!
    private var client: MockHTTPClient!
    private var cache: StubImageCache!
    private var downsampler: StubDownsampler!

    private let request = ImageRequest(url: URL(string: "https://example.com/images/1.jpg")!, maxPixelSize: 256)

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        loader = nil
        client = nil
        cache = nil
        downsampler = nil
        super.tearDown()
    }

    private func reCreate(
        response: MockHTTPClient.Behaviour = .ok(Data("network-bytes".utf8)),
        cached: [ImageRequest: UIImage] = [:],
        downsampleDelay: Duration? = nil
    ) {
        client = MockHTTPClient(always: response)
        cache = StubImageCache(seed: cached)
        downsampler = StubDownsampler(delay: downsampleDelay)
        loader = ImageLoader(client: client, cache: cache, downsampler: downsampler)
    }

    func test_cacheHit_doesNotTouchTheNetwork() async throws {
        let cached = UIImage()
        reCreate(cached: [request: cached])

        let image = try await loader.image(for: request)

        XCTAssertTrue(image === cached)
        XCTAssertEqual(client.sendCount, 0)
    }

    func test_cacheMiss_fetchesDownsamplesThenStores() async throws {
        _ = try await loader.image(for: request)

        XCTAssertEqual(client.sendCount, 1)
        XCTAssertEqual(downsampler.callCount, 1)
        XCTAssertEqual(cache.insertCount, 1)
    }

    /// Two concurrent callers must share one download. The downsampler delay
    /// only widens the overlap; no assertion waits on it.
    func test_concurrentRequestsForTheSameImage_shareOneDownload() async throws {
        reCreate(downsampleDelay: .milliseconds(200))

        async let first = loader.image(for: request)
        async let second = loader.image(for: request)
        _ = try await (first, second)

        XCTAssertEqual(client.sendCount, 1)
        XCTAssertEqual(downsampler.callCount, 1)
    }

    func test_transportFailure_propagatesAndCachesNothing() async {
        reCreate(response: .offline)

        await XCTAssertThrowsErrorAsync(try await loader.image(for: request)) { error in
            XCTAssertEqual((error as? NetworkError)?.isOffline, true, "got \(error)")
        }
        XCTAssertEqual(cache.insertCount, 0)
    }
}
