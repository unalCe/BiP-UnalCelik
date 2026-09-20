import Foundation

public protocol FetchProductDetailUseCase: Sendable {
    func execute(id: String) async throws -> Product
}

public struct FetchProductDetail: FetchProductDetailUseCase {
    private let repository: any ProductRepositoryInterface

    public init(repository: any ProductRepositoryInterface) {
        self.repository = repository
    }

    public func execute(id: String) async throws -> Product {
        try await repository.product(id: id)
    }
}
