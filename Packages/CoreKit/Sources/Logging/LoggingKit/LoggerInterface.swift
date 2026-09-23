import Foundation

/// A diagnostic seam, not a logging framework: two levels and a category, so
/// an error a layer decides to absorb still leaves a trace somebody can read.
public protocol LoggerInterface: Sendable {
    func debug(_ message: String, category: LogCategory)
    func error(_ message: String, category: LogCategory)
}

/// Named rather than a bare `String` so a typo is a compile error and a
/// subsystem's traffic can be filtered in one place.
public struct LogCategory: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension LogCategory {
    static let networking = LogCategory(rawValue: "networking")
    static let persistence = LogCategory(rawValue: "persistence")
    static let composition = LogCategory(rawValue: "composition")
}
