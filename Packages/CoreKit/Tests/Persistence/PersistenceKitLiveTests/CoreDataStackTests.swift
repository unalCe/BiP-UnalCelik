import CoreData
import PersistenceKit
import XCTest
@testable import PersistenceKitLive

/// Built in code so the stack can be exercised without any consumer's model —
/// which is the whole point of `CoreDataStack` being product-agnostic.
private func makeTestModel() -> NSManagedObjectModel {
    let entity = NSEntityDescription()
    entity.name = "Thing"
    entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

    let name = NSAttributeDescription()
    name.name = "name"
    name.attributeType = .stringAttributeType
    name.isOptional = false
    entity.properties = [name]

    let model = NSManagedObjectModel()
    model.entities = [entity]
    return model
}

private func makeSUT() throws -> CoreDataStack {
    try CoreDataStack(modelName: "Test", model: makeTestModel(), inMemory: true)
}

private func count(in context: NSManagedObjectContext) throws -> Int {
    try context.count(for: NSFetchRequest<NSManagedObject>(entityName: "Thing"))
}

final class CoreDataStackTests: XCTestCase {
    func test_write_persistsAcrossOperations() async throws {
        let sut = try makeSUT()

        try await sut.write { context in
            let thing = NSEntityDescription.insertNewObject(forEntityName: "Thing", into: context)
            thing.setValue("Apples", forKey: "name")
        }

        let names = try await sut.read { context in
            try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Thing"))
                .compactMap { $0.value(forKey: "name") as? String }
        }
        XCTAssertEqual(names, ["Apples"])
    }

    func test_read_discardsChangesItMade() async throws {
        let sut = try makeSUT()

        try await sut.read { context in
            let thing = NSEntityDescription.insertNewObject(forEntityName: "Thing", into: context)
            thing.setValue("Uncommitted", forKey: "name")
        }

        let remaining = try await sut.read { try count(in: $0) }
        XCTAssertEqual(remaining, 0)
    }

    func test_write_thatThrows_savesNothing() async throws {
        let sut = try makeSUT()
        struct Boom: Error {}

        do {
            try await sut.write { context in
                NSEntityDescription.insertNewObject(forEntityName: "Thing", into: context)
                    .setValue("Apples", forKey: "name")
                throw Boom()
            }
            XCTFail("expected the error to propagate")
        } catch PersistenceError.writeFailed {
            // the contract: the caller's error arrives wrapped
        }

        let remaining = try await sut.read { try count(in: $0) }
        XCTAssertEqual(remaining, 0, "a failed write must not leave a row behind")
    }

    func test_missingModel_throwsRatherThanTrapping() {
        XCTAssertThrowsError(
            try CoreDataStack(modelName: "NoSuchModel", bundle: .main, inMemory: true)
        ) { error in
            guard case PersistenceError.modelNotFound(let name)? = error as? PersistenceError else {
                return XCTFail("expected modelNotFound, got \(error)")
            }
            XCTAssertEqual(name, "NoSuchModel")
        }
    }

    /// The rebuild path a cache relies on instead of migration: what was on
    /// disk is gone, and the same name opens again empty.
    func test_destroyStore_leavesAnEmptyStoreBehind() async throws {
        let modelName = "DestroyTest-\(UUID().uuidString)"
        let model = makeTestModel()
        defer { try? CoreDataStack.destroyStore(modelName: modelName, model: model) }

        try await CoreDataStack(modelName: modelName, model: model).write { context in
            NSEntityDescription.insertNewObject(forEntityName: "Thing", into: context)
                .setValue("Apples", forKey: "name")
        }

        try CoreDataStack.destroyStore(modelName: modelName, model: model)

        let reopened = try CoreDataStack(modelName: modelName, model: model)
        let remaining = try await reopened.read { try count(in: $0) }
        XCTAssertEqual(remaining, 0)
    }
}
