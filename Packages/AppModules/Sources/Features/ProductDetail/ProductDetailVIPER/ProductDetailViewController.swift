import CommonKit
import CommonUI
import ImageCacheKit
import LayoutKit
import ProductDetailInterface
import UIKit

@MainActor
public final class ProductDetailViewController: UIViewController, ProductDetailViewInterface {
    public var presenter: (any ProductDetailPresenterInterface)?

    // MARK: - Subviews

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.alwaysBounceVertical = true
        view.showsHorizontalScrollIndicator = false
        return view
    }()

    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .title2)
            .scaledFont(for: .systemFont(ofSize: ProductDetailMetrics.titleFontSize, weight: .semibold))
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .body
        label.textColor = .label
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var headerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, priceLabel])
        stack.axis = .horizontal
        stack.alignment = .firstBaseline
        stack.spacing = ProductDetailMetrics.textSpacing
        return stack
    }()

    private lazy var stateView: StateContainerView = {
        let view = StateContainerView()
        view.onRetry = { [weak self] in self?.presenter?.didTapRetry() }
        return view
    }()

    private let productImageView: CachedImageView

    public init(imageLoader: any ImageLoaderInterface) {
        self.productImageView = CachedImageView(loader: imageLoader)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpHierarchy()
        presenter?.viewDidLoad()
    }

    private func setUpHierarchy() {
        view.addSubview(scrollView, pinnedToEdges: .zero)

        scrollView.addSubview(contentView) {
            $0.pinEdges(to: scrollView.contentLayoutGuide)
                .matchWidth(of: scrollView.frameLayoutGuide)
        }

        contentView.addSubview(productImageView) {
            $0.top(to: contentView.topAnchor)
                .pinHorizontally(to: contentView)
                .aspectRatio(ProductDetailMetrics.imageAspectRatio)
        }

        contentView.addSubview(headerStack) {
            $0.below(productImageView, spacing: ProductDetailMetrics.imageSpacing)
                .pinHorizontally(to: contentView, insets: .horizontal(ProductDetailMetrics.horizontalInset))
        }

        contentView.addSubview(descriptionLabel) {
            $0.below(headerStack, spacing: ProductDetailMetrics.textSpacing)
                .pinHorizontally(to: contentView, insets: .horizontal(ProductDetailMetrics.horizontalInset))
                .bottom(to: contentView.bottomAnchor, constant: ProductDetailMetrics.bottomInset)
        }

        view.addSubview(stateView, pinnedToEdges: .zero)
    }

    public func display(_ state: ViewState<ProductDisplayModel>) {
        scrollView.isHidden = state.value == nil

        switch state {
        case .idle:
            stateView.hide()
        case .loading:
            stateView.showLoading()
        case .loaded(let item):
            stateView.hide()
            show(item)
        case .empty:
            stateView.showMessage(AppStrings.ProductDetail.emptyTitle, retryable: false)
        case .failed(let error):
            stateView.showMessage("\(error.title)\n\(error.message)", retryable: error.isRetryable)
        }
    }

    private func show(_ item: ProductDisplayModel) {
        titleLabel.text = item.title
        priceLabel.text = item.formattedPrice
        productImageView.setImage(from: item.imageURL)

        descriptionLabel.text = item.description ?? AppStrings.ProductDetail.descriptionUnavailable
        descriptionLabel.font = item.description == nil ? .italicBody : .body
        descriptionLabel.textColor = item.description == nil ? .secondaryLabel : .label
    }
}

private extension UIFont {
    static var body: UIFont { .preferredFont(forTextStyle: .body) }

    static var italicBody: UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        guard let italic = descriptor.withSymbolicTraits(.traitItalic) else { return .body }
        return UIFont(descriptor: italic, size: 0)
    }
}
