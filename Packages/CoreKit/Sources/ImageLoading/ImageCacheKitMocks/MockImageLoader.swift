import ImageCacheKit
import UIKit

public final class MockImageLoader: ImageLoaderInterface, ImagePrefetchingInterface, @unchecked Sendable {
    private let lock = NSLock()
    private var requested: [ImageRequest] = []
    private var prefetched: [URL] = []
    private let result: Result<UIImage, any Error>

    public var requestedRequests: [ImageRequest] { lock.withLock { requested } }
    public var requestedURLs: [URL] { lock.withLock { requested.map(\.url) } }
    public var prefetchedURLs: [URL] { lock.withLock { prefetched } }

    public init(result: Result<UIImage, any Error> = .success(UIImage())) {
        self.result = result
    }

    public func image(for request: ImageRequest) async throws -> UIImage {
        lock.withLock { requested.append(request) }
        return try result.get()
    }

    public func prefetch(_ urls: [URL]) {
        lock.withLock { prefetched.append(contentsOf: urls) }
    }

    public func cancelPrefetch(_ urls: [URL]) {
        lock.withLock { prefetched.removeAll { urls.contains($0) } }
    }
}
