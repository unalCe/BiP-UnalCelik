import Foundation

/// Minor units: 120 is 1.20. The API sends integers, and `Double` can't
/// represent 0.01 exactly.
public struct Money: Hashable, Sendable, Codable {
    public let minorUnits: Int
    public let currencyCode: String

    // the API sends no currency, so this is the one place one is assumed;
    // the Core Data store deliberately has no default of its own
    public init(minorUnits: Int, currencyCode: String = "USD") {
        self.minorUnits = minorUnits
        self.currencyCode = currencyCode
    }
}
