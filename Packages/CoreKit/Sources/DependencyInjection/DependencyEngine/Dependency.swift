import Foundation

/// Resolves from the engine on first access. A missing registration is a
/// wiring bug, so it traps rather than failing quietly.
@propertyWrapper
public final class Dependency<Value> {
    private var resolved: Value?
    private let engine: DependencyEngine

    public init(engine: DependencyEngine = .shared) {
        self.engine = engine
    }

    /// Bypasses the engine — for tests, and for call sites that already have it.
    public init(wrappedValue: Value, engine: DependencyEngine = .shared) {
        self.resolved = wrappedValue
        self.engine = engine
    }

    public var wrappedValue: Value {
        get {
            if let resolved { return resolved }
            guard let value: Value = engine.resolve(Value.self) else {
                fatalError(
                    """
                    No implementation registered for \(Value.self).
                    Register it in AppDependencyRegistration, or inject it \
                    directly in tests.
                    """
                )
            }
            resolved = value
            return value
        }
        set { resolved = newValue }
    }
}
