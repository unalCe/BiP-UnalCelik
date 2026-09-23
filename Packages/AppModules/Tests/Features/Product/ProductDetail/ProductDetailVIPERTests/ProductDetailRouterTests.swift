import UIKit
import XCTest

@testable import ProductDetailVIPER

@MainActor
final class ProductDetailRouterTests: XCTestCase {
    private var router: ProductDetailRouter!
    private var navigationController: UINavigationController!
    private var detailScreen: UIViewController!

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        router = nil
        navigationController = nil
        detailScreen = nil
        super.tearDown()
    }

    private func reCreate() {
        detailScreen = UIViewController()
        navigationController = UINavigationController(rootViewController: UIViewController())
        navigationController.pushViewController(detailScreen, animated: false)
        router = ProductDetailRouter(navigationController: navigationController)
    }

    func test_dismiss_popsTheDetailScreen() {
        XCTAssertTrue(navigationController.topViewController === detailScreen)

        router.dismiss()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertFalse(navigationController.viewControllers.contains(detailScreen))
    }
}
