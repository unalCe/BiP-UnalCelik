import CoreData
import PersistenceKit
import TestSupport
import XCTest

@testable import PersistenceKitLive

/// The model is built in code, so the stack is exercised without any
/// consumer's model — which is the point of `CoreDataStack` being
/// product-agnostic.
final class CoreDataStackTests: XCTestCase {
    private var stack: CoreDataStack!
    private var model: NSManagedObjectModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        model = Self.makeModel()
        stack = try CoreDataStack(modelName: "Test", model: model, inMemory: true)
    }

    override func tearDown() {
        stack = nil
        model = nil
        super.tearDown()
    }

    func test_write_persistsAcrossOperations() async throws {
        try await stack.write { context in
            NSEntityDescription.insertNewObject(forEntityName: "Thing", into: context)
                .setValue("Apples", forKey: "name")
        }

        let names = try await stack.read { context in
            try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Thing"))
                .compactMap { $0.value(forKey: "name") as? String }
        }
        XCTAssertEqual(names, ["Apples"])
    }

    func test_read_discardsChangesItMade() async throws {
        try await stack.read { context in
            NSEntityDescription.insertNewObject(forEntityName: "Thing", into: context)
                .setValue("Uncommitted", forKey: "name")
        }

        let remaining = try await stack.read { try Self.count(in: $0) }
        XCTAssertEqual(remaining, 0)
    }

    func test_write_thatThrows_savesNothing() async throws {
        struct Boom: Error {}

        await XCTAssertThrowsErrorAsync(
            try await stack.write { context in
                NSEntityDescription.insertNewObject(forEntityName: "Thing", into: context)
                    .setValue("Apples", forKey: "name")
                throw Boom()
            }
        ) { error in
            // the contract: the caller's error arrives wrapped
            guard case PersistenceError.writeFailed = error else {
                return XCTFail("expected writeFailed, got \(error)")
            }
        }

        let remaining = try await stack.read { try Self.count(in: $0) }
        XCTAssertEqual(remaining, 0, "a failed write must not leave a row behind")
    }

    func test_missingModel_throwsRatherThanTrapping() {
        XCTAssertThrowsError(try CoreDataStack(modelName: "NoSuchModel", bundle: .main, inMemory: true)) { error in
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
        defer { try? CoreDataStack.destroyStore(modelName: modelName, model: model) }
        try await CoreDataStack(modelName: modelName, model: model).write { context in
            NSEntityDescription.insertNewObject(forEntityName: "Thing", into: context)
                .setValue("Apples", forKey: "name")
        }

        try CoreDataStack.destroyStore(modelName: modelName, model: model)

        let reopened = try CoreDataStack(modelName: modelName, model: model)
        let remaining = try await reopened.read { try Self.count(in: $0) }
        XCTAssertEqual(remaining, 0)
    }

    // MARK: - Helpers

    private static func makeModel() -> NSManagedObjectModel {
        let name = NSAttributeDescription()
        name.name = "name"
        name.attributeType = .stringAttributeType
        name.isOptional = false

        let entity = NSEntityDescription()
        entity.name = "Thing"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [name]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }

    private static func count(in context: NSManagedObjectContext) throws -> Int {
        try context.count(for: NSFetchRequest<NSManagedObject>(entityName: "Thing"))
    }
}
