import Foundation
import NetworkingKit
import PersistenceKit
import ProductDomain

public final class ProductRepository: ProductRepositoryInterface {
    private let remote: any ProductRemoteDataSource
    private let cache: ProductCache

    init(remote: any ProductRemoteDataSource, cache: ProductCache) {
        self.remote = remote
        self.cache = cache
    }

    public convenience init(
        client: any HTTPClientInterface,
        store: any PersistentStoreInterface,
        baseURL: URL
    ) {
        self.init(
            remote: HTTPProductRemoteDataSource(client: client, baseURL: baseURL),
            cache: ProductCache(store: store)
        )
    }

    // Remote-first, falling back to cache.
    // TODO: maybe think about making the policy injectable — staleness window,
    // forced refresh, cache-only
    public func products() async throws -> [Product] {
        do {
            let fresh = try await remote.products()
            await cache.save(fresh)
            return fresh
        } catch {
            let cached = await cache.products()
            guard cached.isEmpty else { return cached }
            throw DomainErrorMapper.map(error)
        }
    }

    public func product(id: String) async throws -> Product {
        do {
            let fresh = try await remote.product(id: id)
            await cache.save(fresh)
            return fresh
        } catch {
            if let cached = await cache.product(id: id) { return cached }
            throw DomainErrorMapper.map(error)
        }
    }
}
