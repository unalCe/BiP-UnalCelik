import DependencyEngine
import PerformanceKit

public enum PerformanceKitDependencyRegistration: DependencyRegistration {
    public static func register(to engine: DependencyEngine) {
        register(.fromLaunchArguments(), to: engine)
    }

    /// Registers `PerformanceTracer` under its concrete type too, when enabled,
    /// for the HUD. Nothing else should reach past the interface.
    public static func register(_ configuration: PerformanceConfiguration,
                                to engine: DependencyEngine) {
        guard configuration.isTracingEnabled else {
            engine.register(value: NoopPerformanceTracer() as any PerformanceTracing,
                            for: (any PerformanceTracing).self)
            engine.unregister(PerformanceTracer.self)
            return
        }

        let tracer = PerformanceTracer()
        engine.register(value: tracer as any PerformanceTracing, for: (any PerformanceTracing).self)
        engine.register(value: tracer, for: PerformanceTracer.self)
    }
}
