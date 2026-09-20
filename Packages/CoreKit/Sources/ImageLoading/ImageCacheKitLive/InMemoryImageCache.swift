import Foundation
import ImageCacheKit

// TODO: maybe think about NSCache with cost accounting, a disk tier,
// eviction, memory-warning handling
public actor InMemoryImageCache: ImageCacheInterface {
    private var storage: [URL: Data] = [:]

    public init() {}

    public func data(for url: URL) async -> Data? { storage[url] }
    public func store(_ data: Data, for url: URL) async { storage[url] = data }
    public func removeAll() async { storage.removeAll() }
}
