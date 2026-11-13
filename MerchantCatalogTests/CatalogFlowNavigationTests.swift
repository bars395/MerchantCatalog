import SwiftUI
import UIKit
import XCTest
@testable import MerchantCatalog

@MainActor
final class CatalogFlowNavigationTests: XCTestCase {

    // MARK: - Public Methods

    func testSelectionPushesSameProductAndBackPreservesSearch() async throws {
        let navigationController = UINavigationController()
        let flow = CatalogFlow(
            router: Router(navigationController: navigationController),
            dependencyContainer: try makeFixtureContainer()
        )

        flow.start()

        let rootController = try XCTUnwrap(
            navigationController.viewControllers.first as? UIHostingController<CatalogView>
        )
        let viewModel = rootController.rootView.viewModel
        viewModel.searchText = "MATCH-ONLY-SKU"
        try await waitForCatalogLoad(viewModel)
        XCTAssertEqual(viewModel.filteredProducts.map(\.id), [31])

        let selectedProduct = try XCTUnwrap(viewModel.filteredProducts.first)
        withExtendedLifetime(flow) { viewModel.didSelect(selectedProduct) }

        XCTAssertEqual(navigationController.viewControllers.count, 2)
        let detailController = try XCTUnwrap(
            navigationController.viewControllers.last as? UIHostingController<ProductDetailView>
        )
        XCTAssertEqual(detailController.title, selectedProduct.title)
        XCTAssertTrue(detailController.rootView.viewModel.product === selectedProduct)

        navigationController.popViewController(animated: false)

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers.first === rootController)
        XCTAssertTrue(rootController.rootView.viewModel === viewModel)
        XCTAssertEqual(viewModel.searchText, "MATCH-ONLY-SKU")
        XCTAssertEqual(viewModel.filteredProducts.map(\.id), [31])
    }
}
