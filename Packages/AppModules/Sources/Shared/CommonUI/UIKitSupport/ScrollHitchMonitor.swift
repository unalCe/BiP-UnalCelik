import PerformanceKit
import UIKit

/// Watches frame pacing for one drag plus its deceleration. Feed it the
/// scroll view's delegate callbacks; it records each late frame as it happens
/// (`scroll.hitch`, so budget warnings reach the console mid-scroll) and the
/// session's hitch ratio when it settles.
///
/// A proxy for Instruments' Animation Hitches, not a replacement: a display
/// link sees the main thread being late, not a render-server miss.
@MainActor
public final class ScrollHitchMonitor {
    /// Shorter sessions are a tap-and-release; their ratio is noise.
    static let minimumSessionDuration: TimeInterval = 0.1

    private let tracer: any PerformanceTracing
    private var displayLink: CADisplayLink?
    private var accumulator = HitchAccumulator()

    public init(tracer: any PerformanceTracing) {
        self.tracer = tracer
    }

    // MARK: - UIScrollViewDelegate forwarding

    public func scrollViewWillBeginDragging() {
        // Re-grabbing a decelerating list continues the same session.
        guard displayLink == nil else { return }
        accumulator = HitchAccumulator()

        let link = CADisplayLink(target: DisplayLinkTarget(self), selector: #selector(DisplayLinkTarget.tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    public func scrollViewDidEndDragging(willDecelerate decelerate: Bool) {
        if !decelerate { endSession() }
    }

    public func scrollViewDidEndDecelerating() {
        endSession()
    }

    // MARK: - Work

    fileprivate func tick(_ link: CADisplayLink) {
        guard let lateness = accumulator.addFrame(
            timestamp: link.timestamp,
            targetTimestamp: link.targetTimestamp
        ) else { return }
        tracer.record(.scrollHitch, value: lateness * 1_000)
    }

    private func endSession() {
        guard let displayLink else { return }
        displayLink.invalidate()
        self.displayLink = nil

        guard accumulator.duration >= Self.minimumSessionDuration else { return }
        tracer.record(.scrollHitchRatio, value: accumulator.hitchRatio, attributes: [
            "hitches": "\(accumulator.hitchCount)",
            "worstMs": String(format: "%.0f", accumulator.worstHitch * 1_000),
            "durationMs": String(format: "%.0f", accumulator.duration * 1_000),
        ])
    }

    /// `CADisplayLink` retains its target; this breaks the cycle, and stops
    /// the link if the monitor goes away mid-scroll.
    private final class DisplayLinkTarget: NSObject {
        weak var monitor: ScrollHitchMonitor?

        init(_ monitor: ScrollHitchMonitor) { self.monitor = monitor }

        @objc func tick(_ link: CADisplayLink) {
            MainActor.assumeIsolated {
                guard let monitor else { return link.invalidate() }
                monitor.tick(link)
            }
        }
    }
}
