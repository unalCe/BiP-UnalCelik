import Foundation
import ProductDomain

struct Cached<Value: Sendable>: Sendable {
    let value: Value
    let fetchedAt: Date
}

protocol ProductLocalDataSource: Sendable {
    func products() async -> Cached<[Product]>?

    func detail(id: String) async -> Cached<Product>?

    func saveListPage(_ products: [Product], at date: Date) async
    func saveDetail(_ product: Product, at date: Date) async
}
