import Foundation
import LoggingKit
import NetworkingKit
import PersistenceKit
import ProductDomain

public final class ProductRepository: ProductRepositoryInterface {
    private let remote: ProductRemoteDataSource
    private let local: ProductLocalDataSource
    private let logger: LoggerInterface
    private let errorMapper: DomainErrorMapper
    private let timeToLive: TimeInterval

    init(
        remote: ProductRemoteDataSource,
        local: ProductLocalDataSource,
        logger: LoggerInterface,
        timeToLive: TimeInterval
    ) {
        self.remote = remote
        self.local = local
        self.logger = logger
        self.errorMapper = DomainErrorMapper(logger: logger)
        self.timeToLive = timeToLive
    }

    public convenience init(
        client: HTTPClientInterface,
        container: PersistentContainerInterface,
        baseURL: URL,
        logger: LoggerInterface,
        timeToLive: TimeInterval
    ) {
        self.init(
            remote: HTTPProductRemoteDataSource(client: client, baseURL: baseURL, logger: logger),
            local: CoreDataProductStore(container: container),
            logger: logger,
            timeToLive: timeToLive
        )
    }

    public func products() async throws -> [Product] {
        if let cached = await cachedOrMiss({ try await local.products() }), isFresh(cached) {
            return cached.value
        }

        do {
            let fresh = try await remote.products()
            await cache { try await local.saveListPage(fresh, at: Date()) }
            return fresh
        } catch {
            throw errorMapper.map(error)
        }
    }

    public func product(id: String) async throws -> Product {
        if let cached = await cachedOrMiss({ try await local.detail(id: id) }), isFresh(cached) {
            return cached.value
        }

        do {
            let fresh = try await remote.product(id: id)
            await cache { try await local.saveDetail(fresh, at: Date()) }
            return fresh
        } catch {
            throw errorMapper.map(error)
        }
    }

    //

    private func cachedOrMiss<Value>(
        _ read: () async throws -> Cached<Value>?
    ) async -> Cached<Value>? {
        do {
            return try await read()
        } catch {
            logger.error("cache read failed, treated as a miss: \(error)", category: .persistence)
            return nil
        }
    }

    private func cache(_ write: () async throws -> Void) async {
        do {
            try await write()
        } catch {
            logger.error("cache write failed, response returned uncached: \(error)", category: .persistence)
        }
    }

    private func isFresh<Value>(_ cached: Cached<Value>) -> Bool {
        Date().timeIntervalSince(cached.fetchedAt) < timeToLive
    }
}
