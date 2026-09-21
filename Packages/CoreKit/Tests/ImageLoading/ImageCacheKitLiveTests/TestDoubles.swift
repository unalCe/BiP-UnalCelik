import ImageCacheKit
import UIKit
@testable import ImageCacheKitLive

// MARK: - Doubles

/// The cache and downsampler are internal to ImageCacheKitLive, so their
/// doubles live here rather than in ImageCacheKitMocks.
final class StubImageCache: DecodedImageCaching, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [ImageRequest: UIImage]
    private var inserts = 0

    var insertCount: Int { lock.withLock { inserts } }

    init(seed: [ImageRequest: UIImage] = [:]) { self.storage = seed }

    func image(for request: ImageRequest) -> UIImage? {
        lock.withLock { storage[request] }
    }

    func insert(_ image: UIImage, for request: ImageRequest) {
        lock.withLock {
            inserts += 1
            storage[request] = image
        }
    }

    func removeAll() { lock.withLock { storage.removeAll() } }
}

final class StubDownsampler: ImageDownsampling, @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0
    private let delay: Duration?

    var callCount: Int { lock.withLock { calls } }

    /// A delay holds the pipeline open, so a second concurrent request arrives
    /// while the first is still in flight. Without it the first call completes
    /// and populates the cache before the second even starts, and a coalescing
    /// test passes whether or not coalescing exists.
    init(delay: Duration? = nil) { self.delay = delay }

    func downsample(_ data: Data, maxPixelSize: Int, scale: CGFloat) async throws -> UIImage {
        lock.withLock { calls += 1 }
        if let delay { try? await Task.sleep(for: delay) }
        return UIImage()
    }
}
