import SwiftUI
import UIKit

public enum Skeleton {
    public static let fill = UIColor.systemGray5

    public static let sweepDuration: TimeInterval = 1.1

    /// A fraction of the host's width, not points.
    public static let sweepBandWidth: CGFloat = 0.35

    public static let highlightOpacity: CGFloat = 0.38

    public static let cornerRadius: CGFloat = 4
}

enum ImagePlaceholder {
    static let failureSymbol = "photo.badge.exclamationmark"
}

public struct SkeletonBox: View {
    private let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = Skeleton.cornerRadius) {
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color(uiColor: Skeleton.fill))
    }
}

/// A placeholder exactly as tall as `lines` of `style`, so swapping in the real
/// text moves nothing and the height still tracks Dynamic Type.
public struct SkeletonLine: View {
    private let style: Font.TextStyle
    private let lines: Int
    private let widthFraction: CGFloat
    private let cornerRadius: CGFloat

    public init(
        _ style: Font.TextStyle,
        lines: Int = 1,
        widthFraction: CGFloat = 1,
        cornerRadius: CGFloat = Skeleton.cornerRadius
    ) {
        self.style = style
        self.lines = lines
        self.widthFraction = widthFraction
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Text(verbatim: String(repeating: "\n", count: max(lines - 1, 0)) + " ")
            .font(.system(style))
            .hidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    SkeletonBox(cornerRadius: cornerRadius)
                        .frame(width: proxy.size.width * widthFraction)
                }
            }
    }
}
