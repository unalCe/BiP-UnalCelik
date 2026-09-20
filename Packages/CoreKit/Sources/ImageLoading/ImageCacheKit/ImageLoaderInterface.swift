import UIKit

/// Cache-first. Returns a decoded image already sized for the request.
public protocol ImageLoaderInterface: Sendable {
    func image(for request: ImageRequest) async throws -> UIImage
}

// TODO: take `[ImageRequest]` rather than `[URL]` — a URL alone cannot say what
// size to prepare
public protocol ImagePrefetchingInterface: Sendable {
    func prefetch(_ urls: [URL])
    func cancelPrefetch(_ urls: [URL])
}
