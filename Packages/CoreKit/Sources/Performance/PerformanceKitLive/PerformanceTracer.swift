import Foundation
import os
import PerformanceKit
import UIKit

/// Every sample goes three places:
/// - an `os_signpost` interval or event, visible in Instruments' Points of
///   Interest lane beside the Animation Hitches and Network tracks;
/// - the aggregator, for percentiles, the HUD and the report;
/// - the console as a warning or error, when it breaks its budget.
///
/// Uses the stateless `os_signpost` function rather than `OSSignposter`, whose
/// interval state is an object that `PerformanceInterval` cannot carry across
/// the `Sendable` interface.
public final class PerformanceTracer: PerformanceTracing, @unchecked Sendable {
    public static let subsystem = "TurkcellCase.Performance"

    /// One budget breach per metric per window reaches the console; the rest
    /// are counted into the next line. A cold scroll can breach dozens a second.
    static let logInterval: UInt64 = 1_000_000_000

    private struct State {
        var aggregator: PerformanceAggregator
        var nextID: UInt64 = 1
        var lastLogged: [PerformanceMetric: UInt64] = [:]
        var suppressed: [PerformanceMetric: Int] = [:]
    }

    private let signpostLog = OSLog(subsystem: subsystem, category: .pointsOfInterest)
    private let logger = Logger(subsystem: subsystem, category: "Budget")
    private let state: OSAllocatedUnfairLock<State>
    private var backgroundObserver: (any NSObjectProtocol)?

    public init(budgets: [PerformanceMetric: PerformanceBudget] = [:],
                reportsOnBackground: Bool = true) {
        state = OSAllocatedUnfairLock(initialState: State(aggregator: PerformanceAggregator(budgets: budgets)))

        if reportsOnBackground {
            backgroundObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.logReport()
            }
        }
    }

    deinit {
        if let backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver)
        }
    }

    // MARK: - PerformanceTracing

    public func begin(_ metric: PerformanceMetric) -> PerformanceInterval {
        let id = state.withLock { state in
            defer { state.nextID &+= 1 }
            return state.nextID
        }
        os_signpost(.begin, log: signpostLog, name: metric.signpostName, signpostID: OSSignpostID(id))
        return PerformanceInterval(
            metric: metric,
            id: id,
            startNanoseconds: DispatchTime.now().uptimeNanoseconds
        )
    }

    public func end(_ interval: PerformanceInterval,
                    outcome: PerformanceOutcome,
                    attributes: [String: String]) {
        let milliseconds = interval.elapsedMilliseconds()
        os_signpost(.end, log: signpostLog, name: interval.metric.signpostName,
                    signpostID: OSSignpostID(interval.id),
                    "%{public}s %{public}s", outcome.rawValue, attributes.logDescription)
        ingest(interval.metric, value: milliseconds, outcome: outcome, attributes: attributes)
    }

    public func record(_ metric: PerformanceMetric,
                       value: Double,
                       attributes: [String: String]) {
        os_signpost(.event, log: signpostLog, name: metric.signpostName,
                    "%.1f %{public}s", value, attributes.logDescription)
        ingest(metric, value: value, outcome: .completed, attributes: attributes)
    }

    // MARK: - Reporting

    public func report() -> PerformanceReport {
        state.withLock { $0.aggregator.report() }
    }

    public func logReport() {
        logger.notice("\(self.report().description, privacy: .public)")
    }

    // MARK: - Work

    private func ingest(_ metric: PerformanceMetric,
                        value: Double,
                        outcome: PerformanceOutcome,
                        attributes: [String: String]) {
        let now = DispatchTime.now().uptimeNanoseconds

        let breach: (PerformanceSeverity, PerformanceBudget, suppressed: Int)? = state.withLock { state in
            let severity = state.aggregator.add(metric, value: value, outcome: outcome, attributes: attributes)
            guard severity > .ok else { return nil }

            if let last = state.lastLogged[metric], now &- last < Self.logInterval {
                state.suppressed[metric, default: 0] += 1
                return nil
            }
            state.lastLogged[metric] = now
            let suppressed = state.suppressed.removeValue(forKey: metric) ?? 0
            return (severity, state.aggregator.budget(for: metric), suppressed)
        }

        guard let (severity, budget, suppressed) = breach else { return }
        log(metric, value: value, severity: severity, budget: budget,
            suppressed: suppressed, attributes: attributes)
    }

    private func log(_ metric: PerformanceMetric,
                     value: Double,
                     severity: PerformanceSeverity,
                     budget: PerformanceBudget,
                     suppressed: Int,
                     attributes: [String: String]) {
        let name = metric.rawValue
        let unit = metric.unit
        let context = attributes.isEmpty ? "" : " [\(attributes.logDescription)]"
        let more = suppressed > 0 ? " (+\(suppressed) more not shown)" : ""

        switch severity {
        case .ok:
            break
        case .warning:
            logger.warning("⚠️ \(name, privacy: .public) \(value, format: .fixed(precision: 1)) \(unit, privacy: .public) over warning budget \(budget.warning, format: .fixed(precision: 0))\(context, privacy: .public)\(more, privacy: .public)")
        case .error:
            logger.error("🛑 \(name, privacy: .public) \(value, format: .fixed(precision: 1)) \(unit, privacy: .public) over error budget \(budget.error, format: .fixed(precision: 0))\(context, privacy: .public)\(more, privacy: .public)")
        }
    }
}

private extension Dictionary where Key == String, Value == String {
    var logDescription: String {
        sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
    }
}

extension PerformanceMetric {
    /// `os_signpost` names must be `StaticString`, hence the switch.
    var signpostName: StaticString {
        switch self {
        case .productsFetch: return "products.fetch"
        case .listTimeToContent: return "list.timeToContent"
        case .imageLoad: return "image.load"
        case .imageNetwork: return "image.network"
        case .imageDecode: return "image.decode"
        case .imageDecodeCPU: return "image.decodeCPU"
        case .imageVisibleWait: return "image.visibleWait"
        case .scrollHitch: return "scroll.hitch"
        case .scrollHitchRatio: return "scroll.hitchRatio"
        }
    }
}
