import Foundation

/// Minor units: 120 is 1.20. The API sends integers, and `Double` can't
/// represent 0.01 exactly.
public struct Money: Hashable, Sendable, Codable {
    public let minorUnits: Int
    public let currencyCode: String

    public init(minorUnits: Int, currencyCode: String = "GBP") {
        self.minorUnits = minorUnits
        self.currencyCode = currencyCode
    }
}
