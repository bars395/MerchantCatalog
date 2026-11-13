import Foundation

// MARK: - Types

protocol ProductsServiceProtocol: Sendable {
    func fetchProducts() async throws -> [ProductDTO]
}

struct ProductsService {

    // MARK: - Private Properties

    private let networkService: NetworkServiceProtocol

    private let endpoint = URL(string:
        "https://dummyjson.com/products?limit=0&select=id,title,price,stock,sku,description,thumbnail"
    )!

    // MARK: - Object Lifecycle

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
}

// MARK: - ProductsServiceProtocol

extension ProductsService: ProductsServiceProtocol {
    func fetchProducts() async throws -> [ProductDTO] {
        let data = try await networkService.data(from: endpoint)
        // A local decoder is enough for occasional catalog requests.
        // For frequent requests, the service could store and reuse one.
        return try JSONDecoder().decode(ProductsResponse.self, from: data).products
    }
}
