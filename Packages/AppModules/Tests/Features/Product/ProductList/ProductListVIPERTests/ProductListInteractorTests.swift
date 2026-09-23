import ProductDomain
import ProductDomainMocks
import ProductPresentation
import ProductRepositoryMocks
import SharedDomain
import TestSupport
import XCTest

@testable import ProductListVIPER

final class ProductListInteractorTests: XCTestCase {
    private var interactor: ProductListInteractor!
    private var fetchProducts: MockFetchProductsUseCase!

    /// `ProductListResponse.json`, through the real DTO and mapper.
    private var products: [Product] { ProductFixture.list() }

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        interactor = nil
        fetchProducts = nil
        super.tearDown()
    }

    private func reCreate() {
        fetchProducts = .init()
        fetchProducts.stubbedExecuteResult = .success(products)
        interactor = ProductListInteractor(fetchProducts: fetchProducts)
    }

    func test_loadProducts_returnsThemMappedForDisplay() async throws {
        XCTAssertFalse(fetchProducts.invokedExecute)

        let items = try await interactor.loadProducts()

        XCTAssertEqual(fetchProducts.invokedExecuteCount, 1)
        XCTAssertEqual(items, ProductDisplayMapper().map(products))
    }

    func test_loadProducts_passesTheUseCaseErrorThrough() async {
        fetchProducts.stubbedExecuteResult = .failure(DomainError.offline)

        await XCTAssertThrowsErrorAsync(try await interactor.loadProducts(), equals: DomainError.offline)
    }
}
