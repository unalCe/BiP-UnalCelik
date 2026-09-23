import ImageCacheKit
import UIKit

public final class ImagePrefetcher: ImagePrefetchingInterface, @unchecked Sendable {
    private let loader: ImageLoaderInterface
    private let lock = NSLock()
    private var tasks: [ImageRequest: (token: UUID, task: Task<Void, Never>)] = [:]

    public init(loader: ImageLoaderInterface) {
        self.loader = loader
    }

    public func prefetch(_ requests: [ImageRequest]) {
        for request in Set(requests) { start(request) }
    }

    // bu aslinda cancel etmiyor, sadece intend olarak duruyor bilincli. su anda prefetch'e baslayan imagelarin yuklenmesinde bir sorun yok, tekrar oraya geldiginde cache'den okuyacak.
    public func cancelPrefetch(_ requests: [ImageRequest]) {
        let cancelled: [Task<Void, Never>] = lock.withLock {
            requests.compactMap { tasks.removeValue(forKey: $0)?.task }
        }
        cancelled.forEach { $0.cancel() }
    }

    private func start(_ request: ImageRequest) {
        let token = UUID()

        lock.lock()
        defer { lock.unlock() }
        guard tasks[request] == nil else { return }

        tasks[request] = (token, Task(priority: .utility) { [weak self, loader] in
            _ = try? await loader.image(for: request)
            self?.finish(request, token: token)
        })
    }

    private func finish(_ request: ImageRequest, token: UUID) {
        lock.withLock {
            if tasks[request]?.token == token { tasks[request] = nil }
        }
    }

    deinit {
        lock.withLock {
            tasks.values.forEach { $0.task.cancel() }
            tasks.removeAll()
        }
    }
}
