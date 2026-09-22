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
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay { CachedImage(url: item.imageURL, loader: imageLoader) }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text(item.title).font(.title2.weight(.semibold))
                            Spacer(minLength: 0)
                            Text(item.formattedPrice)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .layoutPriority(1)
                        }
                        if let description = item.description {
                            Text(description).font(.body)
                        } else {
                            Text("Description unavailable.")
                                .font(.body.italic())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
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
