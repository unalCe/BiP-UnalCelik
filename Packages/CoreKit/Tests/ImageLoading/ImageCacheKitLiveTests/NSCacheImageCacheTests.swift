import ImageCacheKit
import UIKit
import XCTest

@testable import ImageCacheKitLive

final class NSCacheImageCacheTests: XCTestCase {
    private var cache: NSCacheImageCache!

    private let url = URL(string: "https://example.com/images/1.jpg")!
    private lazy var request = ImageRequest(url: url, maxPixelSize: 256)

    override func setUp() {
        super.setUp()
        cache = NSCacheImageCache(ImageCacheConfiguration(totalCostLimit: 1024 * 1024, countLimit: 10))
    }

    override func tearDown() {
        cache = nil
        super.tearDown()
    }

    func test_insertedImage_isReturnedForTheSameRequest() {
        let image = UIImage()

        cache.insert(image, for: request)

        XCTAssertTrue(cache.image(for: request) === image)
    }

    /// The key is the whole request, not the URL: a thumbnail must never be
    /// served where the detail screen asked for the large decode.
    func test_differentPixelSize_isADifferentEntry() {
        cache.insert(UIImage(), for: request)

        XCTAssertNil(cache.image(for: ImageRequest(url: url, maxPixelSize: 1024)))
    }

    func test_removeAll_empties() {
        cache.insert(UIImage(), for: request)

        cache.removeAll()

        XCTAssertNil(cache.image(for: request))
    }

    func test_memoryWarning_empties() {
        cache.insert(UIImage(), for: request)

        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)

        XCTAssertNil(cache.image(for: request))
    }
}
