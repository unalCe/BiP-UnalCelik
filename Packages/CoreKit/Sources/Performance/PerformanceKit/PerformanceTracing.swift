import Foundation

/// Where timing and smoothness samples go. Called from cell configuration and
/// the image pipeline, so conformers must stay cheap. `NoopPerformanceTracer`
/// is the default everywhere, so instrumented code never needs a nil check.
public protocol PerformanceTracing: Sendable {
    /// Starts a timed interval. Every call must be paired with `end`.
    func begin(_ metric: PerformanceMetric) -> PerformanceInterval

    func end(_ interval: PerformanceInterval,
             outcome: PerformanceOutcome,
             attributes: [String: String])

    /// A sample measured elsewhere, such as one scroll session's hitch ratio.
    func record(_ metric: PerformanceMetric,
                value: Double,
                attributes: [String: String])
}

public extension PerformanceTracing {
    func end(_ interval: PerformanceInterval,
             outcome: PerformanceOutcome = .completed,
             attributes: [String: String] = [:]) {
        end(interval, outcome: outcome, attributes: attributes)
    }

    func record(_ metric: PerformanceMetric, value: Double) {
        record(metric, value: value, attributes: [:])
    }

    /// Ends the interval as `.failed`, or `.cancelled` when the task was, and
    /// rethrows.
    func measure<T>(
        _ metric: PerformanceMetric,
        _ work: () async throws -> T
    ) async rethrows -> T {
        let interval = begin(metric)
        do {
            let value = try await work()
            end(interval)
            return value
        } catch {
            end(interval, outcome: Task.isCancelled ? .cancelled : .failed)
            throw error
        }
    }
}

/// Only `.completed` intervals feed the percentiles. The rest are counted,
/// because a cancelled load is wasted work worth seeing, not a fast one.
public enum PerformanceOutcome: String, Sendable, Codable {
    case completed, cancelled, failed
}

/// A started interval. A value type, so it can cross actors freely.
public struct PerformanceInterval: Sendable, Hashable {
    public let metric: PerformanceMetric
    public let id: UInt64
    public let startNanoseconds: UInt64

    public init(metric: PerformanceMetric, id: UInt64, startNanoseconds: UInt64) {
        self.metric = metric
        self.id = id
        self.startNanoseconds = startNanoseconds
    }

    public func elapsedMilliseconds(
        at now: UInt64 = DispatchTime.now().uptimeNanoseconds
    ) -> Double {
        Double(now &- startNanoseconds) / 1_000_000
    }
}

public struct NoopPerformanceTracer: PerformanceTracing {
    public init() {}

    public func begin(_ metric: PerformanceMetric) -> PerformanceInterval {
        PerformanceInterval(metric: metric, id: 0, startNanoseconds: 0)
    }

    public func end(_ interval: PerformanceInterval,
                    outcome: PerformanceOutcome,
                    attributes: [String: String]) {}

    public func record(_ metric: PerformanceMetric,
                       value: Double,
                       attributes: [String: String]) {}
}
