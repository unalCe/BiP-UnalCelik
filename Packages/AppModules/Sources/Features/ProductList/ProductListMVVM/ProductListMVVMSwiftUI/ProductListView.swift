import CommonKit
import CommonUI
import ImageCacheKit
import ProductListMVVM
import SwiftUI

public struct ProductListView: View {
    @ObservedObject private var viewModel: ProductListViewModel
    private let imageLoader: any ImageLoaderInterface

    public init(viewModel: ProductListViewModel, imageLoader: any ImageLoaderInterface) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
    }

    public var body: some View {
        content
            .navigationTitle("Products")
            .onAppear { viewModel.onAppear() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let items):
            List(items) { item in
                Button {
                    viewModel.didSelectItem(id: item.id)
                } label: {
                    ProductListRow(item: item, imageLoader: imageLoader)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        case .empty:
            ContentUnavailableView("No products", systemImage: "tray")
        case .failed(let error):
            ErrorStateView(error: error) { viewModel.retry() }
        }
    }
}

struct ProductListRow: View {
    let item: ProductDisplayModel
    let imageLoader: any ImageLoaderInterface

    var body: some View {
        HStack(spacing: 12) {
            CachedImage(url: item.imageURL, maxPointSize: 56, loader: imageLoader)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                Text(item.formattedPrice).foregroundStyle(.secondary)
            }
        }
    }
}

struct ErrorStateView: View {
    let error: ErrorDisplayModel
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(error.title).font(.headline)
            Text(error.message).font(.subheadline).foregroundStyle(.secondary)
            if error.isRetryable {
                Button("Try again", action: retry)
            }
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}
