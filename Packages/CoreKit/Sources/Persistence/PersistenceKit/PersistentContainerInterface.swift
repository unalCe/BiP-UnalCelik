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
    case storeUnavailable(any Error)
    case readFailed(any Error)
    case writeFailed(any Error)
}
