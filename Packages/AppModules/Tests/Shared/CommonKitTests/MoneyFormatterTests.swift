import SharedDomain
import XCTest

@testable import CommonKit

final class MoneyFormatterTests: XCTestCase {
    private var formatter: MoneyFormatter!

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        formatter = nil
        super.tearDown()
    }

    /// A fixed locale, so results do not depend on the simulator's region.
    private func reCreate(locale: Locale = Locale(identifier: "en_US")) {
        formatter = MoneyFormatter(locale: locale)
    }

    /// 9 minor units is 0.09, not 9 — the bug this guards against is treating
    /// the integer as a major amount.
    func test_formatsMinorUnitsAsAMajorAmount() {
        XCTAssertEqual(formatter.string(from: Money(minorUnits: 9)), "$0.09")
        XCTAssertEqual(formatter.string(from: Money(minorUnits: 120)), "$1.20")
        XCTAssertEqual(formatter.string(from: Money(minorUnits: 557)), "$5.57")
    }

    func test_usesTheMoneysOwnCurrency() {
        XCTAssertEqual(formatter.string(from: Money(minorUnits: 120, currencyCode: "EUR")), "€1.20")
    }

    func test_followsTheLocalesSeparators() {
        reCreate(locale: Locale(identifier: "de_DE"))

        XCTAssertTrue(formatter.string(from: Money(minorUnits: 120)).contains("1,20"))
    }
}
