import Foundation
import PersistenceKit

public actor CoreDataPersistentStore: PersistentStoreInterface {
    private var storage: [String: Data] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(inMemory: Bool = false) {
        _ = inMemory
    }

    public func read<Value: Decodable & Sendable>(_ type: Value.Type, forKey key: String) async throws -> Value? {
        guard let data = storage[key] else { return nil }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw PersistenceError.decodingFailed(error)
        }
    }

    public func write<Value: Encodable & Sendable>(_ value: Value, forKey key: String) async throws {
        do {
            storage[key] = try encoder.encode(value)
        } catch {
            throw PersistenceError.encodingFailed(error)
        }
    }

    public func remove(forKey key: String) async throws {
        storage.removeValue(forKey: key)
    }

    public func removeAll() async throws {
        storage.removeAll()
    }
}
