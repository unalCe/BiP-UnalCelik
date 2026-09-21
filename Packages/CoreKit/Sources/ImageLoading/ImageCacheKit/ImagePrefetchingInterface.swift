import Foundation

public protocol ImagePrefetchingInterface: Sendable {
    func prefetch(_ requests: [ImageRequest])
    func cancelPrefetch(_ requests: [ImageRequest])
}
