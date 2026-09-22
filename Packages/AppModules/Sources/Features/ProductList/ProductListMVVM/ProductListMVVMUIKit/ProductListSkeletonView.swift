import CommonUI
import ProductListInterface
import UIKit

/// Placeholder grid for the loading state, laid out from `ProductListLayout` so
/// it lands where the real cells will.
///
/// One `CAShapeLayer` draws every placeholder and one `CAGradientLayer` sweeps
/// across all of them, masked by the same path. A screenful costs two layers
/// and one animation, and Core Animation paces it — nothing here runs per frame.
@MainActor
final class ProductListSkeletonView: UIView {
    // text rarely fills its line, so neither do the placeholders for it
    private static let titleWidthFraction: CGFloat = 0.85
    private static let priceWidthFraction: CGFloat = 0.4

    private let shapes: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = Skeleton.fill.cgColor
        return layer
    }()

    private let shimmer = ShimmerSweep()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .systemBackground
        layer.addSublayer(shapes)
        shimmer.attach(to: layer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        let path = placeholderPath(from: placeholders)
        shapes.frame = bounds
        shapes.path = path
        shimmer.layout(in: bounds, clippedTo: path)
        if !isHidden { shimmer.start() }
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
        setNeedsLayout()
    }

    var isSweeping: Bool { shimmer.isRunning }

    /// The collection view adjusts its content for the bars, so the placeholders
    /// have to start in the same place or they jump when the cells land.
    var placeholders: [Placeholder] {
        Self.placeholders(in: bounds.inset(by: safeAreaInsets))
    }

    func stop() {
        isHidden = true
        shimmer.stop()
    }

    private func placeholderPath(from placeholders: [Placeholder]) -> CGPath {
        let path = CGMutablePath()
        for placeholder in placeholders {
            path.addRoundedRect(
                in: placeholder.image,
                cornerWidth: ProductListMetrics.imageCornerRadius,
                cornerHeight: ProductListMetrics.imageCornerRadius
            )
            for text in [placeholder.title, placeholder.price] {
                path.addRoundedRect(
                    in: text, cornerWidth: Skeleton.cornerRadius, cornerHeight: Skeleton.cornerRadius
                )
            }
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

        let gutter = ProductListMetrics.gutter
        let width = ProductListMetrics.itemWidth(in: rect.width)
        let height = ProductListLayout.cellHeight(itemWidth: width)
        let titleHeight = ProductListLayout.titleFont.lineHeight
        let priceHeight = ProductListLayout.priceFont.lineHeight

        var result: [Placeholder] = []
        var y = rect.minY + gutter
        while y < rect.maxY {
            for column in 0..<ProductListMetrics.columns {
                let x = rect.minX + gutter + CGFloat(column) * (width + gutter)
                let titleY = y + width + ProductListMetrics.titleSpacing

                result.append(
                    Placeholder(
                        image: CGRect(x: x, y: y, width: width, height: width),
                        title: CGRect(
                            x: x, y: titleY, width: width * titleWidthFraction, height: titleHeight
                        ),
                        price: CGRect(
                            x: x, y: titleY + titleHeight + ProductListMetrics.priceSpacing,
                            width: width * priceWidthFraction, height: priceHeight
                        )
                    )
                )
            }
            y += height + gutter
        }
        return result
    }
}
