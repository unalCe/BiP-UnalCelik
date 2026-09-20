import DependencyEngine
import ImageCacheKit
import ImageCacheKitLive
import NetworkingKit
import NetworkingKitLive
import PersistenceKit
import PersistenceKitLive
import ProductDetailInterface
import ProductDomain
import ProductListInterface
import UIKit
import XCTest
@testable import AppFeature

@MainActor
final class FlowRegistrationTests: XCTestCase {
    /// Every style must resolve to a working pair of modules. Exhaustive over
    /// `FlowStyle`, so adding or removing a case updates this for free.
    func test_everyFlowStyle_registersBothModules() {
        for style in FlowStyle.allCases {
            let engine = makeBootstrappedEngine()

            FlowRegistration.register(style, to: engine)

            let list: (any ProductListInterface)? =
                engine.resolve((any ProductListInterface).self)
            let detail: (any ProductDetailInterface)? =
                engine.resolve((any ProductDetailInterface).self)

            XCTAssertNotNil(list, "no list module for \(style)")
            XCTAssertNotNil(detail, "no detail module for \(style)")
            XCTAssertNotNil(
                list?.createModule(navigationController: UINavigationController()),
                "list module for \(style) produced no view controller"
            )
        }
    }

    /// Switching architecture must not rebuild the repository — that is the
    /// visible proof the core is untouched by the choice above it.
    func test_switchingStyle_keepsTheSameRepositoryInstance() {
        let engine = makeBootstrappedEngine()
        let before: (any ProductRepositoryInterface)? =
            engine.resolve((any ProductRepositoryInterface).self)

        FlowRegistration.register(.mvvmUIKit, to: engine)
        FlowRegistration.register(.viperUIKit, to: engine)

        let after: (any ProductRepositoryInterface)? =
            engine.resolve((any ProductRepositoryInterface).self)

        XCTAssertTrue(
            (before as AnyObject) === (after as AnyObject),
            "the repository must survive an architecture switch"
        )
    }

    private func makeBootstrappedEngine() -> DependencyEngine {
        let engine = DependencyEngine()
        AppDependencyRegistration.register(to: engine)
        return engine
    }
}
