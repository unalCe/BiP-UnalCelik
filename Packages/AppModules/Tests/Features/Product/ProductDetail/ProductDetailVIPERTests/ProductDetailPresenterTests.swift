import CommonKit
import ProductPresentation
import ProductRepositoryMocks
import SharedDomain
import XCTest

@testable import ProductDetailVIPER

@MainActor
final class ProductDetailPresenterTests: XCTestCase {
    private var presenter: ProductDetailPresenter!
    private var view: MockProductDetailView!
    private var interactor: MockProductDetailInteractor!
    private var router: MockProductDetailRouter!

    /// `ProductDetailResponse.json`, through the real DTO and mapper, then the
    /// display mapper — exactly what the real interactor would hand over.
    private var product: ProductDisplayModel {
        ProductDisplayMapper().map(ProductFixture.detail())
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

    private func reCreate(productID: String = "1") {
        view = .init()
        interactor = .init()
        router = .init()
        interactor.stubbedLoadProductResult = .success(product)
        presenter = ProductDetailPresenter(productID: productID, interactor: interactor, router: router)
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

    func test_viewDidLoad_requestsTheIDItWasGiven() async {
        reCreate(productID: "6_id_is_a_string")
        XCTAssertFalse(interactor.invokedLoadProduct)

        await loadAndWait()

        XCTAssertEqual(interactor.invokedLoadProductCount, 1)
        XCTAssertEqual(interactor.invokedLoadProductParameters?.id, "6_id_is_a_string")
    }

    func test_viewDidLoad_withProduct_displaysLoaded() async {
        await loadAndWait()

        XCTAssertEqual(view.invokedDisplayParametersList.map(\.state), [.loading, .loaded(product)])
        XCTAssertEqual(view.invokedDisplayParameters?.state.value?.description,
                       "An apple a day keeps the doctor away.")
    }

    func test_viewDidLoad_withServerError_displaysTheBackendsMessage() async {
        interactor.stubbedLoadProductResult = .failure(DomainError.server(message: "Access Denied"))

        await loadAndWait()

        XCTAssertEqual(view.invokedDisplayParameters?.state.failure?.message, "Access Denied")
    }

    // MARK: - didTapRetry

    func test_didTapRetry_loadsAgain() async {
        interactor.stubbedLoadProductResult = .failure(DomainError.offline)
        await loadAndWait()
        interactor.stubbedLoadProductResult = .success(product)

        presenter.didTapRetry()
        XCTAssertEqual(view.invokedDisplayParameters?.state, .loading)
        await presenter.loadTask?.value

        XCTAssertEqual(interactor.invokedLoadProductCount, 2)
        XCTAssertEqual(view.invokedDisplayParameters?.state, .loaded(product))
    }

    // MARK: - didTapClose

    func test_didTapClose_dismisses() {
        XCTAssertFalse(router.invokedDismiss)

        presenter.didTapClose()

        XCTAssertEqual(router.invokedDismissCount, 1)
    }
}
