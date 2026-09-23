import ImageCacheKit
import NetworkingKit
import UIKit

public final class ImageLoader: ImageLoaderInterface, Sendable {
    private let client: HTTPClientInterface
    private let cache: DecodedImageCaching
    private let downsampler: ImageDownsampling
    private let registry = InFlightRegistry()

    init(
        client: HTTPClientInterface,
        cache: DecodedImageCaching,
        downsampler: ImageDownsampling
    ) {
        self.client = client
        self.cache = cache
        self.downsampler = downsampler
    }

    public convenience init(
        client: HTTPClientInterface,
        configuration: ImageCacheConfiguration = ImageCacheConfiguration()
    ) {
        self.init(
            client: client,
            cache: NSCacheImageCache(configuration),
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
