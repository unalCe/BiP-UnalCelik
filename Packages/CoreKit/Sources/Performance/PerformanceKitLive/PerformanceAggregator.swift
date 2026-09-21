import Foundation
import PerformanceKit

/// Pure bookkeeping behind `PerformanceTracer`. Not thread-safe on its own;
/// the tracer owns the lock.
struct PerformanceAggregator {
    /// Recent samples only, so a long session neither grows without bound nor
    /// lets a cold start dominate the percentiles forever.
    static let sampleLimit = 1_000

    /// Attribute keys worth tallying. Anything else, like a count, would mint
    /// a new bucket per value.
    static let talliedKeys: Set<String> = ["source"]

    private struct Series {
        var values: [Double] = []
        var last: Double?
        var outcomes: [PerformanceOutcome: Int] = [:]
        var tallies: [String: Int] = [:]
        var warnings = 0
        var errors = 0
    }

    private var series: [PerformanceMetric: Series] = [:]
    private let budgets: [PerformanceMetric: PerformanceBudget]

    init(budgets: [PerformanceMetric: PerformanceBudget]) {
        self.budgets = budgets
    }

    func budget(for metric: PerformanceMetric) -> PerformanceBudget {
        budgets[metric] ?? .default(for: metric)
    }

    /// - Returns: how the sample sits against its budget. Only completed
    ///   samples are judged; a cancelled load being slow means nothing.
    @discardableResult
    mutating func add(_ metric: PerformanceMetric,
                      value: Double,
                      outcome: PerformanceOutcome,
                      attributes: [String: String]) -> PerformanceSeverity {
        var entry = series[metric, default: Series()]
        defer { series[metric] = entry }

        entry.outcomes[outcome, default: 0] += 1
        for (key, tag) in attributes where Self.talliedKeys.contains(key) {
            entry.tallies["\(key)=\(tag)", default: 0] += 1
        }
        guard outcome == .completed else { return .ok }

        entry.values.append(value)
        if entry.values.count > Self.sampleLimit {
            entry.values.removeFirst(entry.values.count - Self.sampleLimit)
        }
        entry.last = value

        let severity = budget(for: metric).severity(of: value)
        switch severity {
        case .ok: break
        case .warning: entry.warnings += 1
        case .error: entry.errors += 1
        }
        return severity
    }

    func report() -> PerformanceReport {
        var entries: [String: PerformanceReport.Entry] = [:]
        for (metric, entry) in series {
            let sorted = entry.values.sorted()
            entries[metric.rawValue] = PerformanceReport.Entry(
                unit: metric.unit,
                count: sorted.count,
                last: entry.last,
                p50: Self.percentile(0.5, of: sorted),
                p90: Self.percentile(0.9, of: sorted),
                max: sorted.last,
                outcomes: Dictionary(uniqueKeysWithValues: entry.outcomes.map { ($0.key.rawValue, $0.value) }),
                tallies: entry.tallies,
                warnings: entry.warnings,
                errors: entry.errors,
                budget: budget(for: metric)
            )
        }
        return PerformanceReport(entries: entries)
    }

    /// Nearest-rank, so the result is always an observed sample.
    static func percentile(_ fraction: Double, of sorted: [Double]) -> Double? {
        guard !sorted.isEmpty else { return nil }
        let rank = Int((fraction * Double(sorted.count)).rounded(.up))
        return sorted[min(max(rank, 1), sorted.count) - 1]
    }
}
