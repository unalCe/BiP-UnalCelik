import CoreData
import Foundation

public protocol PersistentContainerInterface: Sendable {
    func read<T: Sendable>(
        _ work: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T

    func write<T: Sendable>(
        _ work: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T
}

public enum PersistenceError: Error, Sendable {
    case modelNotFound(name: String)
    case entityNotFound(name: String)
    case storeUnavailable(Error)
    case readFailed(Error)
    case writeFailed(Error)
}
