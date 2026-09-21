import Foundation

/// Frame-pacing arithmetic for one scroll session, kept free of `CADisplayLink`
/// so it can be tested with plain numbers.
///
/// Each display-link tick reports the frame just shown (`timestamp`) and when
/// the next one is due (`targetTimestamp`). On time, a tick's `timestamp`
/// equals the previous tick's `targetTimestamp`; any excess is how late the
/// frame was, i.e. how long the main thread blocked the render loop.
public struct HitchAccumulator: Sendable, Equatable {
    /// Vsync timestamps are exact multiples of the frame interval, so anything
    /// under a millisecond is clock jitter, not a missed frame.
    public static let tolerance: TimeInterval = 0.001

    public private(set) var frameCount = 0
    public private(set) var hitchCount = 0
    public private(set) var hitchTime: TimeInterval = 0
    public private(set) var worstHitch: TimeInterval = 0

    private var firstTimestamp: TimeInterval?
    private var lastTimestamp: TimeInterval?
    private var expectedTimestamp: TimeInterval?

    public init() {}

    /// - Returns: how late this frame was, when it hitched.
    @discardableResult
    public mutating func addFrame(timestamp: TimeInterval,
                                  targetTimestamp: TimeInterval) -> TimeInterval? {
        defer {
            expectedTimestamp = targetTimestamp
            lastTimestamp = timestamp
        }
        guard let expected = expectedTimestamp else {
            firstTimestamp = timestamp
            return nil
        }

        frameCount += 1
        let lateness = timestamp - expected
        guard lateness > Self.tolerance else { return nil }

        hitchCount += 1
        hitchTime += lateness
        worstHitch = max(worstHitch, lateness)
        return lateness
    }

    public var duration: TimeInterval {
        guard let firstTimestamp, let lastTimestamp else { return 0 }
        return lastTimestamp - firstTimestamp
    }

    /// Hitch milliseconds per second of scrolling.
    public var hitchRatio: Double {
        duration > 0 ? (hitchTime * 1_000) / duration : 0
    }
}
