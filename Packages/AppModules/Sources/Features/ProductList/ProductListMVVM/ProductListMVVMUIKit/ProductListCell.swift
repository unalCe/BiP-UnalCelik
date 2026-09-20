import CommonKit
import CommonUI
import UIKit

/// TODO: layout
@MainActor
public final class ProductListCell: UICollectionViewCell {
    public static let reuseIdentifier = "ProductListCell"

    private var cachedImageView: CachedImageView?

    public func configure(with item: ProductDisplayModel, imageView: CachedImageView) {
        cachedImageView = imageView
        imageView.setImage(from: item.imageURL)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        // or a fast scroll lands the wrong image here
        cachedImageView?.cancel()
    }
}
