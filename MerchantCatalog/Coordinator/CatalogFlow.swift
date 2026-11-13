import SwiftUI
import UIKit

@MainActor
final class CatalogFlow {

    // MARK: - Private Properties

    private let dependencyContainer: DependencyContainer
    private let router: Router

    // MARK: - Object Lifecycle

    init(
        router: Router,
        dependencyContainer: DependencyContainer = DependencyContainer()
    ) {
        self.router = router
        self.dependencyContainer = dependencyContainer
    }

    // MARK: - Public Methods

    func start() {
        let viewModel = CatalogViewModel(
            productsService: dependencyContainer.productsService,
            imageService: dependencyContainer.imageService,
            onProductSelected: { [weak self] product in
                self?.showDetails(for: product)
            }
        )
        let rootController = UIHostingController(
            rootView: CatalogView(viewModel: viewModel)
        )
        rootController.title = "Merchant Catalog"
        router.setRoot(rootController)
    }
}

// MARK: - Private Methods

extension CatalogFlow {
    private func showDetails(for product: Product) {
        let viewModel = ProductDetailViewModel(product: product) { sku in
            UIPasteboard.general.string = sku
        }
        let detailController = UIHostingController(rootView: ProductDetailView(viewModel: viewModel))
        detailController.title = product.title
        detailController.navigationItem.largeTitleDisplayMode = .never
        router.push(detailController)
    }
}
