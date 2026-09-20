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

    // MARK: - Helpers

    private func makeSUT(
        repository: StubProductRepository = StubProductRepository(),
        loader: MockImageLoader = MockImageLoader()
    ) -> (ProductListViewController, ProductListViewModel) {
        let viewModel = ProductListViewModel(fetchProducts: FetchProducts(repository: repository))
        return (
            ProductListViewController(viewModel: viewModel, imageLoader: loader),
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
