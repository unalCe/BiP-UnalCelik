import LayoutKit
import UIKit

// TODO: real layout
@MainActor
public final class StateContainerView: UIView {
    private let label = UILabel()
    private let retryButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .large)

    public var onRetry: (() -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUpHierarchy()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setUpHierarchy() {
        label.numberOfLines = 0
        label.textAlignment = .center
        retryButton.setTitle("Try again", for: .normal)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [spinner, label, retryButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center

        addSubview(stack, centeredIn: nil)
        stack.layout.leading(to: leadingAnchor, constant: 24, relation: .greaterThanOrEqual)
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
