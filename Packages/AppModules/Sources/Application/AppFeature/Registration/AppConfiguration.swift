import Foundation
import ImageCacheKitLive
import NetworkingKitLive

/// The runtime values this app chooses, in one place. CoreKit takes its share
/// as its own configuration types and never sees this one.
public struct AppConfiguration: Equatable, Sendable {
    public var baseURL: URL
    public var productTimeToLive: TimeInterval
    public var urlCache: URLCacheConfiguration
    public var imageCache: ImageCacheConfiguration

    public init(
        baseURL: URL,
        productTimeToLive: TimeInterval,
        urlCache: URLCacheConfiguration,
        imageCache: ImageCacheConfiguration
    ) {
        self.baseURL = baseURL
        self.productTimeToLive = productTimeToLive
        self.urlCache = urlCache
        self.imageCache = imageCache
    }

    public static let `default` = AppConfiguration(
        baseURL: productionBaseURL,
        productTimeToLive: 10 * 60,
        urlCache: URLCacheConfiguration(memoryCapacity: 16 * 1024 * 1024, diskCapacity: 256 * 1024 * 1024),
        imageCache: ImageCacheConfiguration(totalCostLimit: 64 * 1024 * 1024, countLimit: 100)
    )

    private static let productionBaseURL: URL = {
        guard let url = URL(string: "https://s3-eu-west-1.amazonaws.com/developer-application-test/") else {
            preconditionFailure("AppConfiguration: the production base URL literal is not a URL")
        }
        return url
    }()
}
