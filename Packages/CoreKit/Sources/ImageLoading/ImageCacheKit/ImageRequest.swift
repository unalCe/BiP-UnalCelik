import CoreGraphics
import Foundation

public struct ImageRequest: Hashable, Sendable {
    public let url: URL
    public let maxPixelSize: Int
    public let scale: CGFloat

    public init(url: URL, maxPixelSize: Int, scale: CGFloat = 1) {
        self.url = url
        self.maxPixelSize = Self.bucketed(maxPixelSize)
        self.scale = scale
    }

    public init(url: URL, pointSize: CGFloat, scale: CGFloat) {
        let resolved = scale > 0 ? scale : 3
        self.init(url: url, maxPixelSize: Int(ceil(pointSize * resolved)), scale: resolved)
    }

    private static func bucketed(_ size: Int) -> Int {
        let step = 128
        let clamped = min(max(size, step), 2048)
        return Int((Double(clamped) / Double(step)).rounded(.up)) * step
    }
}
