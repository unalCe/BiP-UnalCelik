import Foundation

public protocol ProductRepositoryInterface: Sendable {
    func products() async throws -> [Product]
    func product(id: String) async throws -> Product
}
