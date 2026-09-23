import CommonKit
import CommonUI
import ImageCacheKit
import LayoutKit
import ProductPresentation
import UIKit

@MainActor
public final class ProductListCell: UICollectionViewCell {
    private var productImageView: CachedImageView?

    // MARK: - Subviews

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = ProductListLayout.titleFont
        label.numberOfLines = 2
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = ProductListLayout.priceFont
        label.textColor = .secondaryLabel
        return label
    }()

    // MARK: - Lifecycle

    public override func prepareForReuse() {
        super.prepareForReuse()
        // or a fast scroll lands the wrong image here
        productImageView?.cancel()
        productImageView?.image = nil
        titleLabel.text = nil
        priceLabel.text = nil
    }

    // MARK: - Public Funcs

    public func configure(with item: ProductDisplayModel,
                          imageLoader: ImageLoaderInterface) {
        titleLabel.text = item.title
        priceLabel.text = item.formattedPrice
        imageView(using: imageLoader).setImage(from: item.imageURL)
    }

    // MARK: - Private Funcs

    private func imageView(using loader: ImageLoaderInterface) -> CachedImageView {
        if let productImageView { return productImageView }

        let imageView = CachedImageView(loader: loader)
        imageView.layer.cornerRadius = ProductListLayout.imageCornerRadius
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
            $0.below(imageView, spacing: ProductListLayout.titleSpacing)
                .pinHorizontally(to: contentView)
        }

        contentView.addSubview(priceLabel) {
            $0.below(titleLabel, spacing: ProductListLayout.priceSpacing)
                .pinHorizontally(to: contentView)
                .bottom(to: contentView.bottomAnchor)
        }
    }
}
