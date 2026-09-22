import Foundation
import ProductDomain

extension ProductMapper {
    static func map(_ row: CDProduct) -> Product {
        Product(
            id: row.id,
            name: row.name,
            price: Money(
                minorUnits: Int(row.priceMinorUnits),
                currencyCode: row.currencyCode
            ),
            imageURL: row.imageURL.flatMap(URL.init(string:)),
            productDescription: row.productDescription
        )
    }
}
