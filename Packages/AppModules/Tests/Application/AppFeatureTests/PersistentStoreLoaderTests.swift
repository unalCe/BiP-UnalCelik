import CoreData
import LoggingKitMocks
import PersistenceKit
import TestSupport
import XCTest

@testable import AppFeature

/// The ladder, rung by rung, without needing a genuinely corrupt store. Each
/// rung is a closure the test decides the outcome of.
final class PersistentStoreLoaderTests: XCTestCase {
    private struct Corrupt: Error {}

    private var loader: PersistentStoreLoader!
    private var logger: SpyLogger!
    private var onDisk: StubContainer!
    private var inMemory: StubContainer!
    private var openOnDiskCount = 0
    private var destroyOnDiskCount = 0
    private var openInMemoryCount = 0

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        loader = nil
        logger = nil
        onDisk = nil
        inMemory = nil
        super.tearDown()
    }

    /// `openOnDisk` fails while `diskOpens` is false; `destroyOnDisk` makes it
    /// open again when `destroyRepairs` is true.
    private func reCreate(
        diskOpens: Bool = true,
        destroyRepairs: Bool = false,
        destroySucceeds: Bool = true,
        memoryOpens: Bool = true
    ) {
        logger = SpyLogger()
        onDisk = StubContainer()
        inMemory = StubContainer()
        openOnDiskCount = 0
        destroyOnDiskCount = 0
        openInMemoryCount = 0
        var repaired = false

        loader = PersistentStoreLoader(
            openOnDisk: { [unowned self] in
                self.openOnDiskCount += 1
                guard diskOpens || repaired else { throw Corrupt() }
                return self.onDisk
            },
            destroyOnDisk: { [unowned self] in
                self.destroyOnDiskCount += 1
                guard destroySucceeds else { throw Corrupt() }
                repaired = destroyRepairs
            },
            openInMemory: { [unowned self] in
                self.openInMemoryCount += 1
                guard memoryOpens else { throw Corrupt() }
                return self.inMemory
            },
            logger: logger
        )
    }

    func test_healthyStore_opensOnDisk_andDestroysNothing() {
        let loaded = loader.load()

        XCTAssertTrue(loaded as AnyObject === onDisk)
        XCTAssertEqual(destroyOnDiskCount, 0)
        XCTAssertEqual(openInMemoryCount, 0)
        XCTAssertTrue(logger.entries.isEmpty)
    }

    func test_unopenableStore_isDestroyedAndReopened() {
        reCreate(diskOpens: false, destroyRepairs: true)

        let loaded = loader.load()

        XCTAssertTrue(loaded as AnyObject === onDisk)
        XCTAssertEqual(openOnDiskCount, 2, "retried exactly once")
        XCTAssertEqual(destroyOnDiskCount, 1)
        XCTAssertEqual(openInMemoryCount, 0)
        XCTAssertEqual(logger.errors.count, 1)
    }

    func test_unrebuildableStore_fallsBackToMemory() {
        reCreate(diskOpens: false, destroySucceeds: false)

        let loaded = loader.load()

        XCTAssertTrue(loaded as AnyObject === inMemory)
        XCTAssertEqual(logger.errors.count, 2, "one line per rung that failed")
    }

    func test_noStoreAtAll_stillLoads_andEveryOperationFails() async {
        reCreate(diskOpens: false, destroySucceeds: false, memoryOpens: false)

        let loaded = loader.load()

        await XCTAssertThrowsErrorAsync(try await loaded.read { _ in 1 }) { error in
            XCTAssertTrue(error is PersistenceError, "got \(error)")
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
