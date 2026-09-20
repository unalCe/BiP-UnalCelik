import CommonKit
import Foundation
import ProductDomain

public struct ProductListInteractor: ProductListInteractorInterface {
    private let fetchProducts: any FetchProductsUseCase
    private let mapper: ProductDisplayMapper

    public init(
        fetchProducts: any FetchProductsUseCase,
        mapper: ProductDisplayMapper = ProductDisplayMapper()
    ) {
        self.fetchProducts = fetchProducts
        self.mapper = mapper
    }

    public func loadProducts() async throws -> [ProductDisplayModel] {
        mapper.map(try await fetchProducts.execute())
    }
}
