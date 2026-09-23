import CachingKit
import Foundation
import ProductDomain

/// Throws rather than returning `nil` on failure, so a broken store cannot
/// pass for an empty one. What a failure *means* is the repository's call.
protocol ProductLocalDataSource: Sendable {
    func products() async throws -> CacheEntry<[Product]>?

    func detail(id: String) async throws -> CacheEntry<Product>?

    func saveListPage(_ products: [Product], at date: Date) async throws
    func saveDetail(_ product: Product, at date: Date) async throws
}
