import CommonKit
import ProductDomain
import ProductRepositoryMocks
import XCTest

@testable import ProductPresentation

final class ProductDisplayMapperTests: XCTestCase {
    private var mapper: ProductDisplayMapper!

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        mapper = nil
        super.tearDown()
    }

    /// A fixed locale, so the price does not depend on the simulator's region.
    private func reCreate(locale: Locale = Locale(identifier: "en_US")) {
        mapper = ProductDisplayMapper(priceFormatter: MoneyFormatter(locale: locale))
    }

    func test_mapProduct_carriesEveryFieldAndFormatsThePrice() {
        let product = ProductFixture.detail()

        let display = mapper.map(product)

        XCTAssertEqual(display.id, "1")
        XCTAssertEqual(display.title, "Apples")
        XCTAssertEqual(display.formattedPrice, "$1.20")
        XCTAssertEqual(display.description, "An apple a day keeps the doctor away.")
        XCTAssertEqual(display.imageURL, product.imageURL)
    }

    /// The list endpoint sends no description; the mapper must not invent one.
    func test_mapProduct_fromTheList_hasNoDescription() {
        let display = mapper.map(ProductFixture.list()[0])

        XCTAssertNil(display.description)
    }

    func test_mapProducts_keepsTheResponseOrder() {
        let display = mapper.map(ProductFixture.list())

        XCTAssertEqual(display.map(\.id), ["1", "6_id_is_a_string", "12"])
        XCTAssertEqual(display.map(\.formattedPrice), ["$1.20", "$3.43", "$0.09"])
    }
}
