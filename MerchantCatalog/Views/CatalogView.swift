import SwiftUI

struct CatalogView: View {

    // MARK: - Public Combine/Wrapped Properties

    @Bindable private(set) var viewModel: CatalogViewModel

    // MARK: - Public Computed Properties

    var body: some View {
        VStack(spacing: 0) {
            CatalogSearchField(
                text: $viewModel.searchText,
                onClear: viewModel.clearSearch
            )

            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("Loading products…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .loaded:
                    CatalogProductList(
                        products: viewModel.filteredProducts,
                        refreshError: viewModel.refreshError,
                        isRefreshing: viewModel.isRefreshing,
                        onClear: viewModel.clearSearch,
                        onSelect: viewModel.didSelect,
                        onProductAppear: viewModel.loadImage(for:)
                    )
                    .refreshable { await viewModel.refreshProducts() }

                case .empty:
                    ContentUnavailableView {
                        Label("No products", systemImage: "shippingbox")
                    } description: {
                        Text("The catalog is currently empty.")
                    } actions: {
                        Button("Reload Catalog", action: viewModel.loadProducts)
                    }

                case .failed(let message):
                    ContentUnavailableView {
                        Label("Couldn’t load products", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Retry", action: viewModel.loadProducts)
                    }
                }
            }
        }
    }

    // MARK: - Object Lifecycle

    init(viewModel: CatalogViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - Private Types

private struct CatalogSearchField: View {

    // MARK: - Public Combine/Wrapped Properties

    @Binding var text: String

    // MARK: - Public Properties

    let onClear: () -> Void

    // MARK: - Public Computed Properties

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.secondary)

            TextField("Search products or SKU", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .accessibilityLabel("Search products by name or SKU")

            if !text.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private struct CatalogEmptySearchResults: View {

    // MARK: - Public Properties

    let onClear: () -> Void

    // MARK: - Public Computed Properties

    var body: some View {
        ContentUnavailableView {
            Label("No matching products", systemImage: "magnifyingglass")
        } description: {
            Text("Try another product name or SKU.")
        } actions: {
            Button("Clear Search", action: onClear)
                .buttonStyle(.bordered)
        }
    }
}

private struct CatalogProductList: View {

    // MARK: - Public Properties

    let products: [Product]
    let refreshError: String?
    let isRefreshing: Bool
    let onClear: () -> Void
    let onSelect: (Product) -> Void
    let onProductAppear: (Product) -> Void

    // MARK: - Public Computed Properties

    var body: some View {
        List {
            if let refreshError {
                CatalogRefreshFailureRow(message: refreshError)
            }
            if products.isEmpty {
                CatalogEmptySearchResults(onClear: onClear)
                    .listRowSeparator(.hidden)
            }
            ForEach(products) { product in
                ProductRow(product: product) {
                    onSelect(product)
                }
                .disabled(isRefreshing)
                .opacity(isRefreshing ? 0.5 : 1)
                .task(id: ObjectIdentifier(product)) {
                    onProductAppear(product)
                }
            }
        }
        .listStyle(.plain)
    }
}

private struct CatalogRefreshFailureRow: View {

    // MARK: - Public Properties

    let message: String

    // MARK: - Public Computed Properties

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Couldn’t refresh catalog", systemImage: "exclamationmark.triangle")
                .font(.subheadline.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
            Text("Pull down to try again.")
                .font(.caption)
                .foregroundStyle(Color.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct ProductRow: View {

    // MARK: - Public Properties

    let product: Product
    let onSelect: () -> Void

    // MARK: - Public Computed Properties

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                ProductImageView(imageState: product.imageState, height: 68, contentMode: .fill)
                    .frame(width: 68)

                VStack(alignment: .leading, spacing: 6) {
                    Text(product.title)
                        .font(.headline)
                    Text("SKU: \(product.sku)")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                    Text(product.price, format: .currency(code: "USD"))
                        .font(.subheadline)
                    Text(product.stock == 0 ? "Out of stock" : "\(product.stock) in stock")
                        .font(.caption)
                        .foregroundStyle(product.stock == 0 ? Color.red : Color.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
