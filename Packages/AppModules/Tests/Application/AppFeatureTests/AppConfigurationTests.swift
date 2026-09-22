import ImageCacheKitLive
import NetworkingKitLive
import XCTest
@testable import AppFeature

final class AppConfigurationTests: XCTestCase {
    /// These values are documented decisions (ARCHITECTURE "Smaller
    /// decisions"); changing one should be a deliberate edit here too.
    func test_default_isTheProductionConfiguration() {
        let megabyte = 1024 * 1024

        XCTAssertEqual(
            AppConfiguration.default,
            AppConfiguration(
                baseURL: URL(string: "https://s3-eu-west-1.amazonaws.com/developer-application-test/")!,
                productTimeToLive: 10 * 60,
                urlCache: URLCacheConfiguration(memoryCapacity: 16 * megabyte, diskCapacity: 256 * megabyte),
                imageCache: ImageCacheConfiguration(totalCostLimit: 64 * megabyte, countLimit: 100)
            )
        )
    }
}
