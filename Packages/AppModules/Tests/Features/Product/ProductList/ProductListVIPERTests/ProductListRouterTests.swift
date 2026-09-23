import ProductDetailInterface
import UIKit
import XCTest

@testable import ProductListVIPER

/// The Router is the one type in this project that uses `@Dependency`. It also
/// has a direct-injection initializer, so this test never touches the shared
/// engine — which is the point of offering both.
@MainActor
final class ProductListRouterTests: XCTestCase {
    private var router: ProductListRouter!
    private var navigationController: UINavigationController!
    private var detailModule: MockProductDetailModule!

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        router = nil
        navigationController = nil
        detailModule = nil
        super.tearDown()
    }

    private func reCreate() {
        navigationController = UINavigationController(rootViewController: UIViewController())
        detailModule = .init()
        detailModule.stubbedCreateModuleResult = UIViewController()
        router = ProductListRouter(navigationController: navigationController, detailModule: detailModule)
    }

    func test_routeToDetail_buildsTheDetailModuleForTheProduct() {
        XCTAssertFalse(detailModule.invokedCreateModule)

        router.routeToDetail(productID: "6_id_is_a_string")

        XCTAssertEqual(detailModule.invokedCreateModuleCount, 1)
        XCTAssertEqual(detailModule.invokedCreateModuleParameters?.productID, "6_id_is_a_string")
        XCTAssertTrue(detailModule.invokedCreateModuleParameters?.navigationController === navigationController)
    }

    func test_routeToDetail_pushesTheDetailScreen() {
        router.routeToDetail(productID: "1")

        XCTAssertTrue(navigationController.viewControllers.last === detailModule.stubbedCreateModuleResult)
    }
}
