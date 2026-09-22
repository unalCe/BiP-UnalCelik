import SwiftUI
import UIKit

public enum Skeleton {
    public static let fill = UIColor.systemGray5

    public static let sweepDuration: TimeInterval = 1.1
}

public struct SkeletonBox: View {
    private let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 4) {
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
        cornerRadius: CGFloat = 4
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
