import SwiftUI
import UIKit

@MainActor
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func startFlow()
}

@MainActor
final class ApplicationCoordinator: Coordinator {
    let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func startFlow() {
        let hostingController = UIHostingController(rootView: CatalogView())
        navigationController.setViewControllers([hostingController], animated: false)
    }
}
