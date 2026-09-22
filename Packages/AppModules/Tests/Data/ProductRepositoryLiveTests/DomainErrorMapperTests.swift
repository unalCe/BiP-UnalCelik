import LoggingKitMocks
import NetworkingKit
import PersistenceKit
import ProductDomain
import XCTest
@testable import ProductRepositoryLive

final class DomainErrorMapperTests: XCTestCase {
    private let logger = SpyLogger()
    private lazy var sut = DomainErrorMapper(logger: logger)

    /// The behaviour most likely to be got wrong: S3 denies listing, so an
    /// unknown product id returns 403 rather than 404.
    func test_403_onDetail_mapsToNotFound() {
        XCTAssertEqual(sut.map(status(403), for: .detail(id: "99")), .notFound)
    }

    func test_404_onDetail_mapsToNotFound() {
        XCTAssertEqual(sut.map(status(404), for: .detail(id: "99")), .notFound)
    }

    /// The list names no product, so "product not found" would be a lie —
    /// the same code there is an access failure.
    func test_403_onList_mapsToUnknown_andIsLogged() {
        XCTAssertEqual(sut.map(status(403), for: .list), .unknown)
        XCTAssertEqual(logger.errors.count, 1)
    }

    func test_404_onList_mapsToUnknown() {
        XCTAssertEqual(sut.map(status(404), for: .list), .unknown)
    }

    func test_500_mapsToUnknown() {
        XCTAssertEqual(sut.map(status(500), for: .detail(id: "1")), .unknown)
    }

    func test_noConnection_mapsToOffline() {
        let underlying = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        XCTAssertEqual(sut.map(NetworkError.transport(underlying), for: .list), .offline)
    }

    func test_domainError_passesThroughUnchanged() {
        XCTAssertEqual(sut.map(DomainError.invalidData, for: .list), .invalidData)
    }

    /// `DomainError` cannot carry the cause, so the log has to.
    func test_persistenceError_isLoggedBeforeBecomingUnknown() {
        struct Disk: Error {}

        XCTAssertEqual(sut.map(PersistenceError.readFailed(Disk()), for: .list), .unknown)
        XCTAssertEqual(logger.errors.map(\.category), [.persistence])
    }

    private func status(_ code: Int) -> NetworkError {
        .unacceptableStatus(code: code, body: Data())
    }
}
