import UIKit

@MainActor
final class Router {

    // MARK: - Private Properties

    private let navigationController: UINavigationController

    // MARK: - Object Lifecycle

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Public Methods

    func setRoot(_ viewController: UIViewController) {
        navigationController.setViewControllers([viewController], animated: false)
    }

    func push(_ viewController: UIViewController) {
        navigationController.pushViewController(viewController, animated: true)
    }
}
