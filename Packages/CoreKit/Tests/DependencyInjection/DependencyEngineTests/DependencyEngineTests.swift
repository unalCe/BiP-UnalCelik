import XCTest

@testable import DependencyEngine

final class DependencyEngineTests: XCTestCase {
    private var engine: DependencyEngine!

    override func setUp() {
        super.setUp()
        engine = DependencyEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    private func resolveGreeter() -> GreeterInterface? {
        engine.resolve(GreeterInterface.self)
    }

    func test_resolve_returnsTheRegisteredValue() {
        engine.register(value: EnglishGreeter() as GreeterInterface, for: GreeterInterface.self)

        XCTAssertEqual(resolveGreeter()?.greet(), "hello")
    }

    func test_resolve_withNothingRegistered_isNil() {
        XCTAssertNil(resolveGreeter())
    }

    /// The behaviour the architecture toggle relies on: re-registering the same
    /// interface swaps the implementation for every later resolution.
    func test_reregistering_replacesTheImplementation() {
        engine.register(value: EnglishGreeter() as GreeterInterface, for: GreeterInterface.self)
        _ = resolveGreeter()

        engine.register(value: TurkishGreeter() as GreeterInterface, for: GreeterInterface.self)

        XCTAssertEqual(resolveGreeter()?.greet(), "merhaba")
    }

    func test_unregister_removesTheImplementation() {
        engine.register(value: EnglishGreeter() as GreeterInterface, for: GreeterInterface.self)

        engine.unregister(GreeterInterface.self)

        XCTAssertNil(resolveGreeter())
    }

    func test_register_isLazyAndBuildsOnce() {
        var buildCount = 0
        engine.register(
            value: { buildCount += 1; return EnglishGreeter() }() as GreeterInterface,
            for: GreeterInterface.self
        )
        XCTAssertEqual(buildCount, 0, "registering must not construct the value")

        _ = resolveGreeter()
        _ = resolveGreeter()

        XCTAssertEqual(buildCount, 1, "a registration is a shared instance")
    }

    func test_registerFactory_buildsOnEveryResolve() {
        var buildCount = 0
        engine.registerFactory({ buildCount += 1; return EnglishGreeter() as GreeterInterface },
                               for: GreeterInterface.self)

        _ = resolveGreeter()
        _ = resolveGreeter()

        XCTAssertEqual(buildCount, 2)
    }
}
