import Foundation

public struct FreshnessPolicy: Sendable {
    public let maxAge: TimeInterval

    public init(maxAge: TimeInterval) {
        self.maxAge = maxAge
    }

    public func isFresh<Value>(_ entry: CacheEntry<Value>, at now: Date) -> Bool {
        now.timeIntervalSince(entry.fetchedAt) < maxAge
    }
}
