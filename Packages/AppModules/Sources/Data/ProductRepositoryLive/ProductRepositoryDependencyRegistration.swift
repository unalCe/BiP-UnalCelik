import DependencyEngine
import Foundation
import NetworkingKit
import PersistenceKit
import ProductDomain

public enum ProductRepositoryDependencyRegistration: DependencyRegistration {
    public static let baseURL = URL(
        string: "https://s3-eu-west-1.amazonaws.com/developer-application-test/"
    )!

    public static func register(to engine: DependencyEngine) {
        guard
            let client: any HTTPClientInterface = engine.resolve((any HTTPClientInterface).self),
            let store: any PersistentStoreInterface = engine.resolve((any PersistentStoreInterface).self)
        else {
            fatalError("Register NetworkingKit and PersistenceKit before ProductRepository")
        }

        engine.register(
            value: ProductRepository(client: client, store: store, baseURL: baseURL)
                as any ProductRepositoryInterface,
            for: (any ProductRepositoryInterface).self
        )
    }
}
