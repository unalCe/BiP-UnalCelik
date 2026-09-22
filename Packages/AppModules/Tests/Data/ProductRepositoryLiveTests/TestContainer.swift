import PersistenceKitLive
import XCTest
@testable import ProductRepositoryLive

/// The real stack against an in-memory store — the same code the app runs, so
/// these tests cannot pass against a double that drifted.
func makeTestContainer() throws -> CoreDataStack {
    try CoreDataStack(
        modelName: ProductDataModel.name,
        bundle: ProductDataModel.bundle,
        inMemory: true
    )
}
