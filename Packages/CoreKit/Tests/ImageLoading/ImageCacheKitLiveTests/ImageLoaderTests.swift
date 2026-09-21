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

    // two concurrent callers must share one download
    func test_concurrentRequestsForTheSameImage_shareOneDownload() async throws {
        let client = MockHTTPClient(always: .ok(Data("network-bytes".utf8)))
        let downsampler = StubDownsampler(delay: .milliseconds(200))
        let sut = ImageLoader(client: client, cache: StubImageCache(), downsampler: downsampler)

        async let first = sut.image(for: request)
        async let second = sut.image(for: request)
        _ = try await (first, second)

        XCTAssertEqual(client.sendCount, 1)
        XCTAssertEqual(downsampler.callCount, 1)
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
