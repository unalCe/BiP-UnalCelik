import UIKit
import XCTest
@testable import AppFeature

@MainActor
final class ProductFlowCoordinatorTests: XCTestCase {
    private var sut: ProductFlowCoordinator!
    private var navigationController: UINavigationController!
    private var list: MockProductListScreenFactory!
    private var detail: MockProductDetailScreenFactory!

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        sut = nil
        navigationController = nil
        list = nil
        detail = nil
        super.tearDown()
    }

    private func reCreate() {
        list = MockProductListScreenFactory()
        detail = MockProductDetailScreenFactory()
        sut = ProductFlowCoordinator(list: list, detail: detail)
        navigationController = sut.navigationController
    }

    func test_start_setsTheListAsRoot() {
        sut.start()

        XCTAssertEqual(list.invokedMakeScreenCount, 1)
        XCTAssertEqual(navigationController.viewControllers, [list.stubbedMakeScreenResult])
    }

    func test_selectingAProduct_pushesItsDetail() {
        sut.start()

        list.invokedMakeScreenParameters?.onSelectProduct("6_id_is_a_string")

        XCTAssertEqual(detail.invokedMakeScreenParameters?.productID, "6_id_is_a_string")
        XCTAssertEqual(navigationController.viewControllers,
                       [list.stubbedMakeScreenResult, detail.stubbedMakeScreenResult])
    }

    func test_finishingTheDetail_popsBackToTheList() {
        sut.start()
        list.invokedMakeScreenParameters?.onSelectProduct("1")

        detail.invokedMakeScreenParameters?.onFinish()

        XCTAssertEqual(navigationController.viewControllers, [list.stubbedMakeScreenResult])
    }

    /// Screens hold the coordinator weakly; an intent that outlives it is a no-op,
    /// not a crash or a retain cycle.
    func test_intentsAfterTheCoordinatorIsGone_doNothing() {
        sut.start()
        let onSelectProduct = list.invokedMakeScreenParameters?.onSelectProduct

        sut = nil
        onSelectProduct?("1")

        XCTAssertFalse(detail.invokedMakeScreen)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }
}
