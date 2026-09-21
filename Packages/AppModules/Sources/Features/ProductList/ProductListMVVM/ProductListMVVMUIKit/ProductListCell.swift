import CommonKit
import CommonUI
import ImageCacheKit
import LayoutKit
import UIKit

@MainActor
public final class ProductListCell: UICollectionViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.numberOfLines = 2
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        return label
    }()

    private var productImageView: CachedImageView?

    public func configure(with item: ProductDisplayModel,
                          imageLoader: any ImageLoaderInterface) {
        titleLabel.text = item.title
        priceLabel.text = item.formattedPrice
        imageView(using: imageLoader).setImage(from: item.imageURL)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        // or a fast scroll lands the wrong image here
        productImageView?.cancel()
        productImageView?.image = nil
        titleLabel.text = nil
        priceLabel.text = nil
    }

    private func imageView(using loader: any ImageLoaderInterface) -> CachedImageView {
        if let productImageView { return productImageView }

        let imageView = CachedImageView(loader: loader)
        imageView.layer.cornerRadius = 8
        imageView.layer.cornerCurve = .continuous
        productImageView = imageView
        setUpHierarchy(with: imageView)
        return imageView
    }

    private func setUpHierarchy(with imageView: CachedImageView) {
        contentView.addSubview(imageView) {
            $0.top(to: contentView.topAnchor)
                .pinHorizontally(to: contentView)
                .aspectRatio(1)
        }

        contentView.addSubview(titleLabel) {
            $0.below(imageView, spacing: 8).pinHorizontally(to: contentView)
        }

        contentView.addSubview(priceLabel) {
            $0.below(titleLabel, spacing: 4)
                .pinHorizontally(to: contentView)
                .bottom(to: contentView.bottomAnchor)
        }
    }
}
