import CoreGraphics
import Foundation

/// A URL plus the size it is wanted at. Both take part in the cache key, so a
/// list thumbnail and a detail image of the same product are separate entries.
public struct ImageRequest: Hashable, Sendable {
    public let url: URL
    public let maxPixelSize: Int
    public let scale: CGFloat

    public init(url: URL, maxPixelSize: Int, scale: CGFloat = 1) {
        self.url = url
        self.maxPixelSize = Self.bucketed(maxPixelSize)
        self.scale = scale
    }

    /// Rounded up to a 128px step, so near-identical layouts share one entry
    /// instead of minting one each. Powers of two would be far too coarse: a
    /// 555px cell would decode at 1024px, 3.4x the pixels it can show.
    private static func bucketed(_ size: Int) -> Int {
        let step = 128
        let clamped = min(max(size, step), 2048)
        return Int((Double(clamped) / Double(step)).rounded(.up)) * step
    }
}
