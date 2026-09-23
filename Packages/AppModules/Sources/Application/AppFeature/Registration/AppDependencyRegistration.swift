import DependencyEngine
import ImageCacheKitLive
import LoggingKit
import LoggingKitLive
import NetworkingKitLive
import PersistenceKit
import PersistenceKitLive
import ProductRepositoryLive

// Order matters: ImageCacheKit and ProductRepository resolve the client and
// container registered above them. Closures rather than `DependencyRegistration`
// types only because the steps take arguments — the list is still the order.
// The logger is registered before the list because the steps in it report
// through it.
public enum AppDependencyRegistration {
    public static func register(
        to engine: DependencyEngine,
        inMemory: Bool = false,
        logger: LoggerInterface = OSLogger(),
        configuration: AppConfiguration = .default
    ) {
        engine.register(value: logger, for: LoggerInterface.self)

        let registrations: [(DependencyEngine) -> Void] = [
            { NetworkingKitDependencyRegistration.register(to: $0, cache: configuration.urlCache) },
            { registerPersistentContainer(to: $0, inMemory: inMemory, logger: logger) },
            { ImageCacheKitDependencyRegistration.register(to: $0, cache: configuration.imageCache) },
            {
                ProductRepositoryDependencyRegistration.register(
                    to: $0, baseURL: configuration.baseURL, timeToLive: configuration.productTimeToLive
                )
            },
        ]
        registrations.forEach { $0(engine) }
    }

    // needs both halves: the stack from CoreKit, the model from the data layer
    private static func registerPersistentContainer(
        to engine: DependencyEngine,
        inMemory: Bool,
        logger: LoggerInterface
    ) {
        let name = ProductDataModel.name
        let bundle = ProductDataModel.bundle
        let loader = PersistentStoreLoader(
            openOnDisk: { try CoreDataStack(modelName: name, bundle: bundle, inMemory: inMemory) },
            destroyOnDisk: { try CoreDataStack.destroyStore(modelName: name, bundle: bundle) },
            openInMemory: { try CoreDataStack(modelName: name, bundle: bundle, inMemory: true) },
            logger: logger
        )
        let container = loader.load()
        engine.register(
            value: container,
            for: PersistentContainerInterface.self
        )
    }
}
