import DependencyEngine
import Foundation
import LoggingKit
import NetworkingKit
import PersistenceKit
import ProductDomain

// Not a `DependencyRegistration`: where the API lives and how long a copy
// stays current are the composition root's decisions, so they arrive as
// arguments.
public enum ProductRepositoryDependencyRegistration {
    public static func register(to engine: DependencyEngine,
                                baseURL: URL,
                                timeToLive: TimeInterval) {
        guard
            let client: HTTPClientInterface = engine.resolve(HTTPClientInterface.self),
            let container: PersistentContainerInterface = engine.resolve(PersistentContainerInterface.self),
            let logger: LoggerInterface = engine.resolve(LoggerInterface.self)
        else {
            fatalError("Register a logger, NetworkingKit and the persistent container before ProductRepository")
        }

        engine.register(
            value: ProductRepository(
                client: client,
                container: container,
                baseURL: baseURL,
                logger: logger,
                timeToLive: timeToLive
            ) as ProductRepositoryInterface,
            for: ProductRepositoryInterface.self
        )
    }
}
