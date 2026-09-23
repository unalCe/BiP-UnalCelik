import ImageCacheKit
import Foundation

public final class MockImagePrefetcher: ImagePrefetchingInterface, @unchecked Sendable {
    private let lock = NSLock()
    private var prefetched: [ImageRequest] = []

    public var prefetchedRequests: [ImageRequest] { lock.withLock { prefetched } }

    public init() {}

    public func prefetch(_ requests: [ImageRequest]) {
        lock.withLock { prefetched.append(contentsOf: requests) }
    }

    public func cancelPrefetch(_ requests: [ImageRequest]) {
        lock.withLock { prefetched.removeAll { requests.contains($0) } }
    }
}
