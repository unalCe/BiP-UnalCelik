import Foundation

/// A closed set, so budgets and signpost names stay exhaustive. The raw value
/// is the name shown in logs, reports and the HUD.
public enum PerformanceMetric: String, CaseIterable, Sendable, Codable {
    /// `FetchProductsUseCase.execute()`, cache or remote.
    case productsFetch = "products.fetch"
    /// List `viewDidLoad` to the first applied snapshot.
    case listTimeToContent = "list.timeToContent"

    /// `ImageLoader.image(for:)` end to end. `source` says memory or network.
    case imageLoad = "image.load"
    case imageNetwork = "image.network"
    /// Wall-clock time of the decode call itself.
    case imageDecode = "image.decode"
    /// CPU time the decoding thread actually spent in that call. The gap to
    /// `image.decode` is time off-CPU: waiting on the hardware JPEG decoder,
    /// a lock, or a core. A large gap means more threads won't help.
    case imageDecodeCPU = "image.decodeCPU"
    /// From a cell asking for an image to that image on screen: the time the
    /// user looks at a placeholder. The number prefetching should reduce.
    case imageVisibleWait = "image.visibleWait"

    /// One late frame while scrolling, in milliseconds.
    case scrollHitch = "scroll.hitch"
    /// Hitch milliseconds per second of scrolling, for one drag and its
    /// deceleration. Apple's measure: under 5 is good, over 10 is critical.
    case scrollHitchRatio = "scroll.hitchRatio"

    public var unit: String {
        switch self {
        case .scrollHitchRatio: return "ms/s"
        default: return "ms"
        }
    }
}

public enum PerformanceSeverity: Int, Sendable, Codable, Comparable {
    case ok, warning, error

    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

public struct PerformanceBudget: Sendable, Hashable, Codable {
    public let warning: Double
    public let error: Double

    public init(warning: Double, error: Double) {
        precondition(warning <= error, "a warning budget above the error budget never fires")
        self.warning = warning
        self.error = error
    }

    public func severity(of value: Double) -> PerformanceSeverity {
        if value > error { return .error }
        if value > warning { return .warning }
        return .ok
    }
}

public extension PerformanceBudget {
    /// Starting points, not gospel. Tighten them once a baseline is recorded.
    static func `default`(for metric: PerformanceMetric) -> PerformanceBudget {
        switch metric {
        case .productsFetch: return .init(warning: 1_000, error: 3_000)
        case .listTimeToContent: return .init(warning: 1_500, error: 4_000)
        case .imageLoad: return .init(warning: 500, error: 2_000)
        case .imageNetwork: return .init(warning: 400, error: 1_500)
        // Off the main thread, so it costs latency rather than frames.
        case .imageDecode: return .init(warning: 50, error: 150)
        // A downsampled thumbnail costs single-digit milliseconds on a device.
        case .imageDecodeCPU: return .init(warning: 30, error: 100)
        // ~100 ms is where a delay stops reading as instant.
        case .imageVisibleWait: return .init(warning: 100, error: 500)
        // Two frames at 60 Hz, then six.
        case .scrollHitch: return .init(warning: 33, error: 100)
        case .scrollHitchRatio: return .init(warning: 5, error: 10)
        }
    }
}
