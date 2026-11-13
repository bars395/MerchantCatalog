import Foundation
import XCTest
@testable import MerchantCatalog

// MARK: - Private Types

private enum CatalogRefreshReply {
    case products([ProductDTO])
    case pendingProducts(AsyncStream<[ProductDTO]>, started: XCTestExpectation)
    case offline
    case cancelled
}

private actor CatalogRefreshScript {

    // MARK: - Private Properties

    private var replies: [CatalogRefreshReply]

    // MARK: - Object Lifecycle

    init(_ replies: [CatalogRefreshReply]) {
        self.replies = replies
    }
}

@MainActor
final class CatalogRefreshTests: XCTestCase {

    // MARK: - Public Methods

    func testReloadAfterEmptyInitialLoadRequestsProductsOnce() async throws {
        let products = try fixtureProducts()
        let viewModel = try makeViewModel(replies: [.products([]), .products(products)])
        try await waitForCatalogLoad(viewModel)
        XCTAssertEqual(viewModel.state, .empty)

        viewModel.loadProducts()
        viewModel.loadProducts()
        try await waitForCatalogLoad(viewModel)

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.products.map(\.id), products.map(\.id))
    }

    func testCancelledInitialLoadCanBeRetried() async throws {
        let products = try fixtureProducts()
        let viewModel = try makeViewModel(replies: [.cancelled, .products(products)])
        try await waitForCatalogLoad(viewModel)
        guard case .failed = viewModel.state else {
            return XCTFail("An interrupted initial load should offer Retry")
        }

        viewModel.loadProducts()
        try await waitForCatalogLoad(viewModel)

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.products.map(\.id), products.map(\.id))
    }

    func testCancelledRefreshKeepsLoadedCatalogWithoutError() async throws {
        let viewModel = try makeViewModel(replies: [.products(try fixtureProducts()), .cancelled])
        try await waitForCatalogLoad(viewModel)
        let product = try XCTUnwrap(viewModel.products.first)

        await viewModel.refreshProducts()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertTrue(viewModel.products.first === product)
        XCTAssertNil(viewModel.refreshError)
    }

    func testSelectionDuringRefreshIsIgnoredAndNextTapOpensUpdatedProduct() async throws {
        let products = try fixtureProducts()
        let refreshStarted = expectation(description: "Refresh requested")
        let (responses, response) = AsyncStream<[ProductDTO]>.makeStream()
        let updatedJSON = """
        {"id":31,"title":"Brass Desk Organizer","price":12,"stock":9,
         "sku":"MATCH-ONLY-SKU","description":"Updated catalog fixture."}
        """
        let updated = try JSONDecoder().decode(ProductDTO.self, from: Data(updatedJSON.utf8))
        var selectedProducts: [Product] = []
        let viewModel = try makeViewModel(replies: [
            .products(products), .pendingProducts(responses, started: refreshStarted)
        ]) { selectedProducts.append($0) }
        try await waitForCatalogLoad(viewModel)
        let original = try XCTUnwrap(viewModel.products.first)
        XCTAssertEqual(original.stock, 3)

        let refresh = Task { await viewModel.refreshProducts() }
        await fulfillment(of: [refreshStarted], timeout: 2)
        XCTAssertTrue(viewModel.isRefreshing)
        viewModel.didSelect(original)
        XCTAssertTrue(selectedProducts.isEmpty)

        response.yield([updated])
        response.finish()
        await refresh.value

        XCTAssertFalse(viewModel.isRefreshing)
        guard case .idle = original.imageState else {
            return XCTFail("A disabled selection should leave the image idle")
        }
        viewModel.didSelect(original)
        XCTAssertEqual(selectedProducts.count, 1)
        XCTAssertTrue(selectedProducts.first === viewModel.products.first)
        XCTAssertEqual(selectedProducts.first?.stock, 9)
    }

    func testSuccessfulRefreshShowsNewMatchForActiveSKUSearch() async throws {
        let products = try fixtureProducts()
        let viewModel = try makeViewModel(replies: [
            .products(products.filter { $0.id == 44 }),
            .products(products)
        ])
        viewModel.searchText = "MATCH-ONLY-SKU"
        try await waitForCatalogLoad(viewModel)
        XCTAssertEqual(viewModel.products.map { $0.id }, [44])
        XCTAssertTrue(viewModel.filteredProducts.isEmpty)

        await viewModel.refreshProducts()

        XCTAssertEqual(viewModel.searchText, "MATCH-ONLY-SKU")
        XCTAssertEqual(viewModel.products.map { $0.id }, [31, 44])
        XCTAssertEqual(viewModel.filteredProducts.map { $0.id }, [31])
        XCTAssertNil(viewModel.refreshError)
    }

    func testFailedRefreshKeepsVisibleProductsAndActiveSKUSearch() async throws {
        let viewModel = try makeViewModel(replies: [.products(try fixtureProducts()), .offline])
        viewModel.searchText = "MATCH-ONLY-SKU"
        try await waitForCatalogLoad(viewModel)
        let oldProduct = try XCTUnwrap(viewModel.filteredProducts.first)
        XCTAssertEqual(viewModel.products.map { $0.id }, [31, 44])

        await viewModel.refreshProducts()

        XCTAssertEqual(viewModel.searchText, "MATCH-ONLY-SKU")
        XCTAssertEqual(viewModel.filteredProducts.map { $0.id }, [31])
        XCTAssertTrue(viewModel.filteredProducts.first === oldProduct)
        XCTAssertTrue(viewModel.products.first === oldProduct)
        XCTAssertNotNil(viewModel.refreshError)
        guard case .loaded = viewModel.state else {
            return XCTFail("A refresh failure should leave the loaded catalog visible")
        }
    }
}

// MARK: - Private Methods

extension CatalogRefreshTests {
    private func makeViewModel(
        replies: [CatalogRefreshReply],
        onProductSelected: @escaping @MainActor (Product) -> Void = { _ in }
    ) throws -> CatalogViewModel {
        let container = try makeFixtureContainer()
        return CatalogViewModel(
            productsService: CatalogRefreshScript(replies),
            imageService: container.imageService,
            onProductSelected: onProductSelected
        )
    }

    private func fixtureProducts() throws -> [ProductDTO] {
        try JSONDecoder().decode(ProductsResponse.self, from: loadCatalogSearchFixtureData()).products
    }
}

// MARK: - ProductsServiceProtocol

extension CatalogRefreshScript: ProductsServiceProtocol {
    func fetchProducts() async throws -> [ProductDTO] {
        guard !replies.isEmpty else {
            XCTFail("Unexpected catalog request")
            throw URLError(.cannotConnectToHost)
        }

        switch replies.removeFirst() {
        case .products(let products):
            return products
        case .pendingProducts(let responses, let started):
            started.fulfill()
            var iterator = responses.makeAsyncIterator()
            return await iterator.next() ?? []
        case .offline:
            throw URLError(.notConnectedToInternet)
        case .cancelled:
            throw CancellationError()
        }
    }
}
