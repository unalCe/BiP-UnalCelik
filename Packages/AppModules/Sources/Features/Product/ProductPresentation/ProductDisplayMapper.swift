import CommonKit
import Foundation
import ProductDomain

public struct ProductDisplayMapper: Sendable {
    private let priceFormatter: MoneyFormatter

    // MARK: - Lifecycle

    public init(priceFormatter: MoneyFormatter = MoneyFormatter()) {
        self.priceFormatter = priceFormatter
    }

    // MARK: - Public Funcs

    public func map(_ product: Product) -> ProductDisplayModel {
        ProductDisplayModel(
            id: product.id,
            title: product.name,
            formattedPrice: priceFormatter.string(from: product.price),
            description: product.productDescription,
            imageURL: product.imageURL
        )
    }

    public func map(_ products: [Product]) -> [ProductDisplayModel] {
        products.map(map)
    }
}
