import CommonKit
import Foundation
import ProductDomain

public struct ProductDetailInteractor: ProductDetailInteractorInterface {
    private let fetchDetail: any FetchProductDetailUseCase
    private let mapper: ProductDisplayMapper

    public init(
        fetchDetail: any FetchProductDetailUseCase,
        mapper: ProductDisplayMapper = ProductDisplayMapper()
    ) {
        self.fetchDetail = fetchDetail
        self.mapper = mapper
    }

    public func loadProduct(id: String) async throws -> ProductDisplayModel {
        mapper.map(try await fetchDetail.execute(id: id))
    }
}
