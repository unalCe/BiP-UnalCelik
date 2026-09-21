import DependencyEngine
import PerformanceKitLive
import SwiftUI
import UIKit

@MainActor
public enum AppRoot {
    /// Call once at launch, before `makeRootViewController`.
    public static func bootstrap(engine: DependencyEngine = .shared) {
        AppDependencyRegistration.register(to: engine)
        FlowRegistration.register(.mvvmUIKit, to: engine)

        let performance = PerformanceConfiguration.fromLaunchArguments()
        if performance.showsHUD,
           let tracer: PerformanceTracer = engine.resolve(PerformanceTracer.self) {
            PerformanceHUD.install(tracer: tracer)
        }
        MainThreadStallInjector.start(milliseconds: performance.injectedStallMilliseconds)
    }

    public static func makeRootViewController(engine: DependencyEngine = .shared) -> UIViewController {
        UINavigationController(rootViewController: FlowPickerViewController(engine: engine))
    }
}

public struct AppRootView: UIViewControllerRepresentable {
    public init() {}

    public func makeUIViewController(context: Context) -> UIViewController {
        AppRoot.bootstrap()
        return AppRoot.makeRootViewController()
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
