import CommonKit
import ProductPresentation
import ProductRepositoryMocks
import SharedDomain
import XCTest

@testable import ProductListVIPER

@MainActor
final class ProductListPresenterTests: XCTestCase {
    private var presenter: ProductListPresenter!
    private var view: MockProductListView!
    private var interactor: MockProductListInteractor!
    private var router: MockProductListRouter!

    /// `ProductListResponse.json`, through the real DTO and mapper, then the
    /// display mapper — exactly what the real interactor would hand over.
    private var products: [ProductDisplayModel] {
        ProductDisplayMapper().map(ProductFixture.list())
    }

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        presenter = nil
        view = nil
        interactor = nil
        router = nil
        super.tearDown()
    }

    private func reCreate() {
        view = .init()
        interactor = .init()
        router = .init()
        interactor.stubbedLoadProductsResult = .success(products)
        presenter = ProductListPresenter(interactor: interactor, router: router)
        presenter.view = view
    }

    /// The presenter loads in a `Task`; awaiting it is the whole wait — no sleeps.
    private func loadAndWait() async {
        presenter.viewDidLoad()
        await presenter.loadTask?.value
    }

    // MARK: - viewDidLoad

    func test_viewDidLoad_displaysLoading() {
        XCTAssertFalse(view.invokedDisplay)

        presenter.viewDidLoad()

        XCTAssertEqual(view.invokedDisplayCount, 1)
        XCTAssertEqual(view.invokedDisplayParameters?.state, .loading)
    }

    func test_viewDidLoad_withProducts_displaysLoaded() async {
        XCTAssertFalse(interactor.invokedLoadProducts)

        await loadAndWait()

        XCTAssertEqual(interactor.invokedLoadProductsCount, 1)
        XCTAssertEqual(view.invokedDisplayParametersList.map(\.state), [.loading, .loaded(products)])
        XCTAssertEqual(view.invokedDisplayParameters?.state.value?.map(\.title), ["Apples", "Pork", "Peppers"])
    }

    func test_viewDidLoad_withEmptyResponse_displaysEmpty() async {
        interactor.stubbedLoadProductsResult = .success(
            ProductDisplayMapper().map(ProductFixture.list("EmptyProductListResponse"))
        )

        await loadAndWait()

        XCTAssertEqual(view.invokedDisplayParameters?.state, .empty)
    }

    func test_viewDidLoad_withServerError_displaysTheBackendsMessage() async {
        interactor.stubbedLoadProductsResult = .failure(DomainError.server(message: "Access Denied"))

        await loadAndWait()

        XCTAssertEqual(view.invokedDisplayParameters?.state.failure?.message, "Access Denied")
    }

    func test_viewDidLoad_offline_displaysOfflineError() async {
        interactor.stubbedLoadProductsResult = .failure(DomainError.offline)

        await loadAndWait()

        XCTAssertEqual(view.invokedDisplayParameters?.state.failure?.title, "You're offline")
    }

    // MARK: - didTapRetry

    func test_didTapRetry_loadsAgain() async {
        interactor.stubbedLoadProductsResult = .failure(DomainError.offline)
        await loadAndWait()
        interactor.stubbedLoadProductsResult = .success(products)

        presenter.didTapRetry()
        XCTAssertEqual(view.invokedDisplayParameters?.state, .loading)
        await presenter.loadTask?.value

        XCTAssertEqual(interactor.invokedLoadProductsCount, 2)
        XCTAssertEqual(view.invokedDisplayParameters?.state, .loaded(products))
    }

    // MARK: - didSelectItem

    func test_didSelectItem_loadedProduct_routesToDetail() async {
        await loadAndWait()
        XCTAssertFalse(router.invokedRouteToDetail)

        presenter.didSelectItem(id: "6_id_is_a_string")

        XCTAssertEqual(router.invokedRouteToDetailCount, 1)
        XCTAssertEqual(router.invokedRouteToDetailParameters?.productID, "6_id_is_a_string")
    }

    func test_didSelectItem_unknownProduct_doesNotRoute() async {
        await loadAndWait()

        presenter.didSelectItem(id: "not_loaded")

        XCTAssertFalse(router.invokedRouteToDetail)
    }

    func test_didSelectItem_beforeProductsLoad_doesNotRoute() {
        presenter.didSelectItem(id: "1")

        XCTAssertFalse(router.invokedRouteToDetail)
    }
}
