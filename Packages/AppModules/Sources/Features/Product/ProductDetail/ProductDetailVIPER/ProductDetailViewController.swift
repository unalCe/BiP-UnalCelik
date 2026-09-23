import AccessibilityIdentifiers
import AccessibilityKit
import CommonKit
import CommonUI
import ImageCacheKit
import LayoutKit
import ProductPresentation
import UIKit

private enum Metrics {
    static let imageAspectRatio: CGFloat = 1
    /// Scaled with Dynamic Type relative to `.title2`.
    static let titleFontSize: CGFloat = 22
    static let horizontalInset: CGFloat = 16
    static let imageSpacing: CGFloat = 16
    /// Between the title and the price, and between them and the description.
    static let textSpacing: CGFloat = 12
    static let bottomInset: CGFloat = 24
}

@MainActor
public final class ProductDetailViewController: UIViewController {
    public var presenter: ProductDetailPresenterInterface?

    // MARK: - Subviews

    private let productImageView: CachedImageView

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
            .scaledFont(for: .systemFont(ofSize: Metrics.titleFontSize, weight: .semibold))
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
        stack.spacing = Metrics.textSpacing
        return stack
    }()

    private lazy var stateView: StateContainerView = {
        let view = StateContainerView()
        view.onRetry = { [weak self] in self?.presenter?.didTapRetry() }
        return view
    }()

    // MARK: - Lifecycle

    public init(imageLoader: ImageLoaderInterface) {
        self.productImageView = CachedImageView(loader: imageLoader)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpHierarchy()
        setAccessibilityIdentifiers()
        presenter?.viewDidLoad()
    }

    // MARK: - Private Funcs

    private func setAccessibilityIdentifiers() {
        scrollView.setAccessibilityIdentifier(UIElements.ProductDetail.scrollView)
        productImageView.setAccessibilityIdentifier(UIElements.ProductDetail.image)
        titleLabel.setAccessibilityIdentifier(UIElements.ProductDetail.title)
        priceLabel.setAccessibilityIdentifier(UIElements.ProductDetail.price)
        descriptionLabel.setAccessibilityIdentifier(UIElements.ProductDetail.description)
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
                .aspectRatio(Metrics.imageAspectRatio)
        }

        contentView.addSubview(headerStack) {
            $0.below(productImageView, spacing: Metrics.imageSpacing)
                .pinHorizontally(to: contentView, insets: .horizontal(Metrics.horizontalInset))
        }

        contentView.addSubview(descriptionLabel) {
            $0.below(headerStack, spacing: Metrics.textSpacing)
                .pinHorizontally(to: contentView, insets: .horizontal(Metrics.horizontalInset))
                .bottom(to: contentView.bottomAnchor, constant: Metrics.bottomInset)
        }

        view.addSubview(stateView, pinnedToEdges: .zero)
    }
}

// MARK: - ProductDetailViewInterface

extension ProductDetailViewController: ProductDetailViewInterface {
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
            stateView.showMessage("\(error.title)\n\(error.message)", retryable: true)
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
