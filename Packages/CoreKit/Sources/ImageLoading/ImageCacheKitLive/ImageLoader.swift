import Foundation
import ImageCacheKit
import NetworkingKit

// TODO: maybe think about coalescing concurrent requests for the same URL,
// cancellation tokens, downsampling — the API images are ~576 KB each
public final class ImageLoader: ImageLoaderInterface, ImagePrefetchingInterface {
    private let client: any HTTPClientInterface
    private let cache: any ImageCacheInterface

    public init(client: any HTTPClientInterface, cache: any ImageCacheInterface) {
        self.client = client
        self.cache = cache
    }

    public func data(for url: URL) async throws -> Data {
        if let cached = await cache.data(for: url) { return cached }
        let response = try await client.send(HTTPRequest(url: url))
        await cache.store(response.body, for: url)
        return response.body
    }

    public func prefetch(_ urls: [URL]) {
        // TODO: hand off to a scheduling engine
    }

    public func cancelPrefetch(_ urls: [URL]) {
        // TODO: as above
    }
}
