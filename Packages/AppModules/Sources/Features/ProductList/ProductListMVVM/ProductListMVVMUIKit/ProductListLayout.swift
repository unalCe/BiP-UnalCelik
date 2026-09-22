import ProductListInterface
import UIKit

/// The UIKit construction of `ProductListMetrics`.
enum ProductListLayout {
    static let estimatedHeight: CGFloat = 240

    // computed, not stored: a stored font would freeze at whatever the content
    // size category was when the type first loaded
    static var titleFont: UIFont { .preferredFont(forTextStyle: .subheadline) }
    static var priceFont: UIFont { .preferredFont(forTextStyle: .footnote) }

    static func make() -> UICollectionViewCompositionalLayout {
        let columns = ProductListMetrics.columns
        let gutter = ProductListMetrics.gutter

        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1 / CGFloat(columns)),
                heightDimension: .estimated(estimatedHeight)
            )
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(estimatedHeight)
            ),
            repeatingSubitem: item,
            count: columns
        )
        group.interItemSpacing = .fixed(gutter)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = gutter
        section.contentInsets = NSDirectionalEdgeInsets(
            top: gutter, leading: gutter, bottom: gutter, trailing: gutter
        )

        return UICollectionViewCompositionalLayout(section: section)
    }

    /// One image, one title line and one price line — what a cell measures to
    /// for the short names this API returns.
    static func cellHeight(itemWidth: CGFloat) -> CGFloat {
        itemWidth
            + ProductListMetrics.titleSpacing + titleFont.lineHeight
            + ProductListMetrics.priceSpacing + priceFont.lineHeight
    }
}
