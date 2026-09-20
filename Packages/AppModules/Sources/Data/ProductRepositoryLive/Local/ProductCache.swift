import Foundation
import PersistenceKit
import ProductDomain

struct ProductCache: Sendable {
    private enum Key {
        static let list = "products.list"
        static func detail(_ id: String) -> String { "products.detail.\(id)" }
    }

    private let store: any PersistentStoreInterface

    init(store: any PersistentStoreInterface) {
        self.store = store
    }

    func products() async -> [Product] {
        (try? await store.read([Product].self, forKey: Key.list)) .flatMap { $0 } ?? []
    }

    func product(id: String) async -> Product? {
        if let cached = try? await store.read(Product.self, forKey: Key.detail(id)) {
            return cached
        }
        return await products().first { $0.id == id }
    }

    func save(_ products: [Product]) async {
        try? await store.write(products, forKey: Key.list)
    }

    /// Merges rather than overwrites: the list endpoint omits `description`,
    /// so a later refresh would otherwise wipe one already fetched.
    func save(_ product: Product) async {
        let merged: Product
        if let existing = await self.product(id: product.id) {
            merged = Product(
                id: product.id,
                name: product.name,
                price: product.price,
                imageURL: product.imageURL ?? existing.imageURL,
                productDescription: product.productDescription ?? existing.productDescription
            )
        } else {
            merged = product
        }
        try? await store.write(merged, forKey: Key.detail(product.id))
    }
}
