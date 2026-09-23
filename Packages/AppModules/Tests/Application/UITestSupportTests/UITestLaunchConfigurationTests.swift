import XCTest

@testable import UITestSupport

final class UITestLaunchConfigurationTests: XCTestCase {
    private var configuration: UITestLaunchConfiguration!

    override func setUp() {
        super.setUp()
        configuration = UITestLaunchConfiguration(
            flow: "viperUIKit",
            stubs: [HTTPStub(path: "cart/list", replies: [.offline, .response(status: 200, body: Data("{}".utf8))])]
        )
    }

    override func tearDown() {
        configuration = nil
        super.tearDown()
    }

    /// What the test encodes is exactly what the app decodes.
    func test_launchEnvironment_roundTrips() throws {
        let environment = try configuration.launchEnvironment()

        let decoded = UITestLaunchConfiguration.current(
            arguments: [UITestLaunchConfiguration.argument],
            environment: environment
        )

        XCTAssertEqual(decoded, configuration)
    }

    /// A normal launch must never pick up a stale environment.
    func test_withoutTheArgument_isANormalLaunch() throws {
        let environment = try configuration.launchEnvironment()

        XCTAssertNil(UITestLaunchConfiguration.current(arguments: [], environment: environment))
    }

    func test_withoutTheEnvironment_isANormalLaunch() {
        XCTAssertNil(UITestLaunchConfiguration.current(arguments: [UITestLaunchConfiguration.argument], environment: [:]))
    }
}
