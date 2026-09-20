import DependencyEngine
import NetworkingKit

public enum NetworkingKitDependencyRegistration: DependencyRegistration {
    public static func register(to engine: DependencyEngine) {
        engine.register(
            value: URLSessionHTTPClient() as any HTTPClientInterface,
            for: (any HTTPClientInterface).self
        )
    }
}
