import ImageCacheKit
import UIKit

public final class MockImageLoader: ImageLoaderInterface, @unchecked Sendable {
    private let lock = NSLock()
    private var requested: [ImageRequest] = []
    private let result: Result<UIImage, Error>

    public var requestedRequests: [ImageRequest] { lock.withLock { requested } }
    public var requestedURLs: [URL] { lock.withLock { requested.map(\.url) } }

    public init(result: Result<UIImage, Error> = .success(UIImage())) {
        self.result = result
    }

    public func image(for request: ImageRequest) async throws -> UIImage {
        lock.withLock { requested.append(request) }
        return try result.get()
    }
}
