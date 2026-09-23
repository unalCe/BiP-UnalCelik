import CommonUI
import UIKit

private enum Metrics {
    // text rarely fills its line, so neither do the placeholders for it
    static let titleWidthFraction: CGFloat = 0.85
    static let priceWidthFraction: CGFloat = 0.4
}

/// Placeholder grid for the loading state, laid out from `ProductListLayout` so
/// it lands where the real cells will.
///
/// One `CAShapeLayer` draws every placeholder and one `CAGradientLayer` sweeps
/// across all of them, masked by the same path. A screenful costs two layers
/// and one animation, and Core Animation paces it — nothing here runs per frame.
@MainActor
final class ProductListSkeletonView: UIView {
    struct Placeholder: Equatable {
        let image: CGRect
        let title: CGRect
        let price: CGRect
    }

    // MARK: - Subviews

    private let shapes: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = Skeleton.fill.cgColor
        return layer
    }()

    private let shimmer = ShimmerSweep()

    // MARK: - Lifecycle

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

    // MARK: - Public Funcs

    var isSweeping: Bool { shimmer.isRunning }

    /// The collection view adjusts its content for the bars, so the placeholders
    /// have to start in the same place or they jump when the cells land.
    var placeholders: [Placeholder] {
        Self.placeholders(in: bounds.inset(by: safeAreaInsets))
    }

    func start() {
        isHidden = false
        setNeedsLayout()
    }

    func stop() {
        isHidden = true
        shimmer.stop()
    }

    /// Where a cell's image, title and price will be, for as many rows as fit.
    static func placeholders(in rect: CGRect) -> [Placeholder] {
        guard rect.width > 0 else { return [] }

        let gridSpacing = ProductListLayout.gridSpacing
        let width = ProductListLayout.itemWidth(in: rect.width)
        let height = ProductListLayout.cellHeight(itemWidth: width)
        let titleHeight = ProductListLayout.titleFont.lineHeight
        let priceHeight = ProductListLayout.priceFont.lineHeight

        var result: [Placeholder] = []
        var y = rect.minY + gridSpacing
        while y < rect.maxY {
            for column in 0..<ProductListLayout.columns {
                let x = rect.minX + gridSpacing + CGFloat(column) * (width + gridSpacing)
                let titleY = y + width + ProductListLayout.titleSpacing

                result.append(
                    Placeholder(
                        image: CGRect(x: x, y: y, width: width, height: width),
                        title: CGRect(
                            x: x, y: titleY, width: width * Metrics.titleWidthFraction, height: titleHeight
                        ),
                        price: CGRect(
                            x: x, y: titleY + titleHeight + ProductListLayout.priceSpacing,
                            width: width * Metrics.priceWidthFraction, height: priceHeight
                        )
                    )
                )
            }
            y += height + gridSpacing
        }
        return result
    }

    // MARK: - Private Funcs

    private func placeholderPath(from placeholders: [Placeholder]) -> CGPath {
        let path = CGMutablePath()
        for placeholder in placeholders {
            path.addRoundedRect(
                in: placeholder.image,
                cornerWidth: ProductListLayout.imageCornerRadius,
                cornerHeight: ProductListLayout.imageCornerRadius
            )
            for text in [placeholder.title, placeholder.price] {
                path.addRoundedRect(
                    in: text, cornerWidth: Skeleton.cornerRadius, cornerHeight: Skeleton.cornerRadius
                )
            }
        }
        return path
    }
}
