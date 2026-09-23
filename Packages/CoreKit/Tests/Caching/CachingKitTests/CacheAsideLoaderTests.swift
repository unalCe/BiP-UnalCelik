import CachingKit
import Foundation
import LoggingKitMocks
import TestSupport
import XCTest

final class CacheAsideLoaderTests: XCTestCase {
    private var loader: CacheAsideLoader!
    private var source: MockCacheSource!
    private var logger: SpyLogger!

    private let start = Date(timeIntervalSince1970: 1_000_000)
    private let maxAge: TimeInterval = 600

    override func setUp() {
        super.setUp()
        source = .init()
        reCreate(now: start)
    }

    override func tearDown() {
        loader = nil
        source = nil
        logger = nil
        super.tearDown()
    }

    /// The clock is a parameter: freshness is decided by moving time, not by sleeping.
    private func reCreate(now: Date) {
        logger = SpyLogger()
        loader = CacheAsideLoader(policy: FreshnessPolicy(maxAge: maxAge), logger: logger, now: { now })
    }

    private func load() async throws -> String {
        try await loader.load(read: source.read, fetch: source.fetch, write: source.write)
    }

    func test_freshEntry_answersWithoutFetching() async throws {
        source.stubbedReadResult = .success(CacheEntry(value: "cached", fetchedAt: start))
        reCreate(now: start.addingTimeInterval(maxAge - 1))

        let value = try await load()

        XCTAssertEqual(value, "cached")
        XCTAssertFalse(source.invokedFetch)
    }

    func test_expiredEntry_fetches() async throws {
        source.stubbedReadResult = .success(CacheEntry(value: "cached", fetchedAt: start))
        reCreate(now: start.addingTimeInterval(maxAge))

        let value = try await load()

        XCTAssertEqual(value, "remote")
        XCTAssertEqual(source.invokedFetchCount, 1)
    }

    func test_miss_fetchesAndWritesStampedWithTheClock() async throws {
        let now = start.addingTimeInterval(42)
        reCreate(now: now)

        let value = try await load()

        XCTAssertEqual(value, "remote")
        XCTAssertEqual(source.invokedFetchCount, 1)
        XCTAssertEqual(source.invokedWriteParameters?.value, "remote")
        XCTAssertEqual(source.invokedWriteParameters?.date, now)
    }

    func test_readFailure_isLoggedAndTreatedAsAMiss() async throws {
        source.stubbedReadResult = .failure(MockCacheSource.Failure())

        let value = try await load()

        XCTAssertEqual(value, "remote")
        XCTAssertTrue(logger.errors.contains { $0.message.contains("read failed") })
    }

    func test_writeFailure_isLoggedAndTheFetchedValueStillReturned() async throws {
        source.stubbedWriteError = MockCacheSource.Failure()

        let value = try await load()

        XCTAssertEqual(value, "remote")
        XCTAssertTrue(logger.errors.contains { $0.message.contains("write failed") })
    }

    func test_remoteFailure_propagatesAndNothingIsWritten() async {
        struct Offline: Error {}
        source.stubbedFetchResult = .failure(Offline())

        await XCTAssertThrowsErrorAsync(try await load()) { error in
            XCTAssertTrue(error is Offline, "got \(error)")
        }
        XCTAssertFalse(source.invokedWrite)
    }
}
