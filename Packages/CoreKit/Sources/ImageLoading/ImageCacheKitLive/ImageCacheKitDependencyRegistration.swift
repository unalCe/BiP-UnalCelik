import DependencyEngine
import ImageCacheKit
import NetworkingKit

public enum ImageCacheKitDependencyRegistration: DependencyRegistration {
    public static func register(to engine: DependencyEngine) {
        register(to: engine, cache: ImageCacheConfiguration())
    }

    public static func register(to engine: DependencyEngine, cache: ImageCacheConfiguration) {
        // Resolves the client already registered by NetworkingKitLive, so the
        // app shares one transport across data and image traffic.
        guard let client: HTTPClientInterface = engine.resolve(HTTPClientInterface.self) else {
            fatalError("Register NetworkingKitDependencyRegistration before ImageCacheKit")
        }

        let loader = ImageLoader(client: client, configuration: cache)
        let prefetcher = ImagePrefetcher(loader: loader)

        engine.register(value: loader as ImageLoaderInterface, for: ImageLoaderInterface.self)
        engine.register(
            value: prefetcher as ImagePrefetchingInterface,
            for: ImagePrefetchingInterface.self
        )
    }
}
