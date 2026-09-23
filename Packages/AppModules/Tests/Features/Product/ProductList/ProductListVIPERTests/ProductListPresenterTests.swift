import CommonKit
import ProductDetailInterface
import ProductDomain
import ProductPresentation
import ProductRepositoryMocks
import SharedDomain
import UIKit
import Foundation
import XCTest
@testable import ProductListVIPER

/// The VIPER counterpart of `ProductListViewModelTests` — same behaviours,
/// asserted through a different seam. The Presenter pushes into a spy View
/// instead of publishing state.
@MainActor
final class ProductListPresenterTests: XCTestCase {
    func test_viewDidLoad_pushesLoadingThenLoaded() async {
        let (sut, view, _) = makeSUT(repository: StubProductRepository())

        sut.viewDidLoad()
        await view.settle()

        XCTAssertEqual(view.receivedStates.count, 2)
        XCTAssertTrue(view.receivedStates.first?.isLoading ?? false)
        XCTAssertEqual(view.receivedStates.last?.value?.map(\.title), ["Apples", "Pork", "Peppers"])
    }

    func test_emptyResult_pushesEmpty() async {
        let (sut, view, _) = makeSUT(
            repository: StubProductRepository(products: .success([]))
        )

        sut.viewDidLoad()
        await view.settle()

        XCTAssertEqual(view.receivedStates.last, .empty)
    }

    func test_failure_pushesMappedError() async {
        let (sut, view, _) = makeSUT(
            repository: StubProductRepository(products: .failure(DomainError.server(message: "Access Denied")))
        )

        sut.viewDidLoad()
        await view.settle()

        guard case .failed(let error) = view.receivedStates.last else {
            return XCTFail("expected failure, got \(String(describing: view.receivedStates.last))")
        }
        XCTAssertEqual(error.message, "Access Denied")
    }

    func test_didSelectItem_routesWithProductID() async {
        let (sut, view, router) = makeSUT(repository: StubProductRepository())

        sut.viewDidLoad()
        await view.settle()
        sut.didSelectItem(id: "6_id_is_a_string")

        XCTAssertEqual(router.routedProductIDs, ["6_id_is_a_string"])
    }

    func test_didSelectItem_unknownID_doesNothing() {
        let (sut, _, router) = makeSUT(repository: StubProductRepository())

        sut.didSelectItem(id: "not_loaded")

        XCTAssertTrue(router.routedProductIDs.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(
        repository: StubProductRepository
    ) -> (ProductListPresenter, SpyView, SpyRouter) {
        let view = SpyView()
        let router = SpyRouter()
        let presenter = ProductListPresenter(
            interactor: ProductListInteractor(
                fetchProducts: FetchProducts(repository: repository)
            ),
            router: router
        )
        presenter.view = view
        view.presenter = presenter
        return (presenter, view, router)
    }
}

@MainActor
private final class SpyView: ProductListViewInterface {
    var presenter: ProductListPresenterInterface?
    private(set) var receivedStates: [ViewState<[ProductDisplayModel]>] = []

    func display(_ state: ViewState<[ProductDisplayModel]>) {
        receivedStates.append(state)
    }

    func settle() async {
        let deadline = Date().addingTimeInterval(2)
        while receivedStates.count < 2, Date() < deadline {
            try? await Task.sleep(for: .milliseconds(5))
        }
    }
}

@MainActor
private final class SpyRouter: ProductListRouterInterface {
    private(set) var routedProductIDs: [String] = []

    func routeToDetail(productID: String) {
        routedProductIDs.append(productID)
    }
}
