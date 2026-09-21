import ImageCacheKit
import UIKit

actor InFlightRegistry {
    private var tasks: [ImageRequest: Task<UIImage, any Error>] = [:]

    /// `joined` is true when the caller rode on a load already in flight —
    /// typically a prefetch the cell caught up with before it finished.
    func image(
        for request: ImageRequest,
        producedBy work: @escaping @Sendable () async throws -> UIImage
    ) async throws -> (image: UIImage, joined: Bool) {
        if let existing = tasks[request] { return (try await existing.value, true) }

        let task = Task { try await work() }
        tasks[request] = task
        defer { tasks[request] = nil }
        return (try await task.value, false)
    }
}
