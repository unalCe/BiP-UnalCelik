import DependencyEngine
import ImageCacheKitLive
import NetworkingKitLive
import PerformanceKitLive
import PersistenceKitLive
import ProductRepositoryLive

// Order matters: ImageCacheKit and ProductRepository resolve the client,
// store and tracer registered above them.
public enum AppDependencyRegistration: DependencyRegistration {
    public static func register(to engine: DependencyEngine) {
        let registrations: [any DependencyRegistration.Type] = [
            PerformanceKitDependencyRegistration.self,
            NetworkingKitDependencyRegistration.self,
            PersistenceKitDependencyRegistration.self,
            ImageCacheKitDependencyRegistration.self,
            ProductRepositoryDependencyRegistration.self,
        ]
        registrations.registerAll(to: engine)
    }
}
