import DependencyEngine
import ImageCacheKitLive
import NetworkingKitLive
import PersistenceKitLive
import ProductRepositoryLive

// Order matters: ImageCacheKit and ProductRepository resolve the client and
// store registered above them.
public enum AppDependencyRegistration: DependencyRegistration {
    public static func register(to engine: DependencyEngine) {
        let registrations: [any DependencyRegistration.Type] = [
            NetworkingKitDependencyRegistration.self,
            PersistenceKitDependencyRegistration.self,
            ImageCacheKitDependencyRegistration.self,
            ProductRepositoryDependencyRegistration.self,
        ]
        registrations.registerAll(to: engine)
    }
}
