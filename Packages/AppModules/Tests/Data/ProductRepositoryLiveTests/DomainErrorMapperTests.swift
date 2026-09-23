import LoggingKitMocks
import NetworkingKit
import NetworkingKitMocks
import PersistenceKit
import ProductDomain
import XCTest
@testable import ProductRepositoryLive

final class DomainErrorMapperTests: XCTestCase {
    private let logger = SpyLogger()
    private lazy var sut = DomainErrorMapper(logger: logger)

    func test_refusalWithAMessage_surfacesTheBackendsOwnWords() {
        XCTAssertEqual(
            sut.map(status(403, body: HTTPFixtures.accessDenied)),
            .server(message: "Access Denied")
        )
        XCTAssertEqual(logger.errors.count, 1)
    }

    /// No status code is given a meaning of ours: without a message, a 404 is
    /// as generic as a 500.
    func test_statusWithoutAMessage_mapsToUnknown() {
        XCTAssertEqual(sut.map(status(404)), .unknown)
        XCTAssertEqual(sut.map(status(500)), .unknown)
    }

    func test_unreadableBody_mapsToUnknown() {
        XCTAssertEqual(sut.map(status(502, body: Data("<html>Bad Gateway</html>".utf8))), .unknown)
    }

    func test_noConnection_mapsToOffline() {
        let underlying = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        XCTAssertEqual(sut.map(NetworkError.transport(underlying)), .offline)
    }

    func test_domainError_passesThroughUnchanged() {
        XCTAssertEqual(sut.map(DomainError.invalidData), .invalidData)
    }

    /// `DomainError` cannot carry the cause, so the log has to.
    func test_persistenceError_isLoggedBeforeBecomingUnknown() {
        struct Disk: Error {}

        XCTAssertEqual(sut.map(PersistenceError.readFailed(Disk())), .unknown)
        XCTAssertEqual(logger.errors.map(\.category), [.persistence])
    }

    private func status(_ code: Int, body: Data = Data()) -> NetworkError {
        .unacceptableStatus(code: code, body: body)
    }
}
