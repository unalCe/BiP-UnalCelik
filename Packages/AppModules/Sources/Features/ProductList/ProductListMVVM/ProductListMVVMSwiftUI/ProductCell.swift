import CommonKit
import CommonUI
import ImageCacheKit
import SwiftUI

private enum Metrics {
    static let imageCornerRadius: CGFloat = 8
    static let titleSpacing: CGFloat = 8
    static let priceSpacing: CGFloat = 4

    // text rarely fills its line, so neither do the placeholders for it
    static let skeletonTitleWidthFraction: CGFloat = 0.85
    static let skeletonPriceWidthFraction: CGFloat = 0.4
}

struct ProductCell: View {
    let item: ProductDisplayModel
    let imageLoader: ImageLoaderInterface

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay { CachedImage(url: item.imageURL, loader: imageLoader) }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: Metrics.imageCornerRadius,
                        style: .continuous
                    )
                )

            Text(item.title)
                .font(.subheadline)
                .lineLimit(2)
                .padding(.top, Metrics.titleSpacing)

            Spacer(minLength: Metrics.priceSpacing)

            Text(item.formattedPrice)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The same stack with the same spacings, so the swap to real content moves
/// nothing.
struct ProductCellSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonBox(cornerRadius: Metrics.imageCornerRadius)
                .aspectRatio(1, contentMode: .fit)

            SkeletonLine(.subheadline, widthFraction: Metrics.skeletonTitleWidthFraction)
                .padding(.top, Metrics.titleSpacing)

            Spacer(minLength: Metrics.priceSpacing)

            SkeletonLine(.footnote, widthFraction: Metrics.skeletonPriceWidthFraction)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
