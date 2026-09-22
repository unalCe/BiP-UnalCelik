import UIKit

enum ProductListLayout {
    static let columns = 2
    static let gutter: CGFloat = 16
    static let estimatedHeight: CGFloat = 240

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
        group.interItemSpacing = .fixed(gutter)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = gutter
        section.contentInsets = NSDirectionalEdgeInsets(
            top: gutter, leading: gutter, bottom: gutter, trailing: gutter
        )

        return UICollectionViewCompositionalLayout(section: section)
    }

    static func itemWidth(in containerWidth: CGFloat) -> CGFloat {
        (containerWidth - gutter * CGFloat(columns + 1)) / CGFloat(columns)
    }
}
