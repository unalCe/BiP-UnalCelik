import CoreData
import Foundation
import PersistenceKit

public final class CoreDataStack: PersistentContainerInterface, @unchecked Sendable {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    public convenience init(modelName: String, bundle: Bundle, inMemory: Bool = false) throws {
        try self.init(
            modelName: modelName,
            model: Self.loadModel(named: modelName, in: bundle),
            inMemory: inMemory
        )
    }

    public init(modelName: String, model: NSManagedObjectModel, inMemory: Bool = false) throws {
        container = NSPersistentContainer(name: modelName, managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions = [
                NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))
            ]
        }

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw PersistenceError.storeUnavailable(loadError) }

        // one context for every operation, so a read-modify-write cannot
        // interleave with another one
        context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    public func read<T: Sendable>(
        _ work: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = context
        do {
            return try await context.perform {
                defer { if context.hasChanges { context.rollback() } }
                return try work(context)
            }
        } catch {
            throw PersistenceError.readFailed(error)
        }
    }

    public func write<T: Sendable>(
        _ work: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = context
        do {
            return try await context.perform {
                // the context outlives the call, so a half-finished write has
                // to be undone or the next one commits it
                do {
                    let result = try work(context)
                    if context.hasChanges { try context.save() }
                    return result
                } catch {
                    context.rollback()
                    throw error
                }
            }
        } catch {
            throw PersistenceError.writeFailed(error)
        }
    }
}

public extension CoreDataStack {
    /// The file a non-in-memory stack for `modelName` opens.
    static func storeURL(modelName: String) -> URL {
        NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("\(modelName).sqlite")
    }

    /// Deletes the on-disk store, so a caller whose store is only a cache can
    /// rebuild it instead of migrating. Through the coordinator rather than
    /// `FileManager`, because SQLite keeps -wal and -shm files beside it.
    static func destroyStore(modelName: String, bundle: Bundle) throws {
        try destroyStore(modelName: modelName, model: loadModel(named: modelName, in: bundle))
    }

    static func destroyStore(modelName: String, model: NSManagedObjectModel) throws {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try coordinator.destroyPersistentStore(
                at: storeURL(modelName: modelName), type: .sqlite
            )
        } catch {
            throw PersistenceError.storeUnavailable(error)
        }
    }

    private static func loadModel(named modelName: String, in bundle: Bundle) throws -> NSManagedObjectModel {
        guard
            let url = bundle.url(forResource: modelName, withExtension: "momd")
                ?? bundle.url(forResource: modelName, withExtension: "mom"),
            let model = NSManagedObjectModel(contentsOf: url)
        else {
            throw PersistenceError.modelNotFound(name: modelName)
        }
        return model
    }
}
