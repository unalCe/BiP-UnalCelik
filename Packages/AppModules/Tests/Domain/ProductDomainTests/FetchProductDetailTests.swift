import ProductRepositoryMocks
import SharedDomain
import TestSupport
import XCTest

@testable import ProductDomain

final class FetchProductDetailTests: XCTestCase {
    private var useCase: FetchProductDetail!
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
        repository.stubbedProductResult = .success(ProductFixture.detail())
        useCase = FetchProductDetail(repository: repository)
    }

    func test_execute_requestsTheGivenIDAndReturnsTheProduct() async throws {
        XCTAssertFalse(repository.invokedProduct)

        let product = try await useCase.execute(id: "1")

        XCTAssertEqual(repository.invokedProductParameters?.id, "1")
        XCTAssertEqual(product, ProductFixture.detail())
    }

    func test_execute_passesTheRepositorysErrorThrough() async {
        repository.stubbedProductResult = .failure(DomainError.server(message: "Access Denied"))

        await XCTAssertThrowsErrorAsync(try await useCase.execute(id: "absent"), equals: DomainError.server(message: "Access Denied"))
    }
}
