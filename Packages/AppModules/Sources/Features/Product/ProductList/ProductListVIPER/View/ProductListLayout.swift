import UIKit

enum ProductListLayout {
    static let columns = 2
    /// Gap between cells, and the padding around the whole grid.
    static let gridSpacing: CGFloat = 16
    static let estimatedHeight: CGFloat = 240

    static let imageCornerRadius: CGFloat = 8
    static let titleSpacing: CGFloat = 8
    static let priceSpacing: CGFloat = 4

    // computed, not stored: a stored font would freeze at whatever the content
    // size category was when the type first loaded
    static var titleFont: UIFont { .preferredFont(forTextStyle: .subheadline) }
    static var priceFont: UIFont { .preferredFont(forTextStyle: .footnote) }

    static func make() -> UICollectionViewCompositionalLayout {
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
        group.interItemSpacing = .fixed(gridSpacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = gridSpacing
        section.contentInsets = NSDirectionalEdgeInsets(
            top: gridSpacing, leading: gridSpacing, bottom: gridSpacing, trailing: gridSpacing
        )

        return UICollectionViewCompositionalLayout(section: section)
    }

    /// The grid spacing also pads the outer edges, so a row has one more
    /// spacing than it has columns.
    static func itemWidth(in containerWidth: CGFloat) -> CGFloat {
        (containerWidth - gridSpacing * CGFloat(columns + 1)) / CGFloat(columns)
    }

    /// One image, one title line and one price line — what a cell measures to
    /// for the short names this API returns.
    static func cellHeight(itemWidth: CGFloat) -> CGFloat {
        itemWidth + titleSpacing + titleFont.lineHeight + priceSpacing + priceFont.lineHeight
    }
}
