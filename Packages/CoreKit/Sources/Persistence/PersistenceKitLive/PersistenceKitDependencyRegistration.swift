import DependencyEngine
import PersistenceKit

public enum PersistenceKitDependencyRegistration: DependencyRegistration {
    public static func register(to engine: DependencyEngine) {
        engine.register(
            value: CoreDataPersistentStore() as any PersistentStoreInterface,
            for: (any PersistentStoreInterface).self
        )
    }
}
