import CommonKit
import ProductDomain
import ProductDomainMocks
import ProductPresentation
import ProductRepositoryMocks
import SharedDomain
import XCTest

@testable import ProductListMVVM

@MainActor
final class ProductListViewModelTests: XCTestCase {
    private var viewModel: ProductListViewModel!
    private var fetchProducts: MockFetchProductsUseCase!

    /// `ProductListResponse.json`, through the real DTO and mapper.
    private var products: [Product] { ProductFixture.list() }

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        viewModel = nil
        fetchProducts = nil
        super.tearDown()
    }

    private func reCreate() {
        fetchProducts = .init()
        fetchProducts.stubbedExecuteResult = .success(products)
        viewModel = ProductListViewModel(fetchProducts: fetchProducts)
    }

    /// The view model loads in a `Task`; awaiting it is the whole wait — no sleeps.
    private func appearAndWait() async {
        viewModel.onAppear()
        await viewModel.loadTask?.value
    }

    // MARK: - onAppear

    func test_onAppear_showsLoading() {
        XCTAssertEqual(viewModel.state, .idle)

        viewModel.onAppear()

        XCTAssertEqual(viewModel.state, .loading)
    }

    func test_onAppear_withProducts_mapsThemForDisplay() async {
        XCTAssertFalse(fetchProducts.invokedExecute)

        await appearAndWait()

        XCTAssertEqual(fetchProducts.invokedExecuteCount, 1)
        XCTAssertEqual(viewModel.state, .loaded(ProductDisplayMapper().map(products)))
        XCTAssertEqual(viewModel.state.value?.map(\.title), ["Apples", "Pork", "Peppers"])
    }

    func test_onAppear_withEmptyResponse_showsEmpty() async {
        fetchProducts.stubbedExecuteResult = .success(ProductFixture.list("EmptyProductListResponse"))

        await appearAndWait()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func test_onAppear_withServerError_showsTheBackendsMessage() async {
        fetchProducts.stubbedExecuteResult = .failure(DomainError.server(message: "Access Denied"))

        await appearAndWait()

        XCTAssertEqual(viewModel.state.failure?.message, "Access Denied")
    }

    func test_onAppear_offline_showsOfflineError() async {
        fetchProducts.stubbedExecuteResult = .failure(DomainError.offline)

        await appearAndWait()

        XCTAssertEqual(viewModel.state.failure?.title, "You're offline")
    }

    func test_onAppear_onceLoaded_doesNotLoadAgain() async {
        await appearAndWait()

        viewModel.onAppear()

        XCTAssertEqual(fetchProducts.invokedExecuteCount, 1)
        XCTAssertNotNil(viewModel.state.value, "a second onAppear must not reset to loading")
    }

    // MARK: - retry

    func test_retry_loadsAgain() async {
        fetchProducts.stubbedExecuteResult = .failure(DomainError.offline)
        await appearAndWait()
        fetchProducts.stubbedExecuteResult = .success(products)

        viewModel.retry()
        XCTAssertEqual(viewModel.state, .loading)
        await viewModel.loadTask?.value

        XCTAssertEqual(fetchProducts.invokedExecuteCount, 2)
        XCTAssertEqual(viewModel.state.value?.count, products.count)
    }

    // MARK: - didSelectItem

    /// The view model emits an id and performs no navigation — which is what
    /// lets the same instance drive a UIKit push and a SwiftUI path append.
    func test_didSelectItem_emitsTheProductID() async {
        var selectedIDs: [String] = []
        viewModel.onSelectProduct = { selectedIDs.append($0) }
        await appearAndWait()

        viewModel.didSelectItem(id: "6_id_is_a_string")

        XCTAssertEqual(selectedIDs, ["6_id_is_a_string"])
    }
}
