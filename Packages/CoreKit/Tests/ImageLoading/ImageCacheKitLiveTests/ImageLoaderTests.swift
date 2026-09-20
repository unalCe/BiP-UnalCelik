import XCTest
import ImageCacheKit
import ImageCacheKitMocks
import NetworkingKit
import NetworkingKitMocks
@testable import ImageCacheKitLive

final class ImageLoaderTests: XCTestCase {
    private let url = URL(string: "https://example.com/images/1.jpg")!

    func test_cacheHit_doesNotTouchTheNetwork() async throws {
        let cached = Data("cached-bytes".utf8)
        let client = MockHTTPClient(always: .ok(Data("network-bytes".utf8)))
        let sut = ImageLoader(client: client, cache: MockImageCache(seed: [url: cached]))

        let data = try await sut.data(for: url)

        XCTAssertEqual(data, cached)
        XCTAssertEqual(client.sendCount, 0)
    }

    func test_cacheMiss_fetchesThenStores() async throws {
        let fetched = Data("network-bytes".utf8)
        let client = MockHTTPClient(always: .ok(fetched))
        let cache = MockImageCache()
        let sut = ImageLoader(client: client, cache: cache)

        let data = try await sut.data(for: url)

        XCTAssertEqual(data, fetched)
        XCTAssertEqual(client.sendCount, 1)
        let stored = await cache.storeCount
        XCTAssertEqual(stored, 1)
    }

    func test_transportFailure_propagates() async {
        let client = MockHTTPClient(always: .offline)
        let sut = ImageLoader(client: client, cache: MockImageCache())

        do {
            _ = try await sut.data(for: url)
            XCTFail("expected a failure")
        } catch let error as NetworkError {
            XCTAssertTrue(error.isOffline)
        } catch {
            XCTFail("expected NetworkError, got \(error)")
        }
    }
}
