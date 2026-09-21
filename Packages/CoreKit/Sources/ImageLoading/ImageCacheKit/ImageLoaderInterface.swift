import UIKit

/// Cache-first. Returns a decoded image already sized for the request.
public protocol ImageLoaderInterface: Sendable {
    func image(for request: ImageRequest) async throws -> UIImage
}
