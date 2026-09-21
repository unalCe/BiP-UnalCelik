import ImageCacheKit
import PerformanceKit
import UIKit

/// Each prefetch is traced as `image.prefetch`. `.cancelled` means the list
/// withdrew interest, not that the download stopped (see `cancelPrefetch`), so
/// a high cancelled count is over-eager prefetching, not wasted bandwidth.
public final class ImagePrefetcher: ImagePrefetchingInterface, @unchecked Sendable {
    private let loader: any ImageLoaderInterface
    private let tracer: any PerformanceTracing
    private let lock = NSLock()
    private var tasks: [ImageRequest: (token: UUID, task: Task<Void, Never>)] = [:]

    public init(loader: any ImageLoaderInterface,
                tracer: any PerformanceTracing = NoopPerformanceTracer()) {
        self.loader = loader
        self.tracer = tracer
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

        let interval = tracer.begin(.imagePrefetch)
        tasks[request] = (token, Task(priority: .utility) { [weak self, loader, tracer] in
            let loaded = (try? await loader.image(for: request)) != nil
            let outcome: PerformanceOutcome = Task.isCancelled ? .cancelled : (loaded ? .completed : .failed)
            tracer.end(interval, outcome: outcome)
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
