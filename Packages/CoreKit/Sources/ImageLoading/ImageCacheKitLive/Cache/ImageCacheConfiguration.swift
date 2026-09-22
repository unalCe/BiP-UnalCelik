/// Limits for the decoded-image memory cache. Cost is decoded bytes, not
/// download size.
public struct ImageCacheConfiguration: Equatable, Sendable {
    public var totalCostLimit: Int
    public var countLimit: Int

    public init(totalCostLimit: Int = 64 * 1024 * 1024, countLimit: Int = 100) {
        self.totalCostLimit = totalCostLimit
        self.countLimit = countLimit
    }
}
