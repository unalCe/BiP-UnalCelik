import ImageCacheKit
import TestSupport
import UIKit
import XCTest

@testable import ImageCacheKitLive

/// Real ImageIO decodes of an image generated in memory — the ~576 KB product
/// photos are the reason this type exists, so it is exercised for real.
final class CGImageDownsamplerTests: XCTestCase {
    private var downsampler: CGImageDownsampler!

    override func setUp() {
        super.setUp()
        downsampler = CGImageDownsampler()
    }

    override func tearDown() {
        downsampler = nil
        super.tearDown()
    }

    func test_largeImage_isDecodedNoLargerThanTheRequestedPixelSize() async throws {
        let image = try await downsampler.downsample(png(width: 1000, height: 500), maxPixelSize: 256, scale: 2)

        let cgImage = try XCTUnwrap(image.cgImage)
        XCTAssertEqual(cgImage.width, 256, "the longer side is capped")
        XCTAssertEqual(cgImage.height, 128, "the aspect ratio is kept")
        XCTAssertEqual(image.scale, 2)
    }

    func test_undecodableData_throwsRatherThanReturningAnEmptyImage() async {
        await XCTAssertThrowsErrorAsync(
            try await downsampler.downsample(Data("not an image".utf8), maxPixelSize: 256, scale: 1)
        )
    }

    func test_cancelledTask_doesNotDecode() async {
        let data = png(width: 100, height: 100)
        let downsampler = downsampler!
        let task = Task { try await downsampler.downsample(data, maxPixelSize: 256, scale: 1) }
        task.cancel()

        await XCTAssertThrowsErrorAsync(try await task.value) { error in
            XCTAssertTrue(error is CancellationError, "got \(error)")
        }
    }

    // MARK: - Helpers

    private func png(width: Int, height: Int) -> Data {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
            .pngData { context in
                UIColor.systemTeal.setFill()
                context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            }
    }
}
