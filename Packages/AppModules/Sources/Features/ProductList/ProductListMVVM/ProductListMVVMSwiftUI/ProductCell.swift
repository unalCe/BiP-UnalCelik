import CommonKit
import CommonUI
import ImageCacheKit
import ProductListInterface
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
                        cornerRadius: ProductListMetrics.imageCornerRadius,
                        style: .continuous
                    )
                )

            Text(item.title)
                .font(.subheadline)
                .lineLimit(2)
                .padding(.top, ProductListMetrics.titleSpacing)

            Spacer(minLength: ProductListMetrics.priceSpacing)

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
            SkeletonBox(cornerRadius: ProductListMetrics.imageCornerRadius)
                .aspectRatio(1, contentMode: .fit)

            SkeletonLine(.subheadline, widthFraction: ProductGridMetrics.skeletonTitleWidthFraction)
                .padding(.top, ProductListMetrics.titleSpacing)

            Spacer(minLength: ProductListMetrics.priceSpacing)

            SkeletonLine(.footnote, widthFraction: ProductGridMetrics.skeletonPriceWidthFraction)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
