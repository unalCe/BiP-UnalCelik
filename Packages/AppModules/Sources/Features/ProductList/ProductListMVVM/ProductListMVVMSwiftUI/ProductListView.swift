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
            ScrollView { ProductGridSkeleton() }
        case .loaded(let items):
            ScrollView {
                LazyVGrid(
                    columns: ProductGridMetrics.gridColumns,
                    spacing: ProductGridMetrics.gutter
                ) {
                    ForEach(items) { item in
                        Button {
                            viewModel.didSelectItem(id: item.id)
                        } label: {
                            ProductCell(item: item, imageLoader: imageLoader)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(ProductGridMetrics.gutter)
            }
        case .empty:
            ContentUnavailableView("No products", systemImage: "tray")
        case .failed(let error):
            ErrorStateView(error: error) { viewModel.retry() }
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
