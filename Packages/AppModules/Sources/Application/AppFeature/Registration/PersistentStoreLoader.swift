import CoreData
import Foundation
import LoggingKit
import PersistenceKit

/// The store is a cache, so failing to open it is a reason to rebuild it, not
/// to crash — that is what makes "no migration needed" true. Each rung is
/// logged, and the bottom one cannot fail.
struct PersistentStoreLoader {
    var openOnDisk: () throws -> PersistentContainerInterface
    var destroyOnDisk: () throws -> Void
    var openInMemory: () throws -> PersistentContainerInterface
    var logger: LoggerInterface

    func load() -> PersistentContainerInterface {
        do {
            return try openOnDisk()
        } catch {
            logger.error("store would not open, rebuilding it: \(error)", category: .persistence)
        }

        do {
            try destroyOnDisk()
            let container = try openOnDisk()
            logger.debug("store rebuilt empty", category: .persistence)
            return container
        } catch {
            logger.error("store would not rebuild, running this session in memory: \(error)", category: .persistence)
        }

        do {
            return try openInMemory()
        } catch {
            // only a model missing from the bundle gets here — a build fault,
            // but the repository already treats every store failure as a miss
            logger.error("no store at all, running without a cache: \(error)", category: .persistence)
            return NoStore()
        }
    }
}

private struct NoStore: PersistentContainerInterface {
    private struct Unavailable: Error {}

    func read<T: Sendable>(
        _ work: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        throw PersistenceError.storeUnavailable(Unavailable())
    }

    func write<T: Sendable>(
        _ work: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        throw PersistenceError.storeUnavailable(Unavailable())
    }
}
