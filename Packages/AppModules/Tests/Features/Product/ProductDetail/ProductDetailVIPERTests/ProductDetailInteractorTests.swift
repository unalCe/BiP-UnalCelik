import ProductDomain
import ProductDomainMocks
import ProductPresentation
import ProductRepositoryMocks
import SharedDomain
import TestSupport
import XCTest

@testable import ProductDetailVIPER

final class ProductDetailInteractorTests: XCTestCase {
    private var interactor: ProductDetailInteractor!
    private var fetchDetail: MockFetchProductDetailUseCase!

    /// `ProductDetailResponse.json`, through the real DTO and mapper.
    private var product: Product { ProductFixture.detail() }

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        interactor = nil
        fetchDetail = nil
        super.tearDown()
    }

    private func reCreate() {
        fetchDetail = .init()
        fetchDetail.stubbedExecuteResult = .success(product)
        interactor = ProductDetailInteractor(fetchDetail: fetchDetail)
    }

    func test_loadProduct_requestsTheIDAndMapsTheProductForDisplay() async throws {
        XCTAssertFalse(fetchDetail.invokedExecute)

        let item = try await interactor.loadProduct(id: "1")

        XCTAssertEqual(fetchDetail.invokedExecuteParameters?.id, "1")
        XCTAssertEqual(item, ProductDisplayMapper().map(product))
    }

    func test_loadProduct_passesTheUseCaseErrorThrough() async {
        fetchDetail.stubbedExecuteResult = .failure(DomainError.offline)

        await XCTAssertThrowsErrorAsync(try await interactor.loadProduct(id: "1"), equals: DomainError.offline)
    }
}
