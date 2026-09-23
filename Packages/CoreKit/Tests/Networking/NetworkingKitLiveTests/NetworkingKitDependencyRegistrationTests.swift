import XCTest
@testable import NetworkingKitLive

final class NetworkingKitDependencyRegistrationTests: XCTestCase {
    // disk sizes are above URLCache's floor, which silently raises smaller ones
    func test_session_usesTheConfiguredCacheCapacity() {
        let cache = URLCacheConfiguration(memoryCapacity: 1024 * 1024, diskCapacity: 32 * 1024 * 1024)

        let session = NetworkingKitDependencyRegistration.makeSession(cache: cache)

        XCTAssertEqual(session.configuration.urlCache?.memoryCapacity, cache.memoryCapacity)
        XCTAssertEqual(session.configuration.urlCache?.diskCapacity, cache.diskCapacity)
    }
}
