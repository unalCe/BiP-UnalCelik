import DependencyEngine
import Foundation
import NetworkingKit

public enum NetworkingKitDependencyRegistration: DependencyRegistration {
    public static func register(to engine: DependencyEngine) {
        engine.register(
            value: URLSessionHTTPClient(session: makeSession()) as any HTTPClientInterface,
            for: (any HTTPClientInterface).self
        )
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 16 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024
        )
        return URLSession(configuration: configuration)
    }
}
