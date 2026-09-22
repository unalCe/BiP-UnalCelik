import Foundation
import NetworkingKit
import PersistenceKit
import ProductDomain

public enum ProductCachePolicy {
    public static let timeToLive: TimeInterval = 10 * 60
}

public final class ProductRepository: ProductRepositoryInterface {
    private let remote: any ProductRemoteDataSource
    private let local: any ProductLocalDataSource
    private let timeToLive: TimeInterval

    init(
        remote: any ProductRemoteDataSource,
        local: any ProductLocalDataSource,
        timeToLive: TimeInterval = ProductCachePolicy.timeToLive
    ) {
        self.remote = remote
        self.local = local
        self.timeToLive = timeToLive
    }

    public convenience init(
        client: any HTTPClientInterface,
        container: any PersistentContainerInterface,
        baseURL: URL,
        timeToLive: TimeInterval = ProductCachePolicy.timeToLive
    ) {
        self.init(
            remote: HTTPProductRemoteDataSource(client: client, baseURL: baseURL),
            local: CoreDataProductStore(container: container),
            timeToLive: timeToLive
        )
    }

    public func products() async throws -> [Product] {
        if let cached = await local.products(), isFresh(cached) { return cached.value }

        do {
            let fresh = try await remote.products()
            await local.saveListPage(fresh, at: Date())
            return fresh
        } catch {
            throw DomainErrorMapper.map(error)
        }
    }

    public func product(id: String) async throws -> Product {
        if let cached = await local.detail(id: id), isFresh(cached) { return cached.value }

        do {
            let fresh = try await remote.product(id: id)
            await local.saveDetail(fresh, at: Date())
            return fresh
        } catch {
            throw DomainErrorMapper.map(error)
        }
    }

    private func isFresh<Value>(_ cached: Cached<Value>) -> Bool {
        Date().timeIntervalSince(cached.fetchedAt) < timeToLive
    }
}
