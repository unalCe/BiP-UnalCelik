import CommonKit
import Foundation
import ProductDomain
import ProductPresentation

public protocol ProductListInteractorInterface: Sendable {
    func loadProducts() async throws -> [ProductDisplayModel]
}

public struct ProductListInteractor: ProductListInteractorInterface {
    private let fetchProducts: FetchProductsUseCase
    private let mapper: ProductDisplayMapper

    public init(
        fetchProducts: FetchProductsUseCase,
        mapper: ProductDisplayMapper = ProductDisplayMapper()
    ) {
        self.fetchProducts = fetchProducts
        self.mapper = mapper
    }

    public func loadProducts() async throws -> [ProductDisplayModel] {
        mapper.map(try await fetchProducts.execute())
    }
}
