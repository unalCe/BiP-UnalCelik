import Foundation

public struct CacheEntry<Value: Sendable>: Sendable {
    public let value: Value
    public let fetchedAt: Date

    public init(value: Value, fetchedAt: Date) {
        self.value = value
        self.fetchedAt = fetchedAt
    }
}
