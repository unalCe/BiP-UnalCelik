import Foundation
import PersistenceKit

public actor MockPersistentStore: PersistentStoreInterface {
    private var storage: [String: Data] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public private(set) var readKeys: [String] = []
    public private(set) var writtenKeys: [String] = []

    public var failure: PersistenceError?

    public init(failure: PersistenceError? = nil) {
        self.failure = failure
    }

    public func setFailure(_ failure: PersistenceError?) {
        self.failure = failure
    }

    public func read<Value: Decodable & Sendable>(_ type: Value.Type, forKey key: String) async throws -> Value? {
        readKeys.append(key)
        if let failure { throw failure }
        guard let data = storage[key] else { return nil }
        return try decoder.decode(type, from: data)
    }

    public func write<Value: Encodable & Sendable>(_ value: Value, forKey key: String) async throws {
        writtenKeys.append(key)
        if let failure { throw failure }
        storage[key] = try encoder.encode(value)
    }

    public func remove(forKey key: String) async throws {
        storage.removeValue(forKey: key)
    }

    public func removeAll() async throws {
        storage.removeAll()
    }
}
