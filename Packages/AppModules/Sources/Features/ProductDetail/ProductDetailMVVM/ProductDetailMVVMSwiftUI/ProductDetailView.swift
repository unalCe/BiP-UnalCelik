import CommonKit
import CommonUI
import ImageCacheKit
import ProductDetailInterface
import ProductDetailMVVM
import SwiftUI

public struct ProductDetailView: View {
    @ObservedObject private var viewModel: ProductDetailViewModel
    private let imageLoader: any ImageLoaderInterface

    @ScaledMetric(relativeTo: .title2) private var titleFontSize = ProductDetailMetrics.titleFontSize

    public init(viewModel: ProductDetailViewModel,
                imageLoader: any ImageLoaderInterface) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
    }

    public var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { viewModel.onAppear() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let item):
            ScrollView {
                VStack(alignment: .leading, spacing: ProductDetailMetrics.imageSpacing) {
                    Color.clear
                        .aspectRatio(ProductDetailMetrics.imageAspectRatio, contentMode: .fit)
                        .overlay { CachedImage(url: item.imageURL, loader: imageLoader) }

                    VStack(alignment: .leading, spacing: ProductDetailMetrics.textSpacing) {
                        HStack(alignment: .firstTextBaseline, spacing: ProductDetailMetrics.textSpacing) {
                            Text(item.title).font(.system(size: titleFontSize, weight: .semibold))
                            Spacer(minLength: 0)
                            Text(item.formattedPrice)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .layoutPriority(1)
                        }
                        if let description = item.description {
                            Text(description).font(.body)
                        } else {
                            Text(AppStrings.ProductDetail.descriptionUnavailable)
                                .font(.body.italic())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, ProductDetailMetrics.horizontalInset)
                    .padding(.bottom, ProductDetailMetrics.bottomInset)
                }
            }
        case .empty:
            ContentUnavailableView(AppStrings.ProductDetail.emptyTitle, systemImage: "tray")
        case .failed(let error):
            ErrorStateView(error: error) { viewModel.retry() }
        }
    }
}
