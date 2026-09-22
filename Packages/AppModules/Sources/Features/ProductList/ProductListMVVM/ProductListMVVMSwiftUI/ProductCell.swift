import CommonKit
import CommonUI
import ImageCacheKit
import SwiftUI

struct ProductCell: View {
    let item: ProductDisplayModel
    let imageLoader: any ImageLoaderInterface

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay { CachedImage(url: item.imageURL, loader: imageLoader) }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: ProductGridMetrics.imageCornerRadius,
                        style: .continuous
                    )
                )

            Text(item.title)
                .font(.subheadline)
                .lineLimit(2)
                .padding(.top, ProductGridMetrics.titleSpacing)

            Spacer(minLength: ProductGridMetrics.priceSpacing)

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
            SkeletonBox(cornerRadius: ProductGridMetrics.imageCornerRadius)
                .aspectRatio(1, contentMode: .fit)

            SkeletonLine(.subheadline, widthFraction: 0.85)
                .padding(.top, ProductGridMetrics.titleSpacing)

            Spacer(minLength: ProductGridMetrics.priceSpacing)

            SkeletonLine(.footnote, widthFraction: 0.4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
