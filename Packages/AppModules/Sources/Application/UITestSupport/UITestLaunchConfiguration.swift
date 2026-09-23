import Foundation

/// The contract between a UI test and the app it launches.
///
/// XCUITest runs in another process, so it cannot inject a Swift double. The
/// test encodes one of these into the launch environment instead; the app
/// decodes it at start-up and builds its graph from it. The app never contains
/// fixture data — every response arrives from the test.
public struct UITestLaunchConfiguration: Codable, Equatable, Sendable {
    public static let argument = "-ui-testing"
    public static let environmentKey = "UITEST_LAUNCH_CONFIGURATION"

    /// `FlowStyle.rawValue` of the flow to start with; `nil` keeps the default.
    public var flow: String?
    public var stubs: [HTTPStub]

    public init(flow: String? = nil, stubs: [HTTPStub]) {
        self.flow = flow
        self.stubs = stubs
    }

    // MARK: - Transport

    /// What the test sets on `XCUIApplication.launchEnvironment`.
    public func launchEnvironment() throws -> [String: String] {
        let data = try JSONEncoder().encode(self)
        return [Self.environmentKey: String(decoding: data, as: UTF8.self)]
    }

    /// The configuration the app was launched with, or `nil` for a normal launch.
    public static func current(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> UITestLaunchConfiguration? {
        guard arguments.contains(argument),
              let json = environment[environmentKey]
        else { return nil }
        return try? JSONDecoder().decode(UITestLaunchConfiguration.self, from: Data(json.utf8))
    }
}

/// Canned answers for every request whose path ends with `path`.
public struct HTTPStub: Codable, Equatable, Sendable {
    public enum Reply: Codable, Equatable, Sendable {
        case response(status: Int, body: Data)
        case offline
    }

    public let path: String
    /// Answered in order; the last one repeats. `[.offline, .response(…)]`
    /// is a request that fails once and succeeds on retry.
    public let replies: [Reply]

    public init(path: String, replies: [Reply]) {
        self.path = path
        self.replies = replies
    }
}
