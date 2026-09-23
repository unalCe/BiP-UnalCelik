import CachingKit
import Foundation
import LoggingKitMocks
import XCTest

final class CacheAsideLoaderTests: XCTestCase {
    private let logger = SpyLogger()
    private let start = Date(timeIntervalSince1970: 1_000_000)
    private let maxAge: TimeInterval = 600

    func test_freshEntry_answersWithoutFetching() async throws {
        let sut = makeSUT(now: start.addingTimeInterval(maxAge - 1))
        let source = Source(entry: CacheEntry(value: "cached", fetchedAt: start))

        let value = try await load(sut, from: source)

        XCTAssertEqual(value, "cached")
        XCTAssertEqual(source.fetches, 0)
    }

    func test_miss_fetchesAndWritesStampedWithTheClock() async throws {
        let now = start.addingTimeInterval(42)
        let sut = makeSUT(now: now)
        let source = Source(entry: nil)

        let value = try await load(sut, from: source)

        XCTAssertEqual(value, "remote")
        XCTAssertEqual(source.fetches, 1)
        XCTAssertEqual(source.writes.map(\.date), [now])
    }

    func test_expiredEntry_fetches() async throws {
        let sut = makeSUT(now: start.addingTimeInterval(maxAge))
        let source = Source(entry: CacheEntry(value: "cached", fetchedAt: start))

        let value = try await load(sut, from: source)

        XCTAssertEqual(value, "remote")
        XCTAssertEqual(source.fetches, 1)
    }

    func test_readFailure_isLoggedAndTreatedAsAMiss() async throws {
        let sut = makeSUT(now: start)
        let source = Source(entry: nil, readFails: true)

        let value = try await load(sut, from: source)

        XCTAssertEqual(value, "remote")
        XCTAssertTrue(logger.errors.contains { $0.message.contains("read failed") })
    }

    func test_writeFailure_isLoggedAndTheFetchedValueStillReturned() async throws {
        let sut = makeSUT(now: start)
        let source = Source(entry: nil, writeFails: true)

        let value = try await load(sut, from: source)

        XCTAssertEqual(value, "remote")
        XCTAssertTrue(logger.errors.contains { $0.message.contains("write failed") })
    }

    func test_remoteFailure_propagatesAndNothingIsWritten() async {
        struct Offline: Error {}
        let sut = makeSUT(now: start)
        let source = Source(entry: nil, fetchError: Offline())

        do {
            _ = try await load(sut, from: source)
            XCTFail("expected the remote error")
        } catch {
            XCTAssertTrue(error is Offline)
        }
        XCTAssertTrue(source.writes.isEmpty)
    }

    func test_clockDecidesFreshness() async throws {
        let source = Source(entry: CacheEntry(value: "cached", fetchedAt: start))

        let early = try await load(makeSUT(now: start.addingTimeInterval(1)), from: source)
        let late = try await load(makeSUT(now: start.addingTimeInterval(maxAge + 1)), from: source)

        XCTAssertEqual(early, "cached")
        XCTAssertEqual(late, "remote")
    }

    // MARK: - Helpers

    private func makeSUT(now: Date) -> CacheAsideLoader {
        CacheAsideLoader(policy: FreshnessPolicy(maxAge: maxAge), logger: logger, now: { now })
    }

    private func load(_ sut: CacheAsideLoader, from source: Source) async throws -> String {
        try await sut.load(read: source.read, fetch: source.fetch, write: source.write)
    }
}

private final class Source: @unchecked Sendable {
    struct Failure: Error {}

    private let entry: CacheEntry<String>?
    private let readFails: Bool
    private let writeFails: Bool
    private let fetchError: Error?

    private(set) var fetches = 0
    private(set) var writes: [(value: String, date: Date)] = []

    init(entry: CacheEntry<String>?, readFails: Bool = false, writeFails: Bool = false, fetchError: Error? = nil) {
        self.entry = entry
        self.readFails = readFails
        self.writeFails = writeFails
        self.fetchError = fetchError
    }

    func read() async throws -> CacheEntry<String>? {
        if readFails { throw Failure() }
        return entry
    }

    func fetch() async throws -> String {
        fetches += 1
        if let fetchError { throw fetchError }
        return "remote"
    }

    func write(_ value: String, _ date: Date) async throws {
        if writeFails { throw Failure() }
        writes.append((value, date))
    }
}
