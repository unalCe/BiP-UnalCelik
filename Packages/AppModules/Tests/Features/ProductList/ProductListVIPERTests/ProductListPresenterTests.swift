import CommonKit
import ProductDetailInterface
import ProductDomain
import ProductRepositoryMocks
import UIKit
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
            repository: StubProductRepository(products: .failure(DomainError.notFound))
        )

        sut.viewDidLoad()
        await view.settle()

        guard case .failed(let error) = view.receivedStates.last else {
            return XCTFail("expected failure, got \(String(describing: view.receivedStates.last))")
        }
        XCTAssertFalse(error.isRetryable)
    }

    func test_didSelectItem_routesWithProductID() async {
        let (sut, view, router) = makeSUT(repository: StubProductRepository())

        sut.viewDidLoad()
        await view.settle()
        sut.didSelectItem(at: 1)

        XCTAssertEqual(router.routedProductIDs, ["6_id_is_a_string"])
    }

    func test_didSelectItem_outOfRange_doesNothing() {
        let (sut, _, router) = makeSUT(repository: StubProductRepository())

        sut.didSelectItem(at: 99)

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
    var presenter: (any ProductListPresenterInterface)?
    private(set) var receivedStates: [ViewState<[ProductDisplayModel]>] = []

    func display(_ state: ViewState<[ProductDisplayModel]>) {
        receivedStates.append(state)
    }

    func settle() async {
        for _ in 0..<50 {
            if receivedStates.count >= 2 { return }
            await Task.yield()
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
