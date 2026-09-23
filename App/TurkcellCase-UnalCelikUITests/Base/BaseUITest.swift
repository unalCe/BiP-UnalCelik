import UITestSupport
import XCTest

/// Every UI test launches the app through here, so every run is hermetic:
/// responses come from a `LaunchScenario`, the store is in memory, animations
/// are off, and the locale is pinned so prices and copy read the same on any
/// machine.
class BaseUITest: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    override func tearDown() {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.lifetime = .deleteOnSuccess
        add(screenshot)
        app.terminate()
        super.tearDown()
    }

    /// Starts the app on `flow`, answering every request from `scenario`.
    func launch(_ scenario: LaunchScenario = .productsLoaded, flow: Flow = .mvvmUIKit) throws {
        let configuration = UITestLaunchConfiguration(flow: flow.rawValue, stubs: scenario.stubs)
        app.launchArguments = [
            UITestLaunchConfiguration.argument,
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
        ]
        app.launchEnvironment = try configuration.launchEnvironment()
        app.launch()
    }

    /// Reads as a sentence where a test only needs a screen to be in a state.
    @discardableResult
    func check<T: Page>(page: T) -> T { page }
}

/// The three presentation stacks, by `FlowStyle.rawValue`.
enum Flow: String, CaseIterable {
    case mvvmUIKit
    case mvvmSwiftUI
    case viperUIKit
}
