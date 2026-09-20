import ImageCacheKit
import NetworkingKit
import UIKit

/// A `final class`, not an `actor`: `ImagePrefetchingInterface` requires
/// synchronous, non-isolated methods that an actor cannot witness. There is no
/// mutable state to protect either — `NSCache` is already thread-safe. When
/// in-flight coalescing lands it belongs in its own actor collaborator.
public final class ImageLoader: ImageLoaderInterface, ImagePrefetchingInterface, Sendable {
    private let client: any HTTPClientInterface
    private let cache: any DecodedImageCaching
    private let downsampler: any ImageDownsampling

    init(
        client: any HTTPClientInterface,
        cache: any DecodedImageCaching,
        downsampler: any ImageDownsampling
    ) {
        self.client = client
        self.cache = cache
        self.downsampler = downsampler
    }

    public convenience init(
        client: any HTTPClientInterface,
        totalCostLimit: Int = 64 * 1024 * 1024,
        countLimit: Int = 100
    ) {
        self.init(
            client: client,
            cache: NSCacheImageCache(totalCostLimit: totalCostLimit, countLimit: countLimit),
            downsampler: CGImageDownsampler()
        )
    }

    public func image(for request: ImageRequest) async throws -> UIImage {
        if let cached = cache.image(for: request) { return cached }

        let response = try await client.send(HTTPRequest(url: request.url))

        let image = try await downsampler.downsample(
            response.body,
            maxPixelSize: request.maxPixelSize,
            scale: request.scale
        )

        cache.insert(image, for: request)
        return image
    }

    // TODO: hand off to a scheduling engine
    public func prefetch(_ urls: [URL]) {}

    public func cancelPrefetch(_ urls: [URL]) {}
}
