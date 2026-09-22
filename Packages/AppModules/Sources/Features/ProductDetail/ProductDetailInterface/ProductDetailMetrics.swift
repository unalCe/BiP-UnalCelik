import CoreGraphics

/// The numbers every renderer of the detail screen lays out with. The layouts
/// themselves stay written per renderer.
public enum ProductDetailMetrics {
    public static let imageAspectRatio: CGFloat = 1

    /// Scaled with Dynamic Type relative to `.title2`.
    public static let titleFontSize: CGFloat = 22

    public static let horizontalInset: CGFloat = 16
    public static let imageSpacing: CGFloat = 16
    /// Between the title and the price, and between them and the description.
    public static let textSpacing: CGFloat = 12
    public static let bottomInset: CGFloat = 24
}
