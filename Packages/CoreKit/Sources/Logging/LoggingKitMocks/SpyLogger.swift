import Foundation
import LoggingKit

/// Records instead of printing, so a test can assert that a swallowed failure
/// was at least reported.
public final class SpyLogger: LoggerInterface, @unchecked Sendable {
    public struct Entry: Sendable {
        public let level: Level
        public let category: LogCategory
        public let message: String
    }

    public enum Level: Sendable {
        case debug
        case error
    }

    private let lock = NSLock()
    private var recorded: [Entry] = []

    public init() {}

    public var entries: [Entry] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    public var errors: [Entry] { entries.filter { $0.level == .error } }

    public func debug(_ message: String, category: LogCategory) {
        record(Entry(level: .debug, category: category, message: message))
    }

    public func error(_ message: String, category: LogCategory) {
        record(Entry(level: .error, category: category, message: message))
    }

    private func record(_ entry: Entry) {
        lock.lock()
        defer { lock.unlock() }
        recorded.append(entry)
    }
}
