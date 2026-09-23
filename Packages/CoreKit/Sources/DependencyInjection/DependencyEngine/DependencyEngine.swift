import Foundation

/// Service locator keyed by interface type.
public final class DependencyEngine: @unchecked Sendable {
    public static let shared = DependencyEngine()

    private let lock = NSLock()
    private var factories: [ObjectIdentifier: () -> Any] = [:]
    private var instances: [ObjectIdentifier: Any] = [:]
    /// Interfaces registered with `registerFactory`, whose values are never cached.
    private var unshared: Set<ObjectIdentifier> = []

    // MARK: - Lifecycle

    public init() {}

    /// Lazily built on first resolve, then shared.
    // MARK: - Public Funcs

    public func register(value: @autoclosure @escaping () -> Any, for interface: Any.Type) {
        lock.lock()
        defer { lock.unlock() }
        factories[ObjectIdentifier(interface)] = value
        instances.removeValue(forKey: ObjectIdentifier(interface))
        unshared.remove(ObjectIdentifier(interface))
    }

    /// New instance per resolve, for the rare dependency that mustn't be shared.
    public func registerFactory(_ factory: @escaping () -> Any, for interface: Any.Type) {
        lock.lock()
        defer { lock.unlock() }
        factories[ObjectIdentifier(interface)] = factory
        instances[ObjectIdentifier(interface)] = nil
        unshared.insert(ObjectIdentifier(interface))
    }

    /// `nil` when unregistered, so callers decide whether that's fatal.
    public func resolve<Value>(_ interface: Any.Type) -> Value? {
        let key = ObjectIdentifier(interface)
        lock.lock()
        defer { lock.unlock() }

        if let existing = instances[key] as? Value { return existing }
        guard let value = factories[key]?() else { return nil }
        if !unshared.contains(key) { instances[key] = value }
        return value as? Value
    }

    public func unregister(_ interface: Any.Type) {
        lock.lock()
        defer { lock.unlock() }
        factories.removeValue(forKey: ObjectIdentifier(interface))
        instances.removeValue(forKey: ObjectIdentifier(interface))
        unshared.remove(ObjectIdentifier(interface))
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        factories.removeAll()
        instances.removeAll()
        unshared.removeAll()
    }
}
