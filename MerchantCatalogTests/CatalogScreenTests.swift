import Foundation
import Observation
import UIKit
import XCTest
@testable import MerchantCatalog

@MainActor
final class ProductDetailViewModelTests: XCTestCase {

    // MARK: - Public Methods

    func testCopySKUCallsInjectedActionWithProductSKU() throws {
        let dto = try XCTUnwrap(
            loadProductDTOFixture(bundle: Bundle(for: Self.self)).first
        )
        let product = Product(dto: dto)
        var copiedSKU: String?
        let viewModel = ProductDetailViewModel(
            product: product,
            copySKU: { copiedSKU = $0 }
        )

        viewModel.copySKU()

        XCTAssertEqual(copiedSKU, product.sku)
    }

    func testDetailViewModelSharesProductAndLatestImageState() throws {
        let dto = try XCTUnwrap(
            loadProductDTOFixture(bundle: Bundle(for: Self.self)).first
        )
        let product = Product(dto: dto)
        let viewModel = ProductDetailViewModel(product: product, copySKU: { _ in })
        let latestImage = try XCTUnwrap(UIImage(systemName: "shippingbox"))
        product.imageState = .loaded(latestImage)

        XCTAssertTrue(viewModel.product === product)
        guard case .loaded(let image) = viewModel.product.imageState else {
            return XCTFail("Detail view model should expose the product's current image")
        }
        XCTAssertTrue(image === latestImage)
    }
}

@MainActor
final class CatalogRetryTests: XCTestCase {

    // MARK: - Public Methods

    func testOfflineCatalogCanBeExplicitlyRetriedWithFixtureProducts() async throws {
        let fixtureProducts = try loadProductDTOFixture(bundle: Bundle(for: Self.self))
        let service = OfflineThenLoadedService(products: fixtureProducts)
        let viewModel = CatalogViewModel(
            productsService: service,
            imageService: UnusedImageService(),
            onProductSelected: { _ in }
        )

        try await waitForCatalogLoad(viewModel)
        guard case .failed(let message) = viewModel.state else {
            return XCTFail("Expected an offline error")
        }
        XCTAssertTrue(message.localizedCaseInsensitiveContains("offline"))

        viewModel.loadProducts()
        try await waitForCatalogLoad(viewModel)

        guard case .loaded = viewModel.state else {
            return XCTFail("Expected products after explicit retry")
        }
        XCTAssertEqual(viewModel.products.first?.sku, "SAMPLE-101")
    }
}

// MARK: - Private Types

private actor OfflineThenLoadedService {

    // MARK: - Public Properties

    let products: [ProductDTO]

    // MARK: - Private Properties

    private var attempts = 0

    // MARK: - Object Lifecycle

    init(products: [ProductDTO]) {
        self.products = products
    }
}

private struct UnusedImageService: ImageServiceProtocol {
    func image(from url: URL) async throws -> UIImage {
        throw URLError(.cancelled)
    }
}

// MARK: - Private Methods

private func loadProductDTOFixture(bundle: Bundle) throws -> [ProductDTO] {
    let url = try XCTUnwrap(
        bundle.url(forResource: "products-fixture", withExtension: "json")
    )
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(ProductsResponse.self, from: data).products
}

// MARK: - ProductsServiceProtocol

extension OfflineThenLoadedService: ProductsServiceProtocol {
    func fetchProducts() async throws -> [ProductDTO] {
        attempts += 1
        if attempts == 1 { throw URLError(.notConnectedToInternet) }
        return products
    }
}

// MARK: - Test Helpers

@MainActor
func waitForCatalogLoad(_ viewModel: CatalogViewModel) async throws {
    guard viewModel.state == .loading else { return }
    let finished = XCTestExpectation(description: "Catalog leaves the loading state")
    withObservationTracking {
        _ = viewModel.state
    } onChange: {
        finished.fulfill()
    }
    guard await XCTWaiter.fulfillment(of: [finished], timeout: 2) == .completed else {
        throw URLError(.timedOut)
    }
}
