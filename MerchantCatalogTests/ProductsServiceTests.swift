import Foundation
import XCTest
@testable import MerchantCatalog

// MARK: - Private Types

private struct FixtureNetworkService {

    // MARK: - Public Properties

    let fixtureData: Data
}

final class ProductsServiceTests: XCTestCase {

    // MARK: - Public Methods

    func testFetchProductsDecodesLocalFixture() async throws {
        let fixtureURL = try XCTUnwrap(
            Bundle(for: Self.self).url(
                forResource: "products-fixture",
                withExtension: "json"
            )
        )
        let fixtureData = try Data(contentsOf: fixtureURL)
        let service = ProductsService(
            networkService: FixtureNetworkService(fixtureData: fixtureData)
        )

        let products = try await service.fetchProducts()
        let product = try XCTUnwrap(products.first)

        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(product.id, 101)
        XCTAssertEqual(product.sku, "SAMPLE-101")
        XCTAssertEqual(product.stock, 7)
    }
}

// MARK: - NetworkServiceProtocol

extension FixtureNetworkService: NetworkServiceProtocol {
    func data(from url: URL) async throws -> Data {
        fixtureData
    }
}
