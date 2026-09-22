import ImageCacheKit
import XCTest

final class ImageRequestTests: XCTestCase {
    private let url = URL(string: "https://example.com/images/1.jpg")!

    func test_pixelSize_roundsUpToThe128Step() {
        XCTAssertEqual(ImageRequest(url: url, maxPixelSize: 128).maxPixelSize, 128)
        XCTAssertEqual(ImageRequest(url: url, maxPixelSize: 129).maxPixelSize, 256)
        XCTAssertEqual(ImageRequest(url: url, maxPixelSize: 555).maxPixelSize, 640)
    }

    func test_pixelSize_isClampedToOneStepAnd2048() {
        XCTAssertEqual(ImageRequest(url: url, maxPixelSize: 0).maxPixelSize, 128)
        XCTAssertEqual(ImageRequest(url: url, maxPixelSize: 5000).maxPixelSize, 2048)
    }

    func test_noScreenScale_decodesAt3x() {
        let request = ImageRequest(url: url, pointSize: 100, scale: 0)

        XCTAssertEqual(request.scale, 3)
        XCTAssertEqual(request.maxPixelSize, 384)
    }
}
