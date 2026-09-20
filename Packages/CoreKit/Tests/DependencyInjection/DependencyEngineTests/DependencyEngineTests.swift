import XCTest
@testable import DependencyEngine

private protocol GreeterInterface: Sendable { func greet() -> String }
private struct EnglishGreeter: GreeterInterface { func greet() -> String { "hello" } }
private struct TurkishGreeter: GreeterInterface { func greet() -> String { "merhaba" } }

final class DependencyEngineTests: XCTestCase {
    func test_resolve_returnsRegisteredValue() {
        let engine = DependencyEngine()
        engine.register(value: EnglishGreeter() as any GreeterInterface, for: (any GreeterInterface).self)

        let resolved: (any GreeterInterface)? = engine.resolve((any GreeterInterface).self)

        XCTAssertEqual(resolved?.greet(), "hello")
    }

    func test_resolve_returnsNilWhenNothingRegistered() {
        let engine = DependencyEngine()
        let resolved: (any GreeterInterface)? = engine.resolve((any GreeterInterface).self)
        XCTAssertNil(resolved)
    }

    /// The behaviour the architecture toggle relies on: re-registering the same
    /// interface swaps the implementation for every later resolution.
    func test_reregistering_replacesImplementation() {
        let engine = DependencyEngine()
        engine.register(value: EnglishGreeter() as any GreeterInterface, for: (any GreeterInterface).self)
        engine.register(value: TurkishGreeter() as any GreeterInterface, for: (any GreeterInterface).self)

        let resolved: (any GreeterInterface)? = engine.resolve((any GreeterInterface).self)

        XCTAssertEqual(resolved?.greet(), "merhaba")
    }

    func test_unregister_removesImplementation() {
        let engine = DependencyEngine()
        engine.register(value: EnglishGreeter() as any GreeterInterface, for: (any GreeterInterface).self)
        engine.unregister((any GreeterInterface).self)

        let resolved: (any GreeterInterface)? = engine.resolve((any GreeterInterface).self)

        XCTAssertNil(resolved)
    }

    func test_registration_isLazy() {
        let engine = DependencyEngine()
        var built = 0
        engine.register(
            value: { built += 1; return EnglishGreeter() }() as any GreeterInterface,
            for: (any GreeterInterface).self
        )

        XCTAssertEqual(built, 0, "registering must not construct the value")

        let _: (any GreeterInterface)? = engine.resolve((any GreeterInterface).self)
        XCTAssertEqual(built, 1)
    }
}

final class DependencyPropertyWrapperTests: XCTestCase {
    func test_wrapper_resolvesFromEngine() {
        let engine = DependencyEngine()
        engine.register(value: EnglishGreeter() as any GreeterInterface, for: (any GreeterInterface).self)

        let dependency = Dependency<any GreeterInterface>(engine: engine)

        XCTAssertEqual(dependency.wrappedValue.greet(), "hello")
    }

    /// Direct injection bypasses the engine, so a test never has to touch
    /// shared state to exercise a type that uses @Dependency.
    func test_wrapper_prefersDirectlyInjectedValue() {
        let engine = DependencyEngine()
        engine.register(value: EnglishGreeter() as any GreeterInterface, for: (any GreeterInterface).self)

        let dependency = Dependency<any GreeterInterface>(
            wrappedValue: TurkishGreeter(),
            engine: engine
        )

        XCTAssertEqual(dependency.wrappedValue.greet(), "merhaba")
    }
}
