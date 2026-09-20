import DependencyEngine
import ImageCacheKit
import NetworkingKit

public enum ImageCacheKitDependencyRegistration: DependencyRegistration {
    public static func register(to engine: DependencyEngine) {
        // Resolves the client already registered by NetworkingKitLive, so the
        // app shares one transport across data and image traffic.
        guard let client: any HTTPClientInterface = engine.resolve((any HTTPClientInterface).self) else {
            fatalError("Register NetworkingKitDependencyRegistration before ImageCacheKit")
        }

        let loader = ImageLoader(client: client)
        engine.register(value: loader as any ImageLoaderInterface, for: (any ImageLoaderInterface).self)
        engine.register(value: loader as any ImagePrefetchingInterface, for: (any ImagePrefetchingInterface).self)
    }
}
