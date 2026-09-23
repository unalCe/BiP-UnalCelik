import CommonKit
import Foundation
import ProductDomain

public struct ProductDetailInteractor: ProductDetailInteractorInterface {
    private let fetchDetail: FetchProductDetailUseCase
    private let mapper: ProductDisplayMapper

    public init(
        fetchDetail: FetchProductDetailUseCase,
        mapper: ProductDisplayMapper = ProductDisplayMapper()
    ) {
        self.fetchDetail = fetchDetail
        self.mapper = mapper
    }

    public func loadProduct(id: String) async throws -> ProductDisplayModel {
        mapper.map(try await fetchDetail.execute(id: id))
    }
}
