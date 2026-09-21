import Foundation

public enum ImageLoadingError: Error, Sendable {
    case invalidData
    case downsamplingFailed
}
