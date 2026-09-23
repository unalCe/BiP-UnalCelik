import DependencyEngine
import ProductDetailInterface
import ProductDomain
import UIKit
import XCTest

@testable import AppFeature

@MainActor
final class FlowRegistrationTests: XCTestCase {
    private var engine: DependencyEngine!

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    /// A private engine with the app's graph over an in-memory store. Screens
    /// are built but never loaded, so nothing touches the network.
    private func reCreate() {
        engine = DependencyEngine()
        AppDependencyRegistration.register(to: engine, inMemory: true)
    }

    /// Every style must produce a coordinator that lands on a root screen.
    /// Exhaustive over `FlowStyle`, so adding or removing a case updates this for free.
    func test_everyFlowStyle_startsOnARootScreen() {
        for style in FlowStyle.allCases {
            reCreate()
            let coordinator = FlowRegistration.makeCoordinator(for: style, engine: engine)

            coordinator.start()

            XCTAssertEqual(coordinator.navigationController.viewControllers.count, 1,
                           "coordinator for \(style) did not set a root screen")
        }
    }

    /// MVVM-C: the coordinator owns navigation, so MVVM styles get one.
    func test_mvvmStyles_getTheProductFlowCoordinator() {
        for style in [FlowStyle.mvvmUIKit, .mvvmSwiftUI] {
            let coordinator = FlowRegistration.makeCoordinator(for: style, engine: engine)

            XCTAssertTrue(coordinator is ProductFlowCoordinator, "\(style)")
        }
    }

    /// VIPER's router resolves its destination through `@Dependency`, so the
    /// VIPER detail module must be in the engine.
    func test_viper_registersTheDetailModuleForItsRouter() {
        let before: ProductDetailInterface? = engine.resolve(ProductDetailInterface.self)
        XCTAssertNil(before)

        _ = FlowRegistration.makeCoordinator(for: .viperUIKit, engine: engine)

        let detail: ProductDetailInterface? = engine.resolve(ProductDetailInterface.self)
        XCTAssertNotNil(detail)
    }

    /// Switching architecture must not rebuild the repository — that is the
    /// visible proof the core is untouched by the choice above it.
    func test_switchingStyle_keepsTheSameRepositoryInstance() {
        let before: ProductRepositoryInterface? = engine.resolve(ProductRepositoryInterface.self)

        _ = FlowRegistration.makeCoordinator(for: .mvvmUIKit, engine: engine)
        _ = FlowRegistration.makeCoordinator(for: .viperUIKit, engine: engine)

        let after: ProductRepositoryInterface? = engine.resolve(ProductRepositoryInterface.self)
        XCTAssertTrue((before as AnyObject) === (after as AnyObject),
                      "the repository must survive an architecture switch")
    }
}
