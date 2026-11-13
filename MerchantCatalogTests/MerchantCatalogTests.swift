import SwiftUI
import UIKit
import XCTest
@testable import MerchantCatalog

@MainActor
final class MerchantCatalogTests: XCTestCase {

    // MARK: - Public Methods

    func testStartFlowInstallsCatalogAsRootController() throws {
        let navigationController = UINavigationController()
        let router = Router(navigationController: navigationController)
        let flow = CatalogFlow(router: router, dependencyContainer: try makeFixtureContainer())

        flow.start()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(
            navigationController.viewControllers.first is UIHostingController<CatalogView>
        )
    }
}
