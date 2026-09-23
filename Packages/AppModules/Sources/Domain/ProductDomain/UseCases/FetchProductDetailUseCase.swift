import Foundation

public protocol FetchProductDetailUseCase: Sendable {
    func execute(id: String) async throws -> Product
}

public struct FetchProductDetail: FetchProductDetailUseCase {
    private let repository: ProductRepositoryInterface

    public init(repository: ProductRepositoryInterface) {
        self.repository = repository
    }

    public func execute(id: String) async throws -> Product {
        try await repository.product(id: id)
    }
}
