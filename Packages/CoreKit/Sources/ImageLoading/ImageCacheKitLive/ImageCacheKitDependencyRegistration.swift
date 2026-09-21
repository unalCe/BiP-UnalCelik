import DependencyEngine
import ImageCacheKit
import NetworkingKit
import PerformanceKit

public enum ImageCacheKitDependencyRegistration: DependencyRegistration {
    public static func register(to engine: DependencyEngine) {
        // Resolves the client already registered by NetworkingKitLive, so the
        // app shares one transport across data and image traffic.
        guard let client: any HTTPClientInterface = engine.resolve((any HTTPClientInterface).self) else {
            fatalError("Register NetworkingKitDependencyRegistration before ImageCacheKit")
        }

        // Optional: tracing is a diagnostic, never a reason to fail launch.
        // Typed apart from the `??`: inline, `resolve` infers its generic as
        // `NoopPerformanceTracer`, the cast fails, and the no-op always wins.
        let registeredTracer: (any PerformanceTracing)? = engine.resolve((any PerformanceTracing).self)
        let tracer = registeredTracer ?? NoopPerformanceTracer()

        let loader = ImageLoader(client: client, tracer: tracer)
        let prefetcher = ImagePrefetcher(loader: loader, tracer: tracer)

        engine.register(value: loader as any ImageLoaderInterface, for: (any ImageLoaderInterface).self)
        engine.register(
            value: prefetcher as any ImagePrefetchingInterface,
            for: (any ImagePrefetchingInterface).self
        )
    }
}
