import UIKit

@MainActor
final class SceneDelegate: UIResponder {

    // MARK: - Public Properties

    var window: UIWindow?

    // MARK: - Private Properties

    private var catalogFlow: CatalogFlow?
}

// MARK: - UIWindowSceneDelegate

extension SceneDelegate: UIWindowSceneDelegate {
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let environment = ProcessInfo.processInfo.environment
        if environment["XCInjectBundleInto"] != nil || environment["XCTestConfigurationFilePath"] != nil {
            // Unit tests create their own flows backed by local fixtures.
            window.rootViewController = UIViewController()
        } else {
            let navigationController = UINavigationController()
            let flow = CatalogFlow(router: Router(navigationController: navigationController))
            catalogFlow = flow
            flow.start()
            window.rootViewController = navigationController
        }
        window.makeKeyAndVisible()
        self.window = window
    }
}
