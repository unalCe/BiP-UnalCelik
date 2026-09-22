import CoreData
import LoggingKitMocks
import PersistenceKit
import XCTest
@testable import AppFeature

/// The ladder, rung by rung, without needing a genuinely corrupt store.
final class PersistentStoreLoaderTests: XCTestCase {
    private struct Corrupt: Error {}

    func test_healthyStore_opensOnDisk_andDestroysNothing() {
        let onDisk = StubContainer()
        var destroyed = false
        let logger = SpyLogger()

        let loaded = PersistentStoreLoader(
            openOnDisk: { onDisk },
            destroyOnDisk: { destroyed = true },
            openInMemory: { XCTFail("no fallback needed"); return StubContainer() },
            logger: logger
        ).load()

        XCTAssertTrue(loaded as AnyObject === onDisk)
        XCTAssertFalse(destroyed)
        XCTAssertTrue(logger.entries.isEmpty)
    }

    func test_unopenableStore_isDestroyedAndReopened() {
        let rebuilt = StubContainer()
        var attempts = 0
        var destroyed = false
        let logger = SpyLogger()

        let loaded = PersistentStoreLoader(
            openOnDisk: {
                attempts += 1
                guard destroyed else { throw Corrupt() }
                return rebuilt
            },
            destroyOnDisk: { destroyed = true },
            openInMemory: { XCTFail("the rebuild should have worked"); return StubContainer() },
            logger: logger
        ).load()

        XCTAssertTrue(loaded as AnyObject === rebuilt)
        XCTAssertEqual(attempts, 2, "retried exactly once")
        XCTAssertEqual(logger.errors.count, 1)
    }

    func test_unrebuildableStore_fallsBackToMemory() {
        let inMemory = StubContainer()
        let logger = SpyLogger()

        let loaded = PersistentStoreLoader(
            openOnDisk: { throw Corrupt() },
            destroyOnDisk: { throw Corrupt() },
            openInMemory: { inMemory },
            logger: logger
        ).load()

        XCTAssertTrue(loaded as AnyObject === inMemory)
        XCTAssertEqual(logger.errors.count, 2, "one line per rung that failed")
    }

    func test_noStoreAtAll_stillLoads_andEveryOperationFails() async {
        let logger = SpyLogger()

        let loaded = PersistentStoreLoader(
            openOnDisk: { throw Corrupt() },
            destroyOnDisk: { throw Corrupt() },
            openInMemory: { throw Corrupt() },
            logger: logger
        ).load()

        do {
            _ = try await loaded.read { _ in 1 }
            XCTFail("expected the read to fail")
        } catch {
            XCTAssertTrue(error is PersistenceError)
        }
        XCTAssertEqual(logger.errors.count, 3)
    }
}

private final class StubContainer: PersistentContainerInterface, @unchecked Sendable {
    func read<T: Sendable>(
        _ work: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        throw CocoaError(.featureUnsupported)
    }

    func write<T: Sendable>(
        _ work: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        throw CocoaError(.featureUnsupported)
    }
}
