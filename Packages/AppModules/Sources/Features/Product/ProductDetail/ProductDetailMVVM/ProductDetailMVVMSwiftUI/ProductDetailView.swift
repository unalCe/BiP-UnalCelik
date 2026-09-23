import AccessibilityIdentifiers
import AccessibilityKit
import CommonKit
import CommonUI
import ImageCacheKit
import ProductDetailMVVM
import ProductPresentation
import SwiftUI

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

public struct ProductDetailView: View {
    @ObservedObject private var viewModel: ProductDetailViewModel
    private let imageLoader: ImageLoaderInterface

    @ScaledMetric(relativeTo: .title2) private var titleFontSize = Metrics.titleFontSize

    // MARK: - Lifecycle

    public init(viewModel: ProductDetailViewModel,
                imageLoader: ImageLoaderInterface) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
    }

    public var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.onAppear() }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let item):
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.imageSpacing) {
                    Color.clear
                        .aspectRatio(Metrics.imageAspectRatio, contentMode: .fit)
                        .overlay { CachedImage(url: item.imageURL, loader: imageLoader) }
                        .accessibilityIdentifier(UIElements.ProductDetail.image)

                    VStack(alignment: .leading, spacing: Metrics.textSpacing) {
                        HStack(alignment: .firstTextBaseline, spacing: Metrics.textSpacing) {
                            Text(item.title).font(.system(size: titleFontSize, weight: .semibold))
                                .accessibilityIdentifier(UIElements.ProductDetail.title)
                            Spacer(minLength: 0)
                            Text(item.formattedPrice)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .layoutPriority(1)
                                .accessibilityIdentifier(UIElements.ProductDetail.price)
                        }
                        Group {
                            if let description = item.description {
                                Text(description).font(.body)
                            } else {
                                Text(AppStrings.ProductDetail.descriptionUnavailable)
                                    .font(.body.italic())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier(UIElements.ProductDetail.description)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Metrics.horizontalInset)
                    .padding(.bottom, Metrics.bottomInset)
                }
            }
            .accessibilityIdentifier(UIElements.ProductDetail.scrollView)
        case .empty:
            ContentUnavailableView(AppStrings.ProductDetail.emptyTitle, systemImage: "tray")
                .accessibilityIdentifier(UIElements.StateView.container)
        case .failed(let error):
            ErrorStateView(error: error) { viewModel.retry() }
        }
    }
}
