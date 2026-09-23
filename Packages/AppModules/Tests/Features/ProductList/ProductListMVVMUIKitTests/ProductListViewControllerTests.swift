import CommonKit
import ImageCacheKit
import ImageCacheKitMocks
import ProductDomain
import ProductListMVVM
@testable import ProductListMVVMUIKit
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

    // a long title used to crush the price label to zero height: every cell was
    // forced to one section-wide height, so nothing could grow for its content
    func test_aLongTitleDoesNotCrushThePrice() async {
        let products = [
            Product(id: "1", name: "Apples", price: Money(minorUnits: 120), imageURL: nil),
            Product(id: "2", name: "Bananas and a very long name that wraps onto two lines",
                    price: Money(minorUnits: 88), imageURL: nil),
        ]
        let (sut, _) = makeSUT(repository: StubProductRepository(products: .success(products)))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = sut
        window.makeKeyAndVisible()
        sut.loadViewIfNeeded()
        await sut.settle()
        window.layoutIfNeeded()

        guard let grid = collectionView(in: sut) else { return XCTFail("no collection view") }
        let cells = grid.visibleCells.sorted { $0.frame.minX < $1.frame.minX }
        XCTAssertEqual(cells.count, 2)

        for cell in cells {
            let labels = cell.contentView.subviews.compactMap { $0 as? UILabel }
            for label in labels {
                XCTAssertGreaterThan(
                    label.bounds.height, 0,
                    "\(label.text ?? "nil") has no height in a \(cell.bounds.height)pt cell"
                )
                XCTAssertLessThanOrEqual(
                    label.frame.maxY, cell.contentView.bounds.height + 0.5,
                    "\(label.text ?? "nil") overflows its cell"
                )
            }
        }
    }

    // spacing used to come from item contentInsets, which stop separating rows
    // once the item self-sizes — the rows ended up touching
    func test_cellsAreSeparatedAndInsetByTheGutter() async {
        let products = (1...4).map {
            Product(id: "\($0)", name: "Item \($0)", price: Money(minorUnits: 100), imageURL: nil)
        }
        let (sut, _) = makeSUT(repository: StubProductRepository(products: .success(products)))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = sut
        window.makeKeyAndVisible()
        sut.loadViewIfNeeded()
        await sut.settle()
        window.layoutIfNeeded()

        guard let grid = collectionView(in: sut) else { return XCTFail("no collection view") }
        let frames = grid.visibleCells.map(\.frame).sorted { ($0.minY, $0.minX) < ($1.minY, $1.minX) }
        guard frames.count == 4 else { return XCTFail("expected 4 cells, got \(frames.count)") }

        let gutter = ProductListLayout.gutter
        XCTAssertEqual(frames[0].minX, gutter, accuracy: 0.5, "leading margin")
        XCTAssertEqual(grid.bounds.width - frames[1].maxX, gutter, accuracy: 0.5, "trailing margin")
        XCTAssertEqual(frames[1].minX - frames[0].maxX, gutter, accuracy: 0.5, "column gap")
        XCTAssertEqual(frames[2].minY - frames[0].maxY, gutter, accuracy: 0.5, "row gap")
        XCTAssertEqual(
            frames[0].width, ProductListLayout.itemWidth(in: grid.bounds.width), accuracy: 0.5
        )
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
