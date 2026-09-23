import Foundation
import LoggingKit

/// Fresh cache, else fetch and write back. Cache failures are logged, never thrown.
public struct CacheAsideLoader: Sendable {
    private let policy: FreshnessPolicy
    private let logger: LoggerInterface
    private let now: @Sendable () -> Date

    // MARK: - Lifecycle

    public init(policy: FreshnessPolicy,
                logger: LoggerInterface,
                now: @escaping @Sendable () -> Date = { Date() }) {
        self.policy = policy
        self.logger = logger
        self.now = now
    }

    // MARK: - Public Funcs

    public func load<Value: Sendable>(
        read: () async throws -> CacheEntry<Value>?,
        fetch: () async throws -> Value,
        write: (Value, Date) async throws -> Void
    ) async throws -> Value {
        if let entry = await readOrMiss(read), policy.isFresh(entry, at: now()) {
            return entry.value
        }

        let fresh = try await fetch()
        do {
            try await write(fresh, now())
        } catch {
            logger.error("cache write failed, response returned uncached: \(error)", category: .persistence)
        }
        return fresh
    }

    // MARK: - Private Funcs

    private func readOrMiss<Value>(
        _ read: () async throws -> CacheEntry<Value>?
    ) async -> CacheEntry<Value>? {
        do {
            return try await read()
        } catch {
            logger.error("cache read failed, treated as a miss: \(error)", category: .persistence)
            return nil
        }
    }
}
