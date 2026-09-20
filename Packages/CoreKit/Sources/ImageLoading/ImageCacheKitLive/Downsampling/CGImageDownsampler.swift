import ImageCacheKit
import ImageIO
import UIKit

/// `nonisolated async` rather than `Task.detached`: both run off the caller's
/// actor, but only this one inherits cancellation. A detached decode would run
/// a 5 megapixel thumbnail to completion for a cell that scrolled away.
struct CGImageDownsampler: ImageDownsampling {
    func downsample(_ data: Data, maxPixelSize: Int, scale: CGFloat) async throws -> UIImage {
        try Task.checkCancellation()

        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            throw ImageLoadingError.invalidData
        }

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true,
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            throw ImageLoadingError.downsamplingFailed
        }

        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}
