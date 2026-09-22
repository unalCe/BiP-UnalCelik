import CoreData
import Foundation
import PersistenceKit
import ProductDomain

struct CoreDataProductStore: ProductLocalDataSource {
    private let container: any PersistentContainerInterface

    init(container: any PersistentContainerInterface) {
        self.container = container
    }

    // MARK: - Reads

    func products() async -> Cached<[Product]>? {
        let page = try? await container.read { context -> Cached<[Product]>? in
            let request = CDProduct.fetchRequest()
            request.predicate = NSPredicate(format: "listPosition != nil")
            request.sortDescriptors = [NSSortDescriptor(key: "listPosition", ascending: true)]

            let rows = try context.fetch(request)
            guard let fetchedAt = rows.first?.listFetchedAt, !rows.isEmpty else { return nil }
            return Cached(value: rows.map(ProductMapper.map), fetchedAt: fetchedAt)
        }
        return page ?? nil
    }

    func detail(id: String) async -> Cached<Product>? {
        let row = try? await container.read { context -> Cached<Product>? in
            let request = CDProduct.fetchRequest()
            request.predicate = NSPredicate(
                format: "id == %@ AND detailVisitedAt != nil", id
            )
            request.fetchLimit = 1

            guard let row = try context.fetch(request).first,
                  let fetchedAt = row.detailVisitedAt else { return nil }
            return Cached(value: ProductMapper.map(row), fetchedAt: fetchedAt)
        }
        return row ?? nil
    }

    // MARK: - Writes

    func saveListPage(_ products: [Product], at date: Date) async {
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
                row.listFetchedAt = date
            }

            try Self.deleteDeparted(in: context)
        }
    }

    func saveDetail(_ product: Product, at date: Date) async {
        try? await container.write { context in
            let row = try Self.findOrCreate(id: product.id, in: context)
            Self.merge(product, into: row)
            row.detailVisitedAt = date

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

    private static func deleteDeparted(in context: NSManagedObjectContext) throws {
        let request = CDProduct.fetchRequest()
        request.predicate = NSPredicate(format: "listPosition == nil")
        for row in try context.fetch(request) { context.delete(row) }
    }
}
