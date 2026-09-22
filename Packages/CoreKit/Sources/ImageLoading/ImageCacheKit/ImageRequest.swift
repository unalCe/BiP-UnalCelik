import CoreGraphics
import Foundation

public struct ImageRequest: Hashable, Sendable {
    public let url: URL
    public let maxPixelSize: Int
    public let scale: CGFloat

    private static let bucketStep = 128
    private static let largestBucket = 2048
    // a view with no screen yet reports scale 0; decoding for the densest
    // iPhone can only oversample, never blur
    private static let fallbackScale: CGFloat = 3

    public init(url: URL, maxPixelSize: Int, scale: CGFloat = 1) {
        self.url = url
        self.maxPixelSize = Self.bucketed(maxPixelSize)
        self.scale = scale
    }

    public init(url: URL, pointSize: CGFloat, scale: CGFloat) {
        let resolved = scale > 0 ? scale : Self.fallbackScale
        self.init(url: url, maxPixelSize: Int(ceil(pointSize * resolved)), scale: resolved)
    }

    private static func bucketed(_ size: Int) -> Int {
        let clamped = min(max(size, bucketStep), largestBucket)
        return Int((Double(clamped) / Double(bucketStep)).rounded(.up)) * bucketStep
    }
}
