import Foundation

public protocol FetchProductsUseCase: Sendable {
    func execute() async throws -> [Product]
}

public struct FetchProducts: FetchProductsUseCase {
    private let repository: any ProductRepositoryInterface

    public init(repository: any ProductRepositoryInterface) {
        self.repository = repository
    }

    public func execute() async throws -> [Product] {
        try await repository.products()
    }
}
