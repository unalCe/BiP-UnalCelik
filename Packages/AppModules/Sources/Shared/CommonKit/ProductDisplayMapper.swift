import Foundation
import ProductDomain

public struct ProductDisplayMapper: Sendable {
    private let priceFormatter: MoneyFormatter

    public init(priceFormatter: MoneyFormatter = MoneyFormatter()) {
        self.priceFormatter = priceFormatter
    }

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

public struct MoneyFormatter: Sendable {
    private let locale: Locale

    /// Injectable so tests don't depend on the simulator's region
    /// (0.09 vs 0,09).
    public init(locale: Locale = .current) {
        self.locale = locale
    }

    public func string(from money: Money) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = money.currencyCode
        let major = Decimal(money.minorUnits) / 100
        return formatter.string(from: major as NSDecimalNumber)
            ?? "\(major) \(money.currencyCode)"
    }
}
