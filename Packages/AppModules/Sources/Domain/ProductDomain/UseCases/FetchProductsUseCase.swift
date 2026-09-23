import Foundation

public protocol FetchProductsUseCase: Sendable {
    func execute() async throws -> [Product]
}

public struct FetchProducts: FetchProductsUseCase {
    private let repository: ProductRepositoryInterface

    public init(repository: ProductRepositoryInterface) {
        self.repository = repository
    }

    public func execute() async throws -> [Product] {
        try await repository.products()
    }
}
