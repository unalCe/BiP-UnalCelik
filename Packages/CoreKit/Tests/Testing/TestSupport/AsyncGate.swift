import Foundation

/// Holds async work open until the test says so.
///
/// Doubles call `wait()` where the real dependency would do its slow part; the
/// test then observes the in-between state and calls `open()`. Time is never the
/// synchronisation mechanism. A waiter whose task is cancelled returns at once,
/// so an abandoned load does not outlive its test.
public final class AsyncGate: @unchecked Sendable {
    private let lock = NSLock()
    private var isOpen = false
    private var waiters: [UUID: CheckedContinuation<Void, Never>] = [:]

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Public Funcs

    /// How many callers are currently suspended in `wait()`.
    public var waiterCount: Int { lock.withLock { waiters.count } }

    public func wait() async {
        let id = UUID()
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let resumeNow: Bool = lock.withLock {
                    // checked under the lock: a cancellation that lands before
                    // registration would otherwise find nothing to resume
                    guard !isOpen, !Task.isCancelled else { return true }
                    waiters[id] = continuation
                    return false
                }
                if resumeNow { continuation.resume() }
            }
        } onCancel: {
            lock.withLock { waiters.removeValue(forKey: id) }?.resume()
        }
    }

    /// Releases every current waiter, and every later one immediately.
    public func open() {
        let released: [CheckedContinuation<Void, Never>] = lock.withLock {
            isOpen = true
            defer { waiters.removeAll() }
            return Array(waiters.values)
        }
        released.forEach { $0.resume() }
    }
}
