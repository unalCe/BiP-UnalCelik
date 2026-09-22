import CommonKit
import ImageCacheKit
import ImageCacheKitMocks
import ProductDetailMVVM
import ProductDetailMVVMUIKit
import ProductDomain
import ProductRepositoryMocks
import UIKit
import XCTest

private let screen = CGRect(x: 0, y: 0, width: 402, height: 874)

@MainActor
final class ProductDetailViewControllerTests: XCTestCase {
    func test_loaded_showsTitlePriceAndDescription() async {
        let sut = await makeLoadedSUT()

        let texts = labels(in: sut).map { $0.text ?? "" }
        XCTAssertEqual(texts.count, 3)
        XCTAssertEqual(texts.first, "Apples")
        XCTAssertTrue(texts[1].contains("1.20"), "price was \(texts[1])")
        XCTAssertEqual(texts.last, "An apple a day keeps the doctor away.")
    }

    func test_missingDescription_saysSoRatherThanVanishing() async {
        let sut = makeSUT(detail: .success(
            Product.fixture(id: "1", name: "Apples", description: nil)
        ))
        sut.view.frame = screen
        sut.loadViewIfNeeded()
        await sut.settle()
        sut.view.layoutIfNeeded()

        guard let description = labels(in: sut).last else { return XCTFail("no labels") }
        XCTAssertEqual(description.text, "Description unavailable.")
        XCTAssertFalse(description.isHidden)
        XCTAssertEqual(description.textColor, .secondaryLabel)
    }

    func test_failure_hidesTheContent() async {
        let sut = makeSUT(detail: .failure(DomainError.offline))
        sut.view.frame = screen
        sut.loadViewIfNeeded()
        await sut.settle()

        XCTAssertEqual(scrollView(in: sut)?.isHidden, true)
    }

    func test_image_isSquareAndFullWidth() async {
        let sut = await makeLoadedSUT()

        guard let image = imageView(in: sut) else { return XCTFail("no image view") }
        XCTAssertEqual(image.bounds.width, screen.width, accuracy: 0.5)
        XCTAssertEqual(image.bounds.height, image.bounds.width, accuracy: 0.5)
    }

    func test_titleTakesTheSlack_andThePriceStaysWhole() async {
        let sut = await makeLoadedSUT()

        let (title, price) = (labels(in: sut)[0], labels(in: sut)[1])
        let titleFrame = title.convert(title.bounds, to: sut.view)
        let priceFrame = price.convert(price.bounds, to: sut.view)

        XCTAssertEqual(titleFrame.minX, 16, accuracy: 0.5, "title pinned to the leading margin")
        XCTAssertEqual(priceFrame.maxX, screen.width - 16, accuracy: 0.5,
                       "price pinned to the trailing margin")
        XCTAssertLessThanOrEqual(titleFrame.maxX, priceFrame.minX, "they must not overlap")
        XCTAssertEqual(priceFrame.width, price.intrinsicContentSize.width, accuracy: 0.5,
                       "the price is never the one that gets compressed")
    }

    func test_descriptionSitsBelowTheHeader() async {
        let sut = await makeLoadedSUT()

        let labels = labels(in: sut)
        let header = labels[0].convert(labels[0].bounds, to: sut.view)
        let description = labels[2].convert(labels[2].bounds, to: sut.view)

        XCTAssertGreaterThan(description.minY, header.maxY)
    }

    func test_contentNeverScrollsHorizontally() async {
        let sut = await makeLoadedSUT(
            description: String(repeating: "A very long description. ", count: 40)
        )

        guard let scroll = scrollView(in: sut) else { return XCTFail("no scroll view") }
        XCTAssertEqual(scroll.contentSize.width, screen.width, accuracy: 0.5)
        XCTAssertGreaterThan(scroll.contentSize.height, screen.height,
                             "a long description must make the page scroll")
    }

    func test_imageIsRequestedAtTheWidthItWillBeDrawnAt() async {
        let loader = MockImageLoader()
        let sut = makeSUT(
            detail: .success(Product(
                id: "1", name: "Apples", price: Money(minorUnits: 120),
                imageURL: URL(string: "https://example.com/1.jpg"), productDescription: "d"
            )),
            loader: loader
        )
        sut.view.frame = screen
        sut.loadViewIfNeeded()
        await sut.settle()
        sut.view.layoutIfNeeded()
        for _ in 0..<200 where loader.requestedRequests.isEmpty { await Task.yield() }

        guard let request = loader.requestedRequests.first else {
            return XCTFail("the image view never asked for anything")
        }
        let scale = sut.traitCollection.displayScale
        XCTAssertEqual(
            request.maxPixelSize,
            ImageRequest(url: request.url, pointSize: screen.width, scale: scale).maxPixelSize
        )
    }

    // MARK: - Helpers

    private func makeSUT(
        detail: Result<Product, any Error> = .success(
            Product.fixture(id: "1", name: "Apples",
                            description: "An apple a day keeps the doctor away.")
        ),
        loader: MockImageLoader = MockImageLoader()
    ) -> ProductDetailViewController {
        ProductDetailViewController(
            viewModel: ProductDetailViewModel(
                productID: "1",
                fetchDetail: FetchProductDetail(repository: StubProductRepository(detail: detail)),
                mapper: ProductDisplayMapper(
                    priceFormatter: MoneyFormatter(locale: Locale(identifier: "en_US"))
                )
            ),
            imageLoader: loader
        )
    }

    private func makeLoadedSUT(description: String = "An apple a day keeps the doctor away.")
        async -> ProductDetailViewController
    {
        let sut = makeSUT(detail: .success(
            Product.fixture(id: "1", name: "Apples", description: description)
        ))
        sut.view.frame = screen
        sut.loadViewIfNeeded()
        await sut.settle()
        sut.view.layoutIfNeeded()
        return sut
    }

    private func scrollView(in controller: UIViewController) -> UIScrollView? {
        controller.view.subviews.compactMap { $0 as? UIScrollView }.first
    }

    private func imageView(in controller: UIViewController) -> UIImageView? {
        descendants(of: controller.view).compactMap { $0 as? UIImageView }.first
    }

    private func labels(in controller: UIViewController) -> [UILabel] {
        guard let scroll = scrollView(in: controller) else { return [] }
        return descendants(of: scroll).compactMap { $0 as? UILabel }
    }

    private func descendants(of view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
    }
}

@MainActor
private extension ProductDetailViewController {
    func settle() async {
        for _ in 0..<100 { await Task.yield() }
    }
}
