import CommonKit
import ImageCacheKit
import ImageCacheKitMocks
import ProductDomain
import ProductPresentation
import ProductRepositoryMocks
import SharedDomain
import UIKit
import XCTest
@testable import ProductListVIPER

private struct NeverFinishing: FetchProductsUseCase {
    func execute() async throws -> [Product] {
        try await Task.sleep(nanoseconds: 60_000_000_000)
        return []
    }
}

/// The VIPER counterpart of the MVVM UIKit controller tests. The controller is
/// wired to a real Presenter and Interactor over a stub repository, so these
/// cover the View's half of the contract end to end.
@MainActor
final class ProductListViewControllerTests: XCTestCase {
    func test_loaded_populatesTheGrid() async {
        let (sut, _) = makeSUT()
        sut.loadViewIfNeeded()
        await settle()

        XCTAssertEqual(collectionView(in: sut)?.numberOfItems(inSection: 0), Product.fixtures.count)
    }

    func test_loading_showsTheSkeleton() async {
        let (sut, _) = makeSUT(fetch: NeverFinishing())
        sut.loadViewIfNeeded()
        await settle()

        XCTAssertEqual(skeletonView(in: sut)?.isHidden, false)
        XCTAssertEqual(collectionView(in: sut)?.isHidden, true)
    }

    func test_loaded_hidesTheSkeleton() async {
        let (sut, _) = makeSUT()
        sut.loadViewIfNeeded()
        await settle()

        XCTAssertEqual(skeletonView(in: sut)?.isHidden, true)
    }

    func test_failure_hidesTheGrid() async {
        let (sut, _) = makeSUT(
            fetch: FetchProducts(repository: StubProductRepository(products: .failure(DomainError.offline)))
        )
        sut.loadViewIfNeeded()
        await settle()

        XCTAssertEqual(collectionView(in: sut)?.isHidden, true)
    }

    func test_selectingAnItem_routesWithTheProductID() async {
        let (sut, router) = makeSUT()
        sut.loadViewIfNeeded()
        await settle()

        guard let grid = collectionView(in: sut) else { return XCTFail("no collection view") }
        grid.delegate?.collectionView?(grid, didSelectItemAt: IndexPath(item: 1, section: 0))

        XCTAssertEqual(router.routedProductIDs, ["6_id_is_a_string"])
    }

    // the grid drops a repeated id rather than crash; selection must still
    // route to what the tapped cell shows, which an index into the
    // Presenter's undeduplicated array would not
    func test_duplicateIDs_selectionRoutesToTheTappedCell() async {
        let products = [
            Product(id: "1", name: "Apples", price: Money(minorUnits: 120), imageURL: nil),
            Product(id: "1", name: "Apples again", price: Money(minorUnits: 120), imageURL: nil),
            Product(id: "2", name: "Bananas", price: Money(minorUnits: 88), imageURL: nil),
        ]
        let (sut, router) = makeSUT(
            fetch: FetchProducts(repository: StubProductRepository(products: .success(products)))
        )
        sut.loadViewIfNeeded()
        await settle()

        guard let grid = collectionView(in: sut) else { return XCTFail("no collection view") }
        XCTAssertEqual(grid.numberOfItems(inSection: 0), 2)
        grid.delegate?.collectionView?(grid, didSelectItemAt: IndexPath(item: 1, section: 0))

        XCTAssertEqual(router.routedProductIDs, ["2"])
    }

    // prefetch and cell must land in the same bucketed cache entry
    func test_prefetchRequest_matchesWhatTheCellAsksFor() async {
        let loader = MockImageLoader()
        let prefetcher = MockImagePrefetcher()
        let (sut, _) = makeSUT(loader: loader, prefetcher: prefetcher)

        sut.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        sut.loadViewIfNeeded()
        await settle()

        guard let grid = collectionView(in: sut) else { return XCTFail("no collection view") }
        sut.view.layoutIfNeeded()
        grid.layoutIfNeeded()
        // a second pass: configuring a cell marks its image view dirty during
        // the first one, and that is when the view measures itself
        grid.visibleCells.forEach { $0.layoutIfNeeded() }

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
        fetch: FetchProductsUseCase = FetchProducts(repository: StubProductRepository()),
        loader: MockImageLoader = MockImageLoader(),
        prefetcher: MockImagePrefetcher = MockImagePrefetcher()
    ) -> (ProductListViewController, SpyRouter) {
        let view = ProductListViewController(imageLoader: loader, imagePrefetcher: prefetcher)
        let router = SpyRouter()
        let presenter = ProductListPresenter(
            interactor: ProductListInteractor(fetchProducts: fetch),
            router: router
        )
        presenter.view = view
        view.presenter = presenter
        return (view, router)
    }

    /// The Presenter loads in a `Task`, and the snapshot lands a turn later.
    private func settle() async {
        for _ in 0..<100 { await Task.yield() }
    }

    private func collectionView(in controller: UIViewController) -> UICollectionView? {
        controller.view.subviews.compactMap { $0 as? UICollectionView }.first
    }

    private func skeletonView(in controller: UIViewController) -> ProductListSkeletonView? {
        controller.view.subviews.compactMap { $0 as? ProductListSkeletonView }.first
    }
}

@MainActor
private final class SpyRouter: ProductListRouterInterface {
    private(set) var routedProductIDs: [String] = []

    func routeToDetail(productID: String) {
        routedProductIDs.append(productID)
    }
}
