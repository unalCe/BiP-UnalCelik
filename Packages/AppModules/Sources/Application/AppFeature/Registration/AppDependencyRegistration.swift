import DependencyEngine
import ImageCacheKitLive
import NetworkingKitLive
import PersistenceKit
import PersistenceKitLive
import ProductRepositoryLive

// Order matters: ImageCacheKit and ProductRepository resolve the client and
// container registered above them. Closures rather than `DependencyRegistration`
// types only because the container takes arguments — the list is still the order.
public enum AppDependencyRegistration {
    public static func register(to engine: DependencyEngine, inMemory: Bool = false) {
        let registrations: [(DependencyEngine) -> Void] = [
            NetworkingKitDependencyRegistration.register,
            { registerPersistentContainer(to: $0, inMemory: inMemory) },
            ImageCacheKitDependencyRegistration.register,
            ProductRepositoryDependencyRegistration.register,
        ]
        registrations.forEach { $0(engine) }
    }

    // needs both halves: the stack from CoreKit, the model from the data layer
    private static func registerPersistentContainer(
        to engine: DependencyEngine,
        inMemory: Bool
    ) {
        do {
            let container = try CoreDataStack(
                modelName: ProductDataModel.name,
                bundle: ProductDataModel.bundle,
                inMemory: inMemory
            )
            engine.register(
                value: container as any PersistentContainerInterface,
                for: (any PersistentContainerInterface).self
            )
        } catch {
            // it's ok to crash here, this is app initializing step
            fatalError("Could not open the product store: \(error)")
        }
    }
}
