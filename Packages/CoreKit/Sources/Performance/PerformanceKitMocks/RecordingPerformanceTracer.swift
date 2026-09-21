import Foundation
import PerformanceKit

/// Keeps every sample, so a test can assert what was measured and how it
/// ended. Durations are real wall-clock time; assert on metrics and outcomes,
/// not on values.
public final class RecordingPerformanceTracer: PerformanceTracing, @unchecked Sendable {
    public struct Sample: Equatable, Sendable {
        public let metric: PerformanceMetric
        public let value: Double
        public let outcome: PerformanceOutcome
        public let attributes: [String: String]
    }

    private let lock = NSLock()
    private var recorded: [Sample] = []
    private var open: Set<PerformanceInterval> = []
    private var nextID: UInt64 = 1

    public var samples: [Sample] { lock.withLock { recorded } }
    /// Begun and never ended — a leak in the instrumentation.
    public var openIntervals: [PerformanceInterval] { lock.withLock { Array(open) } }

    public init() {}

    public func samples(for metric: PerformanceMetric) -> [Sample] {
        samples.filter { $0.metric == metric }
    }

    public func begin(_ metric: PerformanceMetric) -> PerformanceInterval {
        lock.withLock {
            defer { nextID += 1 }
            let interval = PerformanceInterval(
                metric: metric,
                id: nextID,
                startNanoseconds: DispatchTime.now().uptimeNanoseconds
            )
            open.insert(interval)
            return interval
        }
    }

    public func end(_ interval: PerformanceInterval,
                    outcome: PerformanceOutcome,
                    attributes: [String: String]) {
        let sample = Sample(metric: interval.metric,
                            value: interval.elapsedMilliseconds(),
                            outcome: outcome,
                            attributes: attributes)
        lock.withLock {
            open.remove(interval)
            recorded.append(sample)
        }
    }

    public func record(_ metric: PerformanceMetric,
                       value: Double,
                       attributes: [String: String]) {
        let sample = Sample(metric: metric, value: value, outcome: .completed, attributes: attributes)
        lock.withLock { recorded.append(sample) }
    }
}
