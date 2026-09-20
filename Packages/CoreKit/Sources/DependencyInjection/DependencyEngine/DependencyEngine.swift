import Foundation

/// Service locator keyed by interface type.
public final class DependencyEngine: @unchecked Sendable {
    public static let shared = DependencyEngine()

    private let lock = NSLock()
    private var factories: [ObjectIdentifier: () -> Any] = [:]
    private var instances: [ObjectIdentifier: Any] = [:]

    public init() {}

    /// Lazily built on first resolve, then shared.
    public func register(value: @autoclosure @escaping () -> Any, for interface: Any.Type) {
        lock.lock()
        defer { lock.unlock() }
        factories[ObjectIdentifier(interface)] = value
        instances.removeValue(forKey: ObjectIdentifier(interface))
    }

    /// New instance per resolve, for the rare dependency that mustn't be shared.
    public func registerFactory(_ factory: @escaping () -> Any, for interface: Any.Type) {
        lock.lock()
        defer { lock.unlock() }
        factories[ObjectIdentifier(interface)] = factory
        instances[ObjectIdentifier(interface)] = nil
    }

    /// `nil` when unregistered, so callers decide whether that's fatal.
    public func resolve<Value>(_ interface: Any.Type) -> Value? {
        let key = ObjectIdentifier(interface)
        lock.lock()
        defer { lock.unlock() }

        if let existing = instances[key] as? Value { return existing }
        guard let value = factories[key]?() else { return nil }
        instances[key] = value
        return value as? Value
    }

    public func unregister(_ interface: Any.Type) {
        lock.lock()
        defer { lock.unlock() }
        factories.removeValue(forKey: ObjectIdentifier(interface))
        instances.removeValue(forKey: ObjectIdentifier(interface))
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        factories.removeAll()
        instances.removeAll()
    }
}
