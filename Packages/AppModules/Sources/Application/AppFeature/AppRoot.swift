import DependencyEngine
import LoggingKit
import LoggingKitLive
import SwiftUI
import UIKit
import UITestSupport

@MainActor
public enum AppRoot {
    /// Call once at launch, before `makeRootViewController`.
    public static func bootstrap(engine: DependencyEngine = .shared) {
        #if DEBUG
        if let configuration = UITestLaunchConfiguration.current() {
            bootstrapForUITests(engine: engine, configuration: configuration)
            return
        }
        #endif
        AppDependencyRegistration.register(to: engine)
    }

    public static func makeRootViewController(
        engine: DependencyEngine = .shared,
        style: FlowStyle = initialStyle
    ) -> UIViewController {
        let logger: LoggerInterface = engine.resolve(LoggerInterface.self) ?? OSLogger()
        return AppShellViewController(style: style,
                                      engine: engine,
                                      logger: logger)
    }

    /// `.mvvmUIKit`, unless a UI test asked for another flow.
    public nonisolated static var initialStyle: FlowStyle {
        #if DEBUG
        if let flow = UITestLaunchConfiguration.current()?.flow, let style = FlowStyle(rawValue: flow) {
            return style
        }
        #endif
        return .mvvmUIKit
    }

    // MARK: - UI testing

    #if DEBUG
    /// Every response comes from the launching test, the store lives in memory
    /// so nothing leaks between launches, and animations are off so the test
    /// never waits on a transition.
    private static func bootstrapForUITests(
        engine: DependencyEngine,
        configuration: UITestLaunchConfiguration
    ) {
        UIView.setAnimationsEnabled(false)
        AppDependencyRegistration.register(
            to: engine,
            inMemory: true,
            httpClient: StubbedHTTPClient(stubs: configuration.stubs)
        )
    }
    #endif
}

public struct AppRootView: UIViewControllerRepresentable {
    public init() {}

    public func makeUIViewController(context: Context) -> UIViewController {
        AppRoot.bootstrap()
        return AppRoot.makeRootViewController()
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
