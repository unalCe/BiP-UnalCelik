import Foundation
import LoggingKit
import os

public struct OSLogger: LoggerInterface {
    private let subsystem: String

    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "CoreKit") {
        self.subsystem = subsystem
    }

    public func debug(_ message: String, category: LogCategory) {
        logger(for: category).debug("\(message, privacy: .public)")
    }

    public func error(_ message: String, category: LogCategory) {
        logger(for: category).error("\(message, privacy: .public)")
    }

    // built per call: `Logger` is a wrapper around a cached `os_log_t`, and
    // these calls only happen on paths that already failed
    private func logger(for category: LogCategory) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }
}
