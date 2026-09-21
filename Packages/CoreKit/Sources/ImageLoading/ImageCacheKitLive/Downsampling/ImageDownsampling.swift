import ImageCacheKit
import UIKit

protocol ImageDownsampling: Sendable {
    func downsample(_ data: Data, maxPixelSize: Int, scale: CGFloat) async throws -> UIImage
}
