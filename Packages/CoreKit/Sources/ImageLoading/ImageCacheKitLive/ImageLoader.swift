import ImageCacheKit
import NetworkingKit
import PerformanceKit
import UIKit

public final class ImageLoader: ImageLoaderInterface, Sendable {
    private let client: any HTTPClientInterface
    private let cache: any DecodedImageCaching
    private let downsampler: any ImageDownsampling
    private let tracer: any PerformanceTracing
    private let registry = InFlightRegistry()

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

    /// Traced as `image.load`, tagged by where the image came from, so the
    /// report carries the cache hit rate:
    /// - `memory`: decoded cache hit.
    /// - `inflight`: joined a load already running, usually a prefetch that
    ///   had started but not finished. Prefetching helped, but not fully.
    /// - `network`: this call did the download.
    /// The network phase is nested; the decode traces itself, since only the
    /// downsampler knows where its work starts.
    public func image(for request: ImageRequest) async throws -> UIImage {
        let load = tracer.begin(.imageLoad)

        if let cached = cache.image(for: request) {
            tracer.end(load, attributes: ["source": "memory"])
            return cached
        }

        do {
            let (image, joined) = try await registry.image(for: request) { [self] in
                if let cached = cache.image(for: request) { return cached }

                let response = try await tracer.measure(.imageNetwork) {
                    try await client.send(HTTPRequest(url: request.url))
                }
                let image = try await downsampler.downsample(
                    response.body,
                    maxPixelSize: request.maxPixelSize,
                    scale: request.scale
                )

                cache.insert(image, for: request)
                return image
            }
            tracer.end(load, attributes: ["source": joined ? "inflight" : "network"])
            return image
        } catch {
            tracer.end(load,
                       outcome: Task.isCancelled ? .cancelled : .failed,
                       attributes: ["source": "network"])
            throw error
        }
    }
}
