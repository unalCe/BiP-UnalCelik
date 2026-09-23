import DependencyEngine
import ImageCacheKitLive
import LoggingKit
import LoggingKitLive
import NetworkingKit
import NetworkingKitLive
import PersistenceKit
import PersistenceKitLive
import ProductRepositoryLive

// Order matters: ImageCacheKit and ProductRepository resolve the client and container registered above them.
public enum AppDependencyRegistration {
    public static func register(
        to engine: DependencyEngine,
        inMemory: Bool = false,
        logger: LoggerInterface = OSLogger(),
        configuration: AppConfiguration = .default,
        httpClient: HTTPClientInterface? = nil
    ) {
        engine.register(value: logger, for: LoggerInterface.self)

        let registrations: [(DependencyEngine) -> Void] = [
            { NetworkingKitDependencyRegistration.register(to: $0,
                                                           cache: configuration.urlCache) },
            // replaces the URLSession client before anything resolves it,
            // so the repository and the image loader both go through it
            { engine in
                guard let httpClient else { return }
                engine.register(value: httpClient, for: HTTPClientInterface.self)
            },
            { registerPersistentContainer(to: $0,
                                          inMemory: inMemory,
                                          logger: logger) },
            { ImageCacheKitDependencyRegistration.register(to: $0,
                                                           cache: configuration.imageCache) },
            {
                ProductRepositoryDependencyRegistration.register(
                    to: $0,
                    baseURL: configuration.baseURL,
                    timeToLive: configuration.productTimeToLive
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
