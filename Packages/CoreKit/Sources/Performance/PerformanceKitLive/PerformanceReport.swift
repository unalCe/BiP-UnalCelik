import Foundation
import PerformanceKit

/// A point-in-time summary. Codable so a run can be saved and diffed against
/// another — prefetch off against prefetch on, say.
public struct PerformanceReport: Codable, Sendable, Equatable {
    public struct Entry: Codable, Sendable, Equatable {
        public let unit: String
        /// Completed samples, the ones the percentiles are taken over.
        public let count: Int
        public let last: Double?
        public let p50: Double?
        public let p90: Double?
        public let max: Double?
        /// Every sample, by outcome, cancelled and failed included.
        public let outcomes: [String: Int]
        /// e.g. `source=memory: 120, source=network: 40`, the cache hit rate.
        public let tallies: [String: Int]
        public let warnings: Int
        public let errors: Int
        public let budget: PerformanceBudget
    }

    /// Keyed by `PerformanceMetric.rawValue`, so the JSON reads without the enum.
    public let entries: [String: Entry]

    public subscript(metric: PerformanceMetric) -> Entry? { entries[metric.rawValue] }

    public func jsonString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(self) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }
}

extension PerformanceReport: CustomStringConvertible {
    public var description: String {
        guard !entries.isEmpty else { return "No performance samples yet." }

        let rows = PerformanceMetric.allCases.compactMap { metric -> String? in
            guard let entry = self[metric] else { return nil }
            var row = metric.rawValue.padding(toLength: 20, withPad: " ", startingAt: 0)
            row += " n=\(entry.count)"
            row += " p50=\(Self.format(entry.p50)) p90=\(Self.format(entry.p90))"
            row += " max=\(Self.format(entry.max)) \(entry.unit)"
            if entry.warnings + entry.errors > 0 {
                row += "  ⚠️\(entry.warnings) 🛑\(entry.errors)"
            }
            let extras = entry.outcomes
                .filter { $0.key != PerformanceOutcome.completed.rawValue }
                .merging(entry.tallies) { lhs, _ in lhs }
            if !extras.isEmpty {
                row += "  " + extras.sorted { $0.key < $1.key }
                    .map { "\($0.key):\($0.value)" }
                    .joined(separator: " ")
            }
            return row
        }
        return (["── Performance report ──"] + rows).joined(separator: "\n")
    }

    static func format(_ value: Double?) -> String {
        guard let value else { return "-" }
        return String(format: "%.1f", value)
    }
}
