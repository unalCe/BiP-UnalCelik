import CommonUI
import UIKit

/// Placeholder grid for the loading state, laid out from `ProductListLayout` so
/// it lands where the real cells will.
///
/// One `CAShapeLayer` draws every placeholder and one `CAGradientLayer` sweeps
/// across all of them, masked by the same path. A screenful costs two layers
/// and one animation, and Core Animation paces it — nothing here runs per frame.
@MainActor
final class ProductListSkeletonView: UIView {
    private enum Key {
        static let sweep = "skeleton.sweep"
    }

    private let shapes: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = Skeleton.fill.cgColor
        return layer
    }()

    private let shimmerContainer = CALayer()
    private let shimmerMask = CAShapeLayer()

    private let gradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.colors = [
            UIColor.white.withAlphaComponent(0).cgColor,
            UIColor.white.withAlphaComponent(0.38).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor,
        ]
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .systemBackground
        layer.addSublayer(shapes)
        shimmerContainer.mask = shimmerMask
        shimmerContainer.addSublayer(gradient)
        layer.addSublayer(shimmerContainer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        let path = placeholderPath(from: placeholders)
        shapes.frame = bounds
        shapes.path = path
        shimmerContainer.frame = bounds
        shimmerMask.frame = bounds
        shimmerMask.path = path

        let band = bounds.width * 0.35
        gradient.frame = CGRect(x: -band, y: 0, width: band, height: bounds.height)
        restartSweepIfNeeded()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        setNeedsLayout()
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        // cgColor does not follow the interface style on its own
        if traitCollection.hasDifferentColorAppearance(comparedTo: previous) {
            shapes.fillColor = Skeleton.fill.resolvedColor(with: traitCollection).cgColor
        }
    }

    func start() {
        isHidden = false
        restartSweepIfNeeded()
    }

    var isSweeping: Bool { gradient.animation(forKey: Key.sweep) != nil }

    /// The collection view adjusts its content for the bars, so the placeholders
    /// have to start in the same place or they jump when the cells land.
    var placeholders: [Placeholder] {
        Self.placeholders(in: bounds.inset(by: safeAreaInsets))
    }

    func stop() {
        isHidden = true
        gradient.removeAnimation(forKey: Key.sweep)
    }

    private func restartSweepIfNeeded() {
        gradient.removeAnimation(forKey: Key.sweep)
        guard !isHidden, bounds.width > 0, !UIAccessibility.isReduceMotionEnabled else { return }

        let band = gradient.bounds.width
        let sweep = CABasicAnimation(keyPath: "position.x")
        sweep.fromValue = -band / 2
        sweep.toValue = bounds.width + band / 2
        sweep.duration = Skeleton.sweepDuration
        sweep.repeatCount = .infinity
        sweep.timingFunction = CAMediaTimingFunction(name: .linear)
        gradient.add(sweep, forKey: Key.sweep)
    }

    private func placeholderPath(from placeholders: [Placeholder]) -> CGPath {
        let path = CGMutablePath()
        for placeholder in placeholders {
            path.addRoundedRect(
                in: placeholder.image,
                cornerWidth: ProductListLayout.imageCornerRadius,
                cornerHeight: ProductListLayout.imageCornerRadius
            )
            path.addRoundedRect(in: placeholder.title, cornerWidth: 4, cornerHeight: 4)
            path.addRoundedRect(in: placeholder.price, cornerWidth: 4, cornerHeight: 4)
        }
        return path
    }

    struct Placeholder: Equatable {
        let image: CGRect
        let title: CGRect
        let price: CGRect
    }

    /// Where a cell's image, title and price will be, for as many rows as fit.
    static func placeholders(in rect: CGRect) -> [Placeholder] {
        guard rect.width > 0 else { return [] }

        let gutter = ProductListLayout.gutter
        let width = ProductListLayout.itemWidth(in: rect.width)
        let height = ProductListLayout.cellHeight(itemWidth: width)
        let titleHeight = ProductListLayout.titleFont.lineHeight
        let priceHeight = ProductListLayout.priceFont.lineHeight

        var result: [Placeholder] = []
        var y = rect.minY + gutter
        while y < rect.maxY {
            for column in 0..<ProductListLayout.columns {
                let x = rect.minX + gutter + CGFloat(column) * (width + gutter)
                let titleY = y + width + ProductListLayout.titleSpacing

                result.append(
                    Placeholder(
                        image: CGRect(x: x, y: y, width: width, height: width),
                        title: CGRect(x: x, y: titleY, width: width * 0.85, height: titleHeight),
                        price: CGRect(
                            x: x, y: titleY + titleHeight + ProductListLayout.priceSpacing,
                            width: width * 0.4, height: priceHeight
                        )
                    )
                )
            }
            y += height + gutter
        }
        return result
    }
}
