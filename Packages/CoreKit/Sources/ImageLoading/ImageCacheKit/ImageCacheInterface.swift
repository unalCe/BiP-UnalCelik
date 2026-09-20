import Foundation

public protocol ImageCacheInterface: Sendable {
    func data(for url: URL) async -> Data?
    func store(_ data: Data, for url: URL) async
    func removeAll() async
}

/// Cache-first.
public protocol ImageLoaderInterface: Sendable {
    func data(for url: URL) async throws -> Data
}

// TODO: maybe think about priority queues, in-flight de-duplication, a
// concurrency ceiling
public protocol ImagePrefetchingInterface: Sendable {
    func prefetch(_ urls: [URL])
    func cancelPrefetch(_ urls: [URL])
}
