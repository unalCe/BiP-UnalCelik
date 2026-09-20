import ProductDetailInterface
import UIKit
import XCTest
@testable import ProductListVIPER

/// The Router is the one type in this project that uses `@Dependency`.
/// It also exposes a direct-injection initializer, so this test never touches
/// the shared engine — which is the point of offering both.
@MainActor
final class ProductListRouterTests: XCTestCase {
    func test_routeToDetail_asksTheDetailModuleAndPushes() {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let detail = SpyDetailModule()
        let sut = ProductListRouter(
            navigationController: navigationController,
            detailModule: detail
        )

        sut.routeToDetail(productID: "6_id_is_a_string")

        XCTAssertEqual(detail.requestedProductIDs, ["6_id_is_a_string"])
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }
}

@MainActor
private final class SpyDetailModule: ProductDetailInterface {
    private(set) var requestedProductIDs: [String] = []

    func createModule(
        navigationController: UINavigationController?,
        productID: String
    ) -> UIViewController {
        requestedProductIDs.append(productID)
        return UIViewController()
    }
}
