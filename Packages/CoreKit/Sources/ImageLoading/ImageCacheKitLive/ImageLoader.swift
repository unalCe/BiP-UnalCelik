import ImageCacheKit
import NetworkingKit
import PerformanceKit
import UIKit

/// A `final class`, not an `actor`: `ImagePrefetchingInterface` requires
/// synchronous, non-isolated methods that an actor cannot witness. There is no
/// mutable state to protect either — `NSCache` is already thread-safe. When
/// in-flight coalescing lands it belongs in its own actor collaborator.
public final class ImageLoader: ImageLoaderInterface, ImagePrefetchingInterface, Sendable {
    private let client: any HTTPClientInterface
    private let cache: any DecodedImageCaching
    private let downsampler: any ImageDownsampling
    private let tracer: any PerformanceTracing

    init(
        client: any HTTPClientInterface,
        cache: any DecodedImageCaching,
        downsampler: any ImageDownsampling,
        tracer: any PerformanceTracing = NoopPerformanceTracer()
    ) {
        self.client = client
        self.cache = cache
        self.downsampler = downsampler
        self.tracer = tracer
    }

    public convenience init(
        client: any HTTPClientInterface,
        totalCostLimit: Int = 64 * 1024 * 1024,
        countLimit: Int = 100,
        tracer: any PerformanceTracing = NoopPerformanceTracer()
    ) {
        self.init(
            client: client,
            cache: NSCacheImageCache(totalCostLimit: totalCostLimit, countLimit: countLimit),
            downsampler: CGImageDownsampler(tracer: tracer),
            tracer: tracer
        )
    }

    /// Traced as `image.load`, tagged `source=memory|network` so the report
    /// carries the cache hit rate, with the network phase nested. The decode
    /// traces itself, since only the downsampler knows where its work starts.
    public func image(for request: ImageRequest) async throws -> UIImage {
        let load = tracer.begin(.imageLoad)

        if let cached = cache.image(for: request) {
            tracer.end(load, attributes: ["source": "memory"])
            return cached
        }

        do {
            let response = try await tracer.measure(.imageNetwork) {
                try await client.send(HTTPRequest(url: request.url))
            }

            let image = try await downsampler.downsample(
                response.body,
                maxPixelSize: request.maxPixelSize,
                scale: request.scale
            )

            cache.insert(image, for: request)
            tracer.end(load, attributes: ["source": "network"])
            return image
        } catch {
            tracer.end(load,
                       outcome: Task.isCancelled ? .cancelled : .failed,
                       attributes: ["source": "network"])
            throw error
        }
    }

    // TODO: hand off to a scheduling engine
    public func prefetch(_ urls: [URL]) {}

    public func cancelPrefetch(_ urls: [URL]) {}
}
