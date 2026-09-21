import UIKit

enum ProductListLayout {
    static let columns = 2
    static let spacing: CGFloat = 8

    static func make() -> UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1 / CGFloat(columns)),
                heightDimension: .fractionalHeight(1)
            )
        )
        item.contentInsets = NSDirectionalEdgeInsets(
            top: spacing, leading: spacing, bottom: spacing, trailing: spacing
        )

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(240)
            ),
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: spacing, leading: spacing, bottom: spacing, trailing: spacing
        )

        return UICollectionViewCompositionalLayout(section: section)
    }

    static func itemWidth(in containerWidth: CGFloat) -> CGFloat {
        let sectionWidth = containerWidth - spacing * 2
        return sectionWidth / CGFloat(columns) - spacing * 2
    }
}
