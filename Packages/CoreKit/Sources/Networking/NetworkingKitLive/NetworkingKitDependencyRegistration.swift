import DependencyEngine
import Foundation
import NetworkingKit

public struct URLCacheConfiguration: Equatable, Sendable {
    public var memoryCapacity: Int
    public var diskCapacity: Int

    public init(memoryCapacity: Int = 16 * 1024 * 1024, diskCapacity: Int = 256 * 1024 * 1024) {
        self.memoryCapacity = memoryCapacity
        self.diskCapacity = diskCapacity
    }
}

public enum NetworkingKitDependencyRegistration: DependencyRegistration {
    public static func register(to engine: DependencyEngine) {
        register(to: engine, cache: URLCacheConfiguration())
    }

    public static func register(to engine: DependencyEngine, cache: URLCacheConfiguration) {
        engine.register(
            value: URLSessionHTTPClient(session: makeSession(cache: cache)) as any HTTPClientInterface,
            for: (any HTTPClientInterface).self
        )
    }

    static func makeSession(cache: URLCacheConfiguration) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: cache.memoryCapacity,
            diskCapacity: cache.diskCapacity
        )
        return URLSession(configuration: configuration)
    }
}
