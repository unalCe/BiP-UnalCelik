import CommonKit
import ProductDomain
import ProductDomainMocks
import ProductPresentation
import ProductRepositoryMocks
import SharedDomain
import XCTest

@testable import ProductDetailMVVM

@MainActor
final class ProductDetailViewModelTests: XCTestCase {
    private var viewModel: ProductDetailViewModel!
    private var fetchDetail: MockFetchProductDetailUseCase!

    /// `ProductDetailResponse.json`, through the real DTO and mapper.
    private var product: Product { ProductFixture.detail() }

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        viewModel = nil
        fetchDetail = nil
        super.tearDown()
    }

    private func reCreate(productID: String = "1") {
        fetchDetail = .init()
        fetchDetail.stubbedExecuteResult = .success(product)
        viewModel = ProductDetailViewModel(productID: productID, fetchDetail: fetchDetail)
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

    func test_onAppear_requestsTheIDItWasGiven() async {
        reCreate(productID: "6_id_is_a_string")
        XCTAssertFalse(fetchDetail.invokedExecute)

        await appearAndWait()

        XCTAssertEqual(fetchDetail.invokedExecuteCount, 1)
        XCTAssertEqual(fetchDetail.invokedExecuteParameters?.id, "6_id_is_a_string")
    }

    func test_onAppear_withProduct_mapsItForDisplay() async {
        await appearAndWait()

        XCTAssertEqual(viewModel.state, .loaded(ProductDisplayMapper().map(product)))
        XCTAssertEqual(viewModel.state.value?.description, "An apple a day keeps the doctor away.")
    }

    func test_onAppear_withServerError_showsTheBackendsMessage() async {
        fetchDetail.stubbedExecuteResult = .failure(DomainError.server(message: "Access Denied"))

        await appearAndWait()

        XCTAssertEqual(viewModel.state.failure?.message, "Access Denied")
    }

    func test_onAppear_onceLoaded_doesNotLoadAgain() async {
        await appearAndWait()

        viewModel.onAppear()

        XCTAssertEqual(fetchDetail.invokedExecuteCount, 1)
    }

    // MARK: - retry

    func test_retry_loadsAgain() async {
        fetchDetail.stubbedExecuteResult = .failure(DomainError.offline)
        await appearAndWait()
        fetchDetail.stubbedExecuteResult = .success(product)

        viewModel.retry()
        XCTAssertEqual(viewModel.state, .loading)
        await viewModel.loadTask?.value

        XCTAssertEqual(fetchDetail.invokedExecuteCount, 2)
        XCTAssertNotNil(viewModel.state.value)
    }

    // MARK: - close

    func test_close_emitsFinish() {
        var finishCount = 0
        viewModel.onFinish = { finishCount += 1 }

        viewModel.close()

        XCTAssertEqual(finishCount, 1)
    }
}
