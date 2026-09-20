import Foundation

/// Keyed `Codable` storage.
public protocol PersistentStoreInterface: Sendable {
    func read<Value: Decodable & Sendable>(_ type: Value.Type, forKey key: String) async throws -> Value?
    func write<Value: Encodable & Sendable>(_ value: Value, forKey key: String) async throws
    func remove(forKey key: String) async throws
    func removeAll() async throws
}

public enum PersistenceError: Error, Sendable {
    case storeUnavailable(any Error)
    case encodingFailed(any Error)
    case decodingFailed(any Error)
}
