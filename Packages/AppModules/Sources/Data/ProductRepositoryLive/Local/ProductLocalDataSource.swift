import Foundation
import ProductDomain

protocol ProductLocalDataSource: Sendable {
    func products() async -> [Product]
    func product(id: String) async -> Product?
    func saveListPage(_ products: [Product]) async
    func saveDetail(_ product: Product) async
}
