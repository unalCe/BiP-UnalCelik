import CommonKit
import ProductDomain
import ProductRepositoryMocks
import Foundation
import SharedDomain
import XCTest
@testable import ProductDetailMVVM

@MainActor
final class ProductDetailViewModelTests: XCTestCase {
    func test_onAppear_loadsDescription() async {
        let product = Product.fixture(
            id: "1", name: "Apples", description: "An apple a day keeps the doctor away."
        )
        let sut = ProductDetailViewModel(
            productID: "1",
            fetchDetail: FetchProductDetail(
                repository: StubProductRepository(detail: .success(product))
            )
        )

        sut.onAppear()
        await sut.settle()

        XCTAssertEqual(sut.state.value?.description, "An apple a day keeps the doctor away.")
    }

    func test_serverError_surfacesTheBackendsMessage() async {
        let sut = ProductDetailViewModel(
            productID: "999",
            fetchDetail: FetchProductDetail(
                repository: StubProductRepository(detail: .failure(DomainError.server(message: "Access Denied")))
            )
        )

        sut.onAppear()
        await sut.settle()

        guard case .failed(let error) = sut.state else {
            return XCTFail("expected failure, got \(sut.state)")
        }
        XCTAssertEqual(error.message, "Access Denied")
    }

    func test_requestsTheIDItWasGiven() async {
        let repository = StubProductRepository()
        let sut = ProductDetailViewModel(
            productID: "6_id_is_a_string",
            fetchDetail: FetchProductDetail(repository: repository)
        )

        sut.onAppear()
        await sut.settle()

        XCTAssertEqual(repository.requestedProductIDs, ["6_id_is_a_string"])
    }

    func test_close_emitsFinish() {
        let sut = ProductDetailViewModel(
            productID: "1",
            fetchDetail: FetchProductDetail(repository: StubProductRepository())
        )
        var finished = false
        sut.onFinish = { finished = true }

        sut.close()

        XCTAssertTrue(finished)
    }
}

@MainActor
extension ProductDetailViewModel {
    func settle() async {
        let deadline = Date().addingTimeInterval(2)
        while state.isLoading || state.isIdle, Date() < deadline {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }
}
