import CommonKit
import LayoutKit
import UIKit

private enum Metrics {
    static let spacing: CGFloat = 16
    static let horizontalInset: CGFloat = 24
    static let topInset: CGFloat = 24
}

/// Switches the running architecture. It only picks: restarting is the
/// caller's job, handed in as `onRestart`.
@MainActor
public final class FlowPickerViewController: UIViewController {
    private let currentStyle: FlowStyle
    private let onRestart: (FlowStyle) -> Void

    private var selection: FlowSelection {
        didSet { renderSelection() }
    }

    // MARK: - Subviews

    private let currentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var architectureControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ArchitectureStyle.allCases.map(\.title))
        control.addTarget(self,
                          action: #selector(architectureChanged),
                          for: .valueChanged)
        return control
    }()

    private lazy var frameworkControl: UISegmentedControl = {
        let control = UISegmentedControl(items: UIFramework.allCases.map(\.title))
        control.addTarget(self,
                          action: #selector(frameworkChanged),
                          for: .valueChanged)
        return control
    }()

    private let lockLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var restartButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = .filled()
        button.addTarget(self,
                         action: #selector(restartTapped),
                         for: .touchUpInside)
        return button
    }()

    private lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            currentLabel,
            architectureControl,
            frameworkControl,
            lockLabel,
            restartButton,
        ])
        stack.axis = .vertical
        stack.spacing = Metrics.spacing
        return stack
    }()

    // MARK: - Lifecycle

    public init(currentStyle: FlowStyle,
                onRestart: @escaping (FlowStyle) -> Void) {
        self.currentStyle = currentStyle
        self.onRestart = onRestart
        self.selection = FlowSelection(style: currentStyle)
        super.init(nibName: nil, bundle: nil)
        title = AppStrings.FlowPicker.title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
        )
        setUpHierarchy()
        currentLabel.text = AppStrings.FlowPicker.current(currentStyle.title)
        renderSelection()
    }

    // MARK: - Private Funcs

    private func setUpHierarchy() {
        view.addSubview(stack) {
            $0.top(to: view.safeAreaLayoutGuide.topAnchor, constant: Metrics.topInset)
                .pinHorizontally(to: view.safeAreaLayoutGuide, insets: .horizontal(Metrics.horizontalInset))
        }
    }

    private func renderSelection() {
        architectureControl.selectedSegmentIndex =
            ArchitectureStyle.allCases.firstIndex(of: selection.architecture) ?? 0
        frameworkControl.selectedSegmentIndex =
            UIFramework.allCases.firstIndex(of: selection.uiFramework) ?? 0

        frameworkControl.isEnabled = selection.isUIFrameworkSelectable
        lockLabel.text = selection.lockReason
        lockLabel.isHidden = selection.lockReason == nil
        restartButton.setTitle(AppStrings.FlowPicker.restart(selection.style.title), for: .normal)
        restartButton.isEnabled = selection.style != currentStyle
    }

    @objc private func architectureChanged() {
        selection.select(ArchitectureStyle.allCases[architectureControl.selectedSegmentIndex])
    }

    @objc private func frameworkChanged() {
        selection.select(UIFramework.allCases[frameworkControl.selectedSegmentIndex])
    }

    @objc private func restartTapped() {
        onRestart(selection.style)
    }
}
