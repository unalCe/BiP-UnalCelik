import DependencyEngine
import LoggingKitMocks
import ProductDomain
import UIKit
import XCTest
@testable import AppFeature

@MainActor
final class AppShellViewControllerTests: XCTestCase {
    func test_launch_landsOnTheListOfTheGivenStyle() {
        let sut = makeSUT(style: .mvvmUIKit)

        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.currentStyle, .mvvmUIKit)
        XCTAssertEqual(sut.flowController?.viewControllers.count, 1)
        XCTAssertTrue(sut.flowController?.parent === sut)
    }

    func test_everyStyle_getsTheInfoButton() {
        for style in FlowStyle.allCases {
            let sut = makeSUT(style: style)
            sut.loadViewIfNeeded()

            let item = sut.flowController?.viewControllers.first?.navigationItem.rightBarButtonItem
            XCTAssertNotNil(item, "no info button for \(style)")
            XCTAssertEqual(item?.action, #selector(AppShellViewController.showFlowPicker))
        }
    }

    func test_start_swapsTheFlowAndRecordsTheStyle() {
        let sut = makeSUT(style: .mvvmUIKit)
        sut.loadViewIfNeeded()
        let before = sut.flowController

        sut.start(.viperUIKit)

        XCTAssertEqual(sut.currentStyle, .viperUIKit)
        XCTAssertNotNil(sut.flowController)
        XCTAssertFalse(sut.flowController === before)
    }

    /// Restarting rebuilds the screens, not the core underneath them.
    func test_restart_keepsTheSameRepositoryInstance() {
        let engine = makeBootstrappedEngine()
        let sut = AppShellViewController(style: .mvvmUIKit, engine: engine, logger: SpyLogger())
        sut.loadViewIfNeeded()
        let before: ProductRepositoryInterface? = engine.resolve(ProductRepositoryInterface.self)

        sut.start(.mvvmSwiftUI)

        let after: ProductRepositoryInterface? = engine.resolve(ProductRepositoryInterface.self)
        XCTAssertTrue((before as AnyObject) === (after as AnyObject))
    }

    // MARK: - Helpers

    private func makeSUT(style: FlowStyle) -> AppShellViewController {
        AppShellViewController(style: style, engine: makeBootstrappedEngine(), logger: SpyLogger())
    }

    private func makeBootstrappedEngine() -> DependencyEngine {
        let engine = DependencyEngine()
        AppDependencyRegistration.register(to: engine, inMemory: true)
        return engine
    }
}
