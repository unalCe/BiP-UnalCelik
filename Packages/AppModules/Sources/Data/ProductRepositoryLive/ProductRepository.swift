import CachingKit
import Foundation
import LoggingKit
import NetworkingKit
import PersistenceKit
import ProductDomain
import SharedDomain

public final class ProductRepository: ProductRepositoryInterface {
    private let remote: ProductRemoteDataSource
    private let local: ProductLocalDataSource
    private let loader: CacheAsideLoader
    private let errorMapper: DomainErrorMapper

    // MARK: - Lifecycle

    init(
        remote: ProductRemoteDataSource,
        local: ProductLocalDataSource,
        logger: LoggerInterface,
        timeToLive: TimeInterval,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.remote = remote
        self.local = local
        self.loader = CacheAsideLoader(
            policy: FreshnessPolicy(maxAge: timeToLive), logger: logger, now: now
        )
        self.errorMapper = DomainErrorMapper(logger: logger)
    }

    public convenience init(
        client: HTTPClientInterface,
        container: PersistentContainerInterface,
        baseURL: URL,
        logger: LoggerInterface,
        timeToLive: TimeInterval
    ) {
        self.init(
            remote: HTTPProductRemoteDataSource(apiClient: APIClient(baseURL: baseURL, transport: client)),
            local: CoreDataProductStore(container: container),
            logger: logger,
            timeToLive: timeToLive
        )
    }

    // MARK: - Public Funcs

    public func products() async throws -> [Product] {
        do {
            return try await loader.load(
                read: local.products,
                fetch: remote.products,
                write: local.saveListPage
            )
        } catch {
            throw errorMapper.map(error)
        }
    }

    public func product(id: String) async throws -> Product {
        do {
            return try await loader.load(
                read: { try await local.detail(id: id) },
//                read: local.detail(id: id), // doesn't work here because loader expects () -> CacheEntry<Product>, not a (Sting)-> CacheEntry
                fetch: { try await remote.product(id: id) },
                write: local.saveDetail
            )
        } catch {
            throw errorMapper.map(error)
        }
    }
}
