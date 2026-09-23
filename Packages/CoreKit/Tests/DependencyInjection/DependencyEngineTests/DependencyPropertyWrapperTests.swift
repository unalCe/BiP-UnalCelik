import XCTest

@testable import DependencyEngine

final class DependencyPropertyWrapperTests: XCTestCase {
    private var engine: DependencyEngine!

    override func setUp() {
        super.setUp()
        engine = DependencyEngine()
        engine.register(value: EnglishGreeter() as GreeterInterface, for: GreeterInterface.self)
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    func test_wrapper_resolvesFromTheEngine() {
        let dependency = Dependency<GreeterInterface>(engine: engine)

        XCTAssertEqual(dependency.wrappedValue.greet(), "hello")
    }

    /// Direct injection bypasses the engine, so a test never has to touch
    /// shared state to exercise a type that uses @Dependency.
    func test_wrapper_prefersADirectlyInjectedValue() {
        let dependency = Dependency<GreeterInterface>(wrappedValue: TurkishGreeter(), engine: engine)

        XCTAssertEqual(dependency.wrappedValue.greet(), "merhaba")
    }
}
