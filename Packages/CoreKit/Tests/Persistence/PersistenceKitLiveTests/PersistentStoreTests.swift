import XCTest
import PersistenceKit
import PersistenceKitMocks
@testable import PersistenceKitLive

private struct Item: Codable, Equatable {
    let id: String
    let name: String
}

/// Same contract exercised against both the live store and the mock, so the
/// mock cannot quietly drift from the behaviour consumers rely on.
final class PersistentStoreTests: XCTestCase {
    func test_liveStore_roundTrips() async throws {
        try await assertRoundTrips(CoreDataPersistentStore(inMemory: true))
    }

    func test_mockStore_roundTrips() async throws {
        try await assertRoundTrips(MockPersistentStore())
    }

    func test_missingKey_returnsNil() async throws {
        let sut = CoreDataPersistentStore(inMemory: true)
        let value = try await sut.read(Item.self, forKey: "absent")
        XCTAssertNil(value)
    }

    func test_removeAll_clearsEverything() async throws {
        let sut = CoreDataPersistentStore(inMemory: true)
        try await sut.write(Item(id: "1", name: "Apples"), forKey: "products")
        try await sut.removeAll()

        let value = try await sut.read(Item.self, forKey: "products")
        XCTAssertNil(value)
    }

    private func assertRoundTrips(
        _ sut: any PersistentStoreInterface,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let item = Item(id: "6_id_is_a_string", name: "Pork")
        try await sut.write(item, forKey: "product")

        let read = try await sut.read(Item.self, forKey: "product")

        XCTAssertEqual(read, item, file: file, line: line)
    }
}
