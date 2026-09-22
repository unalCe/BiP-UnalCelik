import CoreData
import Foundation

// @objc: Core Data resolves the class by its Objective-C name, and Swift
// mangles class names with their module
@objc(CDProduct)
final class CDProduct: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var priceMinorUnits: Int64
    @NSManaged var currencyCode: String
    @NSManaged var imageURL: String?
    @NSManaged var productDescription: String?
    @NSManaged var listPosition: NSNumber?
    @NSManaged var detailVisitedAt: Date?
}

extension CDProduct {
    static let entityName = "CDProduct"

    static func fetchRequest() -> NSFetchRequest<CDProduct> {
        NSFetchRequest<CDProduct>(entityName: entityName)
    }

    var pageIndex: Int? {
        get { listPosition?.intValue }
        set { listPosition = newValue.map(NSNumber.init(value:)) }
    }

    var isRetained: Bool { listPosition != nil || detailVisitedAt != nil }
}

public enum ProductDataModel {
    public static let name = "ProductDataModel"
    public static let bundle = Bundle.module
}
