import CommonKit
import LayoutKit
import UIKit

/// Shared by the UIKit container and the SwiftUI error view, so a failure
/// looks the same in every stack.
enum StateLayout {
    static let spacing: CGFloat = 12
    static let minimumHorizontalInset: CGFloat = 24
}

// TODO: real layout
@MainActor
public final class StateContainerView: UIView {
    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    // lazy: the closure needs self for the target-action
    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(AppStrings.Common.tryAgain, for: .normal)
        button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        return button
    }()

    private let spinner = UIActivityIndicatorView(style: .large)

    private lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [spinner, label, retryButton])
        stack.axis = .vertical
        stack.spacing = StateLayout.spacing
        stack.alignment = .center
        return stack
    }()

    public var onRetry: (() -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUpHierarchy()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setUpHierarchy() {
        addSubview(stack, centeredIn: nil)
        stack.layout.leading(to: leadingAnchor, constant: StateLayout.minimumHorizontalInset, relation: .greaterThanOrEqual)
    }

    public func showLoading() {
        isHidden = false
        spinner.startAnimating()
        label.isHidden = true
        retryButton.isHidden = true
    }

    public func showMessage(_ text: String, retryable: Bool) {
        isHidden = false
        spinner.stopAnimating()
        label.isHidden = false
        label.text = text
        retryButton.isHidden = !retryable
    }

    public func hide() {
        isHidden = true
        spinner.stopAnimating()
    }

    @objc private func retryTapped() { onRetry?() }
}
