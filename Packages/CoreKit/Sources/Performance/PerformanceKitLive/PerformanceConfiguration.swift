import Foundation

/// Read from launch arguments, which land in `UserDefaults`' argument domain:
///
///     -perfTracing YES|NO   signposts, budget logs, report (default: on in DEBUG)
///     -perfHUD YES          on-screen overlay, also read by the UI tests
///     -perfInjectStallMs 60 DEBUG only: stall the main thread every 10th
///                           frame, to check the hitch alarms actually fire
///
/// Set them per scheme under Run ▸ Arguments, or in `XCUIApplication.launchArguments`.
public struct PerformanceConfiguration: Sendable, Equatable {
    public static let tracingKey = "perfTracing"
    public static let hudKey = "perfHUD"
    public static let injectStallKey = "perfInjectStallMs"

    public var isTracingEnabled: Bool
    public var showsHUD: Bool
    public var injectedStallMilliseconds: Int

    public init(isTracingEnabled: Bool, showsHUD: Bool, injectedStallMilliseconds: Int = 0) {
        // The HUD reads the tracer's report, so it implies tracing.
        self.isTracingEnabled = isTracingEnabled || showsHUD
        self.showsHUD = showsHUD
        self.injectedStallMilliseconds = injectedStallMilliseconds
    }

    public static func fromLaunchArguments(_ defaults: UserDefaults = .standard) -> Self {
        #if DEBUG
        let tracingByDefault = true
        #else
        let tracingByDefault = false
        #endif

        let tracing = defaults.object(forKey: tracingKey) == nil
            ? tracingByDefault
            : defaults.bool(forKey: tracingKey)
        return Self(isTracingEnabled: tracing,
                    showsHUD: defaults.bool(forKey: hudKey),
                    injectedStallMilliseconds: defaults.integer(forKey: injectStallKey))
    }
}
