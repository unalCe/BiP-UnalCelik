import CoreData
import Foundation
import PersistenceKit
import ProductDomain

// Retention policy and its two numbers: ARCHITECTURE.md §5.
struct CoreDataProductStore: ProductLocalDataSource {
    static let retainedDetailCount = 3

    private let container: any PersistentContainerInterface

    init(container: any PersistentContainerInterface) {
        self.container = container
    }

    // MARK: - Reads

    func products() async -> [Product] {
        let rows = try? await container.read { context in
            let request = CDProduct.fetchRequest()
            request.predicate = NSPredicate(format: "listPosition != nil")
            request.sortDescriptors = [NSSortDescriptor(key: "listPosition", ascending: true)]
            return try context.fetch(request).map(ProductMapper.map)
        }
        return rows ?? []
    }

    func product(id: String) async -> Product? {
        let row = try? await container.read { context in
            try Self.find(id: id, in: context).map(ProductMapper.map)
        }
        return row ?? nil
    }

    // MARK: - Writes

    func saveListPage(_ products: [Product]) async {
        try? await container.write { context in
            let ids = products.map(\.id)
            let departed = CDProduct.fetchRequest()
            departed.predicate = NSPredicate(
                format: "listPosition != nil AND NOT (id IN %@)", ids
            )
            for row in try context.fetch(departed) { row.pageIndex = nil }

            for (index, product) in products.enumerated() {
                let row = try Self.findOrCreate(id: product.id, in: context)
                Self.merge(product, into: row)
                row.pageIndex = index
            }

            try Self.deleteUnretained(in: context)
        }
    }

    func saveDetail(_ product: Product) async {
        try? await container.write { context in
            let row = try Self.findOrCreate(id: product.id, in: context)
            Self.merge(product, into: row)
            row.detailVisitedAt = Date()

            let visited = CDProduct.fetchRequest()
            visited.predicate = NSPredicate(format: "detailVisitedAt != nil")
            visited.sortDescriptors = [
                NSSortDescriptor(key: "detailVisitedAt", ascending: false)
            ]
            for evicted in try context.fetch(visited).dropFirst(Self.retainedDetailCount) {
                evicted.detailVisitedAt = nil
                evicted.productDescription = nil
            }

            try Self.deleteUnretained(in: context)
        }
    }

    // MARK: - Rows

    private static func find(
        id: String, in context: NSManagedObjectContext
    ) throws -> CDProduct? {
        let request = CDProduct.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private static func findOrCreate(
        id: String, in context: NSManagedObjectContext
    ) throws -> CDProduct {
        if let existing = try find(id: id, in: context) { return existing }
        let row = CDProduct(
            entity: NSEntityDescription.entity(forEntityName: CDProduct.entityName, in: context)!,
            insertInto: context
        )
        row.id = id
        return row
    }

    private static func merge(_ product: Product, into row: CDProduct) {
        row.name = product.name
        row.priceMinorUnits = Int64(product.price.minorUnits)
        row.currencyCode = product.price.currencyCode
        if let imageURL = product.imageURL {
            row.imageURL = imageURL.absoluteString
        }
        if let description = product.productDescription {
            row.productDescription = description
        }
    }

    private static func deleteUnretained(in context: NSManagedObjectContext) throws {
        let request = CDProduct.fetchRequest()
        request.predicate = NSPredicate(
            format: "listPosition == nil AND detailVisitedAt == nil"
        )
        for row in try context.fetch(request) { context.delete(row) }
    }
}
