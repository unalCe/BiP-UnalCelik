import CommonKit
import ImageCacheKit
import ImageCacheKitMocks
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

    // prefetch and cell must land in the same bucketed cache entry
    func test_prefetchRequest_matchesWhatTheCellAsksFor() async {
        let loader = MockImageLoader()
        let prefetcher = MockImagePrefetcher()
        let (sut, _) = makeSUT(loader: loader, prefetcher: prefetcher)

        sut.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        sut.loadViewIfNeeded()
        await sut.settle()

        guard let grid = collectionView(in: sut) else { return XCTFail("no collection view") }
        sut.view.layoutIfNeeded()
        grid.layoutIfNeeded()
        // A second pass: configuring a cell marks its image view dirty during
        // the first one, and that is when the view measures itself.
        grid.visibleCells.forEach { $0.layoutIfNeeded() }

        // The cells' loads are dispatched into Tasks, so let them land.
        for _ in 0..<200 where loader.requestedRequests.isEmpty { await Task.yield() }

        grid.prefetchDataSource?.collectionView(
            grid, prefetchItemsAt: [IndexPath(item: 0, section: 0)]
        )

        guard let prefetched = prefetcher.prefetchedRequests.first else {
            return XCTFail("the collection view produced no prefetch request")
        }
        guard let fromCell = loader.requestedRequests.first(where: { $0.url == prefetched.url }) else {
            return XCTFail("no cell ever requested \(prefetched.url)")
        }

        XCTAssertEqual(prefetched.maxPixelSize, fromCell.maxPixelSize)
    }

    // MARK: - Helpers

    private func makeSUT(
        repository: StubProductRepository = StubProductRepository(),
        loader: MockImageLoader = MockImageLoader(),
        prefetcher: MockImagePrefetcher = MockImagePrefetcher()
    ) -> (ProductListViewController, ProductListViewModel) {
        let viewModel = ProductListViewModel(fetchProducts: FetchProducts(repository: repository))
        return (
            ProductListViewController(
                viewModel: viewModel,
                imageLoader: loader,
                imagePrefetcher: prefetcher
            ),
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
