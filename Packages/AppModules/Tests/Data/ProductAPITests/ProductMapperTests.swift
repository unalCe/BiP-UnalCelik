import ProductDomain
import ProductRepositoryMocks
import SharedDomain
import XCTest

@testable import ProductAPI

/// Decodes the captured responses and maps them — the one place the wire
/// format meets the domain.
final class ProductMapperTests: XCTestCase {
    private var decoder: JSONDecoder!

    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    private func decodeList(_ name: String = "ProductListResponse") throws -> [Product] {
        ProductMapper.map(try decoder.decode(ProductListResponseDTO.self, from: ProductFixture.data(name)).products)
    }

    private func decodeProduct(_ json: String) throws -> Product {
        ProductMapper.map(try decoder.decode(ProductDTO.self, from: Data(json.utf8)))
    }

    // MARK: - List

    /// The live payload ships `"6_id_is_a_string"` next to `"1"`; an `Int` id
    /// would drop that product.
    func test_list_keepsNonNumericIDsAndOrder() throws {
        XCTAssertEqual(try decodeList().map(\.id), ["1", "6_id_is_a_string", "12"])
    }

    /// Prices arrive as integers in minor units: 9 is 0.09, not 9.00.
    func test_list_readsPricesAsMinorUnits() throws {
        XCTAssertEqual(try decodeList().map(\.price), [
            Money(minorUnits: 120), Money(minorUnits: 343), Money(minorUnits: 9),
        ])
    }

    func test_list_hasNoDescription() throws {
        XCTAssertEqual(try decodeList().map(\.productDescription), [nil, nil, nil])
    }

    func test_list_emptyResponse_isAnEmptyList() throws {
        XCTAssertTrue(try decodeList("EmptyProductListResponse").isEmpty)
    }

    func test_list_malformedResponse_throws() {
        XCTAssertThrowsError(try decodeList("MalformedProductListResponse"))
    }

    // MARK: - Detail

    func test_detail_carriesEveryField() throws {
        let product = try decoder.decode(ProductDTO.self, from: ProductFixture.data("ProductDetailResponse"))

        XCTAssertEqual(ProductMapper.map(product), Product(
            id: "1",
            name: "Apples",
            price: Money(minorUnits: 120),
            imageURL: URL(string: "https://s3-eu-west-1.amazonaws.com/developer-application-test/images/1.jpg"),
            productDescription: "An apple a day keeps the doctor away."
        ))
    }

    func test_missingImage_mapsToNoURL() throws {
        let product = try decodeProduct(#"{ "product_id": "1", "name": "Apples", "price": 120 }"#)

        XCTAssertNil(product.imageURL)
    }

    func test_missingRequiredField_throws() {
        XCTAssertThrowsError(try decodeProduct(#"{ "product_id": "1", "price": 120 }"#))
    }
}
