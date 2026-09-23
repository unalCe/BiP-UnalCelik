import AccessibilityIdentifiers
import AccessibilityKit
import CommonKit
import CommonUI
import ImageCacheKit
import ProductListMVVM
import ProductPresentation
import SwiftUI

public struct ProductListView: View {
    @ObservedObject private var viewModel: ProductListViewModel
    private let imageLoader: ImageLoaderInterface

    // MARK: - Lifecycle

    public init(viewModel: ProductListViewModel, imageLoader: ImageLoaderInterface) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
    }

    public var body: some View {
        content
            .navigationTitle(AppStrings.ProductList.title)
            .onAppear { viewModel.onAppear() }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ScrollView { ProductGridSkeleton() }
                .accessibilityIdentifier(UIElements.ProductList.skeleton)
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
                        .accessibilityIdentifier(UIElements.ProductList.cell, suffix: item.id)
                    }
                }
            }
            .accessibilityIdentifier(UIElements.ProductList.collection)
        case .empty:
            ContentUnavailableView(AppStrings.ProductList.emptyTitle, systemImage: "tray")
                .accessibilityIdentifier(UIElements.StateView.container)
        case .failed(let error):
            ErrorStateView(error: error) { viewModel.retry() }
        }
    }
}
