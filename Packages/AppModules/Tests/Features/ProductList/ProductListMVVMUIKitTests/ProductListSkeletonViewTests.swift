import CommonKit
import CommonUI
import ImageCacheKitMocks
import ProductDomain
import ProductListMVVM
import ProductRepositoryMocks
import UIKit
import XCTest
@testable import ProductListMVVMUIKit

private struct NeverFinishing: FetchProductsUseCase {
    func execute() async throws -> [Product] {
        try await Task.sleep(nanoseconds: 60_000_000_000)
        return []
    }
}

@MainActor
final class ProductListSkeletonViewTests: XCTestCase {
    func test_visibleWhileLoading_hiddenOnceLoaded() async {
        let (sut, window) = makeSUT(fetch: NeverFinishing())
        _ = window
        await settle(sut)

        guard let skeleton = skeletonView(in: sut) else { return XCTFail("no skeleton") }
        XCTAssertFalse(skeleton.isHidden, "loading must show placeholders")

        let (loaded, loadedWindow) = makeSUT(fetch: FetchProducts(repository: StubProductRepository()))
        _ = loadedWindow
        await settle(loaded)

        XCTAssertEqual(skeletonView(in: loaded)?.isHidden, true)
    }

    func test_sweepRunsWhileLoadingAndStopsOnContent() async {
        let (sut, window) = makeSUT(fetch: NeverFinishing())
        _ = window
        await settle(sut)

        guard let skeleton = skeletonView(in: sut) else { return XCTFail("no skeleton") }
        XCTAssertEqual(skeleton.isSweeping, !UIAccessibility.isReduceMotionEnabled)

        skeleton.stop()
        XCTAssertFalse(skeleton.isSweeping, "the animation must not outlive the loading state")
    }

    /// The point of the whole thing: the placeholders sit exactly where the
    /// cells will, so the swap moves nothing.
    func test_placeholdersLandWhereTheCellsWill() async {
        let (loaded, window) = makeSUT(fetch: FetchProducts(repository: StubProductRepository()))
        await settle(loaded)
        window.layoutIfNeeded()

        guard
            let skeleton = skeletonView(in: loaded),
            let grid = loaded.view.subviews.compactMap({ $0 as? UICollectionView }).first,
            let cell = grid.visibleCells.min(by: { ($0.frame.minY, $0.frame.minX) < ($1.frame.minY, $1.frame.minX) }),
            let imageView = cell.contentView.subviews.compactMap({ $0 as? CachedImageView }).first
        else { return XCTFail("no first cell") }

        let cellImageFrame = imageView.convert(imageView.bounds, to: loaded.view)
        // the view's own placeholders, not a region recomputed here — otherwise
        // this passes even when the view lays them out somewhere else
        guard let first = skeleton.placeholders.first else { return XCTFail("no placeholders") }

        XCTAssertEqual(first.image.minX, cellImageFrame.minX, accuracy: 0.5)
        XCTAssertEqual(first.image.minY, cellImageFrame.minY, accuracy: 0.5)
        XCTAssertEqual(first.image.width, cellImageFrame.width, accuracy: 0.5)
        XCTAssertEqual(first.image.height, cellImageFrame.height, accuracy: 0.5)
    }

    // MARK: - Helpers

    private func makeSUT(fetch: FetchProductsUseCase) -> (ProductListViewController, UIWindow) {
        let sut = ProductListViewController(
            viewModel: ProductListViewModel(fetchProducts: fetch),
            imageLoader: MockImageLoader(),
            imagePrefetcher: MockImagePrefetcher()
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = UINavigationController(rootViewController: sut)
        window.makeKeyAndVisible()
        return (sut, window)
    }

    private func settle(_ sut: ProductListViewController) async {
        sut.loadViewIfNeeded()
        for _ in 0..<200 { await Task.yield() }
        sut.view.layoutIfNeeded()
    }

    private func skeletonView(in controller: UIViewController) -> ProductListSkeletonView? {
        controller.view.subviews.compactMap { $0 as? ProductListSkeletonView }.first
    }
}
