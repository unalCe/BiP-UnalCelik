import ImageCacheKit
import UIKit

actor InFlightRegistry {
    private var tasks: [ImageRequest: Task<UIImage, any Error>] = [:]

    func image(
        for request: ImageRequest,
        producedBy work: @escaping @Sendable () async throws -> UIImage
    ) async throws -> UIImage {
        if let existing = tasks[request] { return try await existing.value }

        let task = Task { try await work() }
        tasks[request] = task
        defer { tasks[request] = nil }
        return try await task.value
    }
}
