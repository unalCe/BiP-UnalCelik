import Foundation
import ProductDomain

struct Cached<Value: Sendable>: Sendable {
    let value: Value
    let fetchedAt: Date
}

/// Throws rather than returning `nil` on failure, so a broken store cannot
/// pass for an empty one. What a failure *means* is the repository's call.
protocol ProductLocalDataSource: Sendable {
    func products() async throws -> Cached<[Product]>?

    func detail(id: String) async throws -> Cached<Product>?

    func saveListPage(_ products: [Product], at date: Date) async throws
    func saveDetail(_ product: Product, at date: Date) async throws
}
