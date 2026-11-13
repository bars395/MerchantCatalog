import Foundation
import XCTest
import Observation
@testable import MerchantCatalog

@MainActor
final class CatalogSearchTests: XCTestCase {

    // MARK: - Public Methods

    func testSearchMatchesSKUOnly() async throws {
        let viewModel = try makeViewModel()
        try await waitForCatalogLoad(viewModel)
        XCTAssertEqual(viewModel.filteredProducts.map(\.id), [31, 44])

        let searchApplied = expectation(description: "SKU filter is applied")
        withObservationTracking {
            _ = viewModel.filteredProducts.map(\.id)
        } onChange: {
            searchApplied.fulfill()
        }

        viewModel.searchText = "MATCH-ONLY-SKU"
        XCTAssertEqual(viewModel.filteredProducts.map(\.id), [31, 44])
        let result = await XCTWaiter.fulfillment(of: [searchApplied], timeout: 2)
        XCTAssertEqual(result, .completed)
        XCTAssertEqual(viewModel.filteredProducts.map(\.id), [31])
    }

    func testClearSearchRestoresOriginalOrderAfterDebounce() async throws {
        let viewModel = try makeViewModel()
        viewModel.searchText = "MATCH-ONLY-SKU"
        try await waitForCatalogLoad(viewModel)
        XCTAssertEqual(viewModel.filteredProducts.map(\.id), [31])

        let clock = ContinuousClock()
        let clearStarted = clock.now
        let clearApplied = expectation(description: "Clearing restores all products")
        withObservationTracking {
            _ = viewModel.filteredProducts.map(\.id)
        } onChange: {
            XCTAssertGreaterThanOrEqual(clearStarted.duration(to: clock.now), .milliseconds(295))
            clearApplied.fulfill()
        }

        viewModel.clearSearch()
        XCTAssertEqual(viewModel.filteredProducts.map(\.id), [31])
        let result = await XCTWaiter.fulfillment(of: [clearApplied], timeout: 2)
        XCTAssertEqual(result, .completed)

        XCTAssertEqual(viewModel.filteredProducts.map(\.id), [31, 44])
    }
}

// MARK: - Private Methods

extension CatalogSearchTests {
    private func makeViewModel() throws -> CatalogViewModel {
        let container = try makeFixtureContainer()
        return CatalogViewModel(
            productsService: container.productsService,
            imageService: container.imageService,
            onProductSelected: { _ in }
        )
    }
}

// MARK: - Types

struct CatalogFixtureNetworkService {

    // MARK: - Public Properties

    let fixtureData: Data
}

// MARK: - Fixture Functions

func loadCatalogSearchFixtureData() throws -> Data {
    let url = try XCTUnwrap(
        Bundle(for: CatalogSearchTests.self).url(
            forResource: "catalog-search-fixture",
            withExtension: "json"
        )
    )
    return try Data(contentsOf: url)
}

@MainActor
func makeFixtureContainer() throws -> DependencyContainer {
    DependencyContainer(networkService: CatalogFixtureNetworkService(
        fixtureData: try loadCatalogSearchFixtureData()
    ))
}

// MARK: - NetworkServiceProtocol

extension CatalogFixtureNetworkService: NetworkServiceProtocol {
    func data(from url: URL) async throws -> Data {
        fixtureData
    }
}
