import ImageCacheKit
import ImageCacheKitMocks
import NetworkingKit
import NetworkingKitMocks
import UIKit
import XCTest
@testable import ImageCacheKitLive

final class ImagePrefetcherTests: XCTestCase {
    private let request = ImageRequest(
        url: URL(string: "https://example.com/images/1.jpg")!,
        maxPixelSize: 256
    )

    // a cell catching up with a prefetch joins it rather than re-downloading
    func test_prefetchThenVisibleLoad_downloadsOnce() async throws {
        let client = MockHTTPClient(always: .ok(Data("network-bytes".utf8)))
        let downsampler = StubDownsampler(delay: .milliseconds(300))
        let loader = ImageLoader(client: client, cache: StubImageCache(), downsampler: downsampler)
        let prefetcher = ImagePrefetcher(loader: loader)

        prefetcher.prefetch([request])
        await waitUntil { client.sendCount == 1 }

        _ = try await loader.image(for: request)

        XCTAssertEqual(client.sendCount, 1)
        XCTAssertEqual(downsampler.callCount, 1)
    }

    // scroll away, scroll back: the return trip is a cache hit
    func test_cancelledPrefetch_servesALaterLoadWithoutDownloadingAgain() async throws {
        let client = MockHTTPClient(always: .ok(Data("network-bytes".utf8)))
        let cache = StubImageCache()
        let loader = ImageLoader(client: client, cache: cache, downsampler: StubDownsampler())
        let prefetcher = ImagePrefetcher(loader: loader)

        prefetcher.prefetch([request])
        prefetcher.cancelPrefetch([request])
        await waitUntil { cache.insertCount == 1 }

        _ = try await loader.image(for: request)

        XCTAssertEqual(client.sendCount, 1)
    }

    func test_duplicateRequestsInOneCall_reachTheLoaderOnce() async {
        let loader = MockImageLoader()
        let prefetcher = ImagePrefetcher(loader: loader)

        prefetcher.prefetch([request, request, request])
        await waitUntil { !loader.requestedRequests.isEmpty }
        try? await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(loader.requestedRequests.count, 1)
    }

    private func waitUntil(_ condition: @escaping () -> Bool) async {
        for _ in 0..<200 {
            if condition() { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}
