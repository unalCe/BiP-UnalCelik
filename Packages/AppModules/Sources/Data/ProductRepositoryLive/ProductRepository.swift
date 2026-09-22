import Foundation
import NetworkingKit
import PersistenceKit
import ProductDomain

public final class ProductRepository: ProductRepositoryInterface {
    private let remote: any ProductRemoteDataSource
    private let local: any ProductLocalDataSource

    init(remote: any ProductRemoteDataSource, local: any ProductLocalDataSource) {
        self.remote = remote
        self.local = local
    }

    public convenience init(
        client: any HTTPClientInterface,
        container: any PersistentContainerInterface,
        baseURL: URL
    ) {
        self.init(
            remote: HTTPProductRemoteDataSource(client: client, baseURL: baseURL),
            local: CoreDataProductStore(container: container)
        )
    }

    // Remote-first, falling back to cache.
    // TODO: maybe think about making the policy injectable — staleness window,
    // forced refresh, cache-only
    public func products() async throws -> [Product] {
        do {
            let fresh = try await remote.products()
            await local.saveListPage(fresh)
            return fresh
        } catch {
            let cached = await local.products()
            guard cached.isEmpty else { return cached }
            throw DomainErrorMapper.map(error)
        }
    }

    public func product(id: String) async throws -> Product {
        do {
            let fresh = try await remote.product(id: id)
            await local.saveDetail(fresh)
            return fresh
        } catch {
            if let cached = await local.product(id: id) { return cached }
            throw DomainErrorMapper.map(error)
        }
    }
}
