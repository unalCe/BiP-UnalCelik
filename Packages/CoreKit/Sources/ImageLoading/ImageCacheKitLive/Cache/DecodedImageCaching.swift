import ImageCacheKit
import UIKit

protocol DecodedImageCaching: Sendable {
    func image(for request: ImageRequest) -> UIImage?
    func insert(_ image: UIImage, for request: ImageRequest)
    func removeAll()
}
