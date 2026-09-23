import DependencyEngine
import LoggingKit
import LoggingKitLive
import SwiftUI
import UIKit

@MainActor
public enum AppRoot {
    /// Call once at launch, before `makeRootViewController`.
    public static func bootstrap(engine: DependencyEngine = .shared) {
        AppDependencyRegistration.register(to: engine)
    }

    public static func makeRootViewController(
        engine: DependencyEngine = .shared,
        style: FlowStyle = .mvvmUIKit
    ) -> UIViewController {
        let logger: LoggerInterface = engine.resolve(LoggerInterface.self) ?? OSLogger()
        return AppShellViewController(style: style,
                                      engine: engine,
                                      logger: logger)
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
