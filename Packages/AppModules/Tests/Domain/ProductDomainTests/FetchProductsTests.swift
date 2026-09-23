import ProductRepositoryMocks
import SharedDomain
import TestSupport
import XCTest

@testable import ProductDomain

final class FetchProductsTests: XCTestCase {
    private var useCase: FetchProducts!
    private var repository: MockProductRepository!

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        useCase = nil
        repository = nil
        super.tearDown()
    }

    private func reCreate() {
        repository = .init()
        repository.stubbedProductsResult = .success(ProductFixture.list())
        useCase = FetchProducts(repository: repository)
    }

    func test_execute_returnsTheRepositorysProducts() async throws {
        XCTAssertFalse(repository.invokedProducts)

        let products = try await useCase.execute()

        XCTAssertEqual(repository.invokedProductsCount, 1)
        XCTAssertEqual(products, ProductFixture.list())
    }

    func test_execute_passesTheRepositorysErrorThrough() async {
        repository.stubbedProductsResult = .failure(DomainError.server(message: "Access Denied"))

        await XCTAssertThrowsErrorAsync(try await useCase.execute(), equals: DomainError.server(message: "Access Denied"))
    }
}
