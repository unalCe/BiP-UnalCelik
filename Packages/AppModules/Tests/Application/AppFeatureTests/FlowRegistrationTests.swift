import DependencyEngine
import ProductDetailInterface
import ProductDomain
import ProductListInterface
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

    /// A private engine with the app's graph over an in-memory store. Modules
    /// are built but never loaded, so nothing touches the network.
    private func reCreate() {
        engine = DependencyEngine()
        AppDependencyRegistration.register(to: engine, inMemory: true)
    }

    /// Exhaustive over `FlowStyle`, so adding or removing a case updates this for free.
    func test_everyFlowStyle_registersBothModules() {
        for style in FlowStyle.allCases {
            reCreate()

            FlowRegistration.register(style, to: engine)

            let list: ProductListInterface? = engine.resolve(ProductListInterface.self)
            let detail: ProductDetailInterface? = engine.resolve(ProductDetailInterface.self)
            XCTAssertNotNil(list, "no list module for \(style)")
            XCTAssertNotNil(detail, "no detail module for \(style)")
        }
    }

    /// Switching architecture must not rebuild the repository — that is the
    /// visible proof the core is untouched by the choice above it.
    func test_switchingStyle_keepsTheSameRepositoryInstance() {
        let before: ProductRepositoryInterface? = engine.resolve(ProductRepositoryInterface.self)

        FlowRegistration.register(.mvvmUIKit, to: engine)
        FlowRegistration.register(.viperUIKit, to: engine)

        let after: ProductRepositoryInterface? = engine.resolve(ProductRepositoryInterface.self)
        XCTAssertTrue((before as AnyObject) === (after as AnyObject),
                      "the repository must survive an architecture switch")
    }
}
