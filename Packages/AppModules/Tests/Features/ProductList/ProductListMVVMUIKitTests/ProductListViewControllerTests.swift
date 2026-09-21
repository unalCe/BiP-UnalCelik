import CommonKit
import ImageCacheKit
import ImageCacheKitMocks
import PerformanceKitMocks
import ProductDomain
import ProductListMVVM
import ProductListMVVMUIKit
import ProductRepositoryMocks
import UIKit
import XCTest

@MainActor
final class ProductListViewControllerTests: XCTestCase {
    func test_loaded_populatesTheGrid() async {
        let (sut, _) = makeSUT()
        sut.loadViewIfNeeded()
        await sut.settle()

        XCTAssertEqual(collectionView(in: sut)?.numberOfItems(inSection: 0), Product.fixtures.count)
    }

    func test_failure_hidesTheGrid() async {
        let (sut, _) = makeSUT(repository: StubProductRepository(products: .failure(DomainError.offline)))
        sut.loadViewIfNeeded()
        await sut.settle()

        XCTAssertEqual(collectionView(in: sut)?.isHidden, true)
    }

    func test_selectingAnItem_forwardsTheProductID() async {
        var selected: [String] = []
        let (sut, viewModel) = makeSUT()
        viewModel.onSelectProduct = { selected.append($0) }
        sut.loadViewIfNeeded()
        await sut.settle()

        guard let grid = collectionView(in: sut) else { return XCTFail("no collection view") }
        grid.delegate?.collectionView?(grid, didSelectItemAt: IndexPath(item: 1, section: 0))

        XCTAssertEqual(selected, ["6_id_is_a_string"])
    }

    func test_firstSnapshot_endsTimeToContent() async {
        let tracer = RecordingPerformanceTracer()
        let (sut, _) = makeSUT(tracer: tracer)
        sut.loadViewIfNeeded()
        await sut.settle()

        let samples = tracer.samples(for: .listTimeToContent)
        XCTAssertEqual(samples.map(\.outcome), [.completed])
        XCTAssertEqual(samples.first?.attributes["count"], "\(Product.fixtures.count)")
    }

    func test_failure_endsTimeToContentAsFailed() async {
        let tracer = RecordingPerformanceTracer()
        let (sut, _) = makeSUT(
            repository: StubProductRepository(products: .failure(DomainError.offline)),
            tracer: tracer
        )
        sut.loadViewIfNeeded()
        await sut.settle()

        XCTAssertEqual(tracer.samples(for: .listTimeToContent).map(\.outcome), [.failed])
    }

    func test_visibleCells_traceTheirImageWait() async {
        let tracer = RecordingPerformanceTracer()
        let (sut, _) = makeSUT(tracer: tracer)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = sut
        window.makeKeyAndVisible()
        await sut.settle()
        sut.view.layoutIfNeeded()
        await sut.settle()

        let waits = tracer.samples(for: .imageVisibleWait)
        XCTAssertFalse(waits.isEmpty, "laid-out cells should have measured their image")
        XCTAssertTrue(waits.allSatisfy { $0.outcome == .completed })
    }

    // MARK: - Helpers

    private func makeSUT(
        repository: StubProductRepository = StubProductRepository(),
        loader: MockImageLoader = MockImageLoader(),
        tracer: RecordingPerformanceTracer = RecordingPerformanceTracer()
    ) -> (ProductListViewController, ProductListViewModel) {
        let viewModel = ProductListViewModel(fetchProducts: FetchProducts(repository: repository))
        return (
            ProductListViewController(viewModel: viewModel, imageLoader: loader, tracer: tracer),
            viewModel
        )
    }

    private func collectionView(in controller: UIViewController) -> UICollectionView? {
        controller.view.subviews.compactMap { $0 as? UICollectionView }.first
    }
}

@MainActor
private extension ProductListViewController {
    /// The ViewModel starts a detached `Task`, and the snapshot lands a turn later.
    func settle() async {
        for _ in 0..<100 { await Task.yield() }
    }
}
