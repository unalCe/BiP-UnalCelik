import UIKit
import XCTest

@testable import AppFeature

@MainActor
final class VIPERFlowCoordinatorTests: XCTestCase {
    private var coordinator: VIPERFlowCoordinator!
    private var list: MockProductListModule!

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        coordinator = nil
        list = nil
        super.tearDown()
    }

    private func reCreate() {
        list = MockProductListModule()
        coordinator = VIPERFlowCoordinator(list: list)
    }

    func test_start_setsTheListAsRoot() {
        XCTAssertFalse(list.invokedCreateModule)

        coordinator.start()

        XCTAssertEqual(list.invokedCreateModuleCount, 1)
        XCTAssertEqual(coordinator.navigationController.viewControllers, [list.stubbedCreateModuleResult])
    }

    /// VIPER routers push onto the stack they were built with, so the list
    /// module must receive the coordinator's own navigation controller.
    func test_start_handsTheListItsNavigationController() {
        coordinator.start()

        XCTAssertTrue(list.invokedCreateModuleParameters?.navigationController === coordinator.navigationController)
    }
}
