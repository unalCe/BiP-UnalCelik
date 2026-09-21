import ImageCacheKit
import NetworkingKit
import UIKit

public final class ImageLoader: ImageLoaderInterface, Sendable {
    private let client: any HTTPClientInterface
    private let cache: any DecodedImageCaching
    private let downsampler: any ImageDownsampling
    private let registry = InFlightRegistry()

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

        return try await registry.image(for: request) { [self] in
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
    }
}
