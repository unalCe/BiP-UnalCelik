import Foundation
import ImageCacheKit

public final class MockImageLoader: ImageLoaderInterface, ImagePrefetchingInterface, @unchecked Sendable {
    private let lock = NSLock()
    private var requested: [URL] = []
    private var prefetched: [URL] = []
    private let result: Result<Data, any Error>

    public var requestedURLs: [URL] { lock.withLock { requested } }
    public var prefetchedURLs: [URL] { lock.withLock { prefetched } }

    public init(result: Result<Data, any Error> = .success(Data())) {
        self.result = result
    }

    public func data(for url: URL) async throws -> Data {
        lock.withLock { requested.append(url) }
        return try result.get()
    }

    public func prefetch(_ urls: [URL]) {
        lock.withLock { prefetched.append(contentsOf: urls) }
    }

    public func cancelPrefetch(_ urls: [URL]) {
        lock.withLock { prefetched.removeAll { urls.contains($0) } }
    }
}

public actor MockImageCache: ImageCacheInterface {
    private var storage: [URL: Data]
    public private(set) var storeCount = 0

    public init(seed: [URL: Data] = [:]) { self.storage = seed }

    public func data(for url: URL) async -> Data? { storage[url] }

    public func store(_ data: Data, for url: URL) async {
        storeCount += 1
        storage[url] = data
    }

    public func removeAll() async { storage.removeAll() }
}
