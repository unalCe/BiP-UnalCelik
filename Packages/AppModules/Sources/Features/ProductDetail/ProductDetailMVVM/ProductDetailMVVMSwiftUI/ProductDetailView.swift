import CommonKit
import CommonUI
import ImageCacheKit
import ProductDetailMVVM
import SwiftUI

public struct ProductDetailView: View {
    @ObservedObject private var viewModel: ProductDetailViewModel
    private let imageLoader: any ImageLoaderInterface

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
                VStack(alignment: .leading, spacing: 16) {
                    CachedImage(url: item.imageURL, loader: imageLoader)
                        .frame(maxWidth: .infinity)
                        .frame(height: 280)
                        .clipped()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title).font(.title2.weight(.semibold))
                        Text(item.formattedPrice).font(.headline).foregroundStyle(.secondary)
                        if let description = item.description {
                            Text(description).font(.body)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
            }
            .navigationTitle(item.title)
        case .empty:
            ContentUnavailableView("Not available", systemImage: "tray")
        case .failed(let error):
            VStack(spacing: 12) {
                Text(error.title).font(.headline)
                Text(error.message).font(.subheadline).foregroundStyle(.secondary)
                if error.isRetryable {
                    Button("Try again") { viewModel.retry() }
                }
            }
            .multilineTextAlignment(.center)
            .padding()
        }
    }
}
