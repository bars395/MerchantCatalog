import Combine
import Foundation
import Observation

// MARK: - Types

enum CatalogState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case failed(String)
}

@Observable
@MainActor
final class CatalogViewModel {

    // MARK: - Public Properties

    private(set) var products: [Product] = []
    private(set) var filteredProducts: [Product] = []
    private(set) var state: CatalogState = .idle
    private(set) var refreshError: String?
    private(set) var isRefreshing = false

    var searchText = "" {
        didSet {
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            searchSubject.send(query)
        }
    }

    // MARK: - Private Combine/Wrapped Properties

    private let searchSubject = PassthroughSubject<String, Never>()
    @ObservationIgnored private var searchCancellable: AnyCancellable?

    // MARK: - Private Properties

    private let productsService: ProductsServiceProtocol
    private let imageService: ImageServiceProtocol
    private let onProductSelected: @MainActor (Product) -> Void

    // MARK: - Object Lifecycle

    init(
        productsService: ProductsServiceProtocol,
        imageService: ImageServiceProtocol,
        onProductSelected: @escaping @MainActor (Product) -> Void
    ) {
        self.productsService = productsService
        self.imageService = imageService
        self.onProductSelected = onProductSelected
        searchCancellable = searchSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.applySearch(query: query)
            }
        loadProducts()
    }

    // MARK: - Public Methods

    func clearSearch() {
        searchText = ""
    }

    func didSelect(_ product: Product) {
        guard !isRefreshing,
              let currentProduct = products.first(where: { $0.id == product.id }) else { return }
        loadImage(for: currentProduct)
        onProductSelected(currentProduct)
    }

    func loadImage(for product: Product) {
        switch product.imageState {
        case .loading, .loaded:
            return
        case .idle, .failed:
            break
        }

        guard let url = product.thumbnail else {
            product.imageState = .failed
            return
        }

        // Set loading before creating the task so row and detail appearances share one request.
        product.imageState = .loading

        Task { [imageService] in
            do {
                let image = try await imageService.image(from: url)
                guard !Task.isCancelled else {
                    product.imageState = .idle
                    return
                }
                product.imageState = .loaded(image)
            } catch {
                if Task.isCancelled || error is CancellationError {
                    product.imageState = .idle
                } else {
                    product.imageState = .failed
                }
            }
        }
    }

    func loadProducts() {
        switch state {
        case .idle, .empty, .failed:
            state = .loading
            Task { await fetchProducts(isRefresh: false) }
        case .loading, .loaded:
            return
        }
    }

    func refreshProducts() async {
        guard !Task.isCancelled, !isRefreshing, case .loaded = state else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        refreshError = nil
        await fetchProducts(isRefresh: true)
    }
}

// MARK: - Private Methods

extension CatalogViewModel {
    private func applySearch(query: String) {
        guard !query.isEmpty else {
            filteredProducts = products
            return
        }

        filteredProducts = products.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.sku.localizedCaseInsensitiveContains(query)
        }
    }

    private func message(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff:
                return "You appear to be offline. Check your connection and try again."
            case .timedOut:
                return "The catalog request timed out. Please try again."
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .networkConnectionLost:
                return "The catalog server could not be reached. Please try again shortly."
            default:
                return "The catalog could not be loaded. Please try again."
            }
        }

        if let networkError = error as? NetworkServiceError {
            switch networkError {
            case .invalidResponse:
                return "The catalog server returned an invalid response. Please try again later."
            case .httpStatus(let statusCode):
                return statusCode >= 500
                    ? "The catalog server is unavailable. Please try again later."
                    : "The catalog request was rejected. Please try again later."
            }
        }

        if error is DecodingError {
            return "The catalog response could not be read. Please try again later."
        }

        return "The catalog could not be loaded. Please try again."
    }

    private func fetchProducts(isRefresh: Bool) async {
        do {
            let productDTOs = try await productsService.fetchProducts()
            try Task.checkCancellation()

            products = productDTOs.map { Product(dto: $0) }
            applySearch(
                query: searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            refreshError = nil
            state = products.isEmpty ? .empty : .loaded
        } catch {
            if isRefresh {
                guard !Task.isCancelled, !(error is CancellationError),
                      (error as? URLError)?.code != .cancelled else { return }
                refreshError = message(for: error)
            } else {
                state = .failed(message(for: error))
            }
        }
    }
}
