import CommonKit
import CommonUI
import ImageCacheKit
import ProductListMVVM
import SwiftUI

public struct ProductListView: View {
    @ObservedObject private var viewModel: ProductListViewModel
    private let imageLoader: ImageLoaderInterface

    public init(viewModel: ProductListViewModel, imageLoader: ImageLoaderInterface) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
    }

    public var body: some View {
        content
            .navigationTitle(AppStrings.ProductList.title)
            .onAppear { viewModel.onAppear() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ScrollView { ProductGridSkeleton() }
        case .loaded(let items):
            ScrollView {
                ProductGrid {
                    ForEach(items) { item in
                        Button {
                            viewModel.didSelectItem(id: item.id)
                        } label: {
                            ProductCell(item: item, imageLoader: imageLoader)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        case .empty:
            ContentUnavailableView(AppStrings.ProductList.emptyTitle, systemImage: "tray")
        case .failed(let error):
            ErrorStateView(error: error) { viewModel.retry() }
        }
    }
}
