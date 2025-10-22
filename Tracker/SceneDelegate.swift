import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)

        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

        if hasSeenOnboarding {
            let mainVC = TrackersViewController()
            let navController = UINavigationController(rootViewController: mainVC)
            window?.rootViewController = navController
        } else {
            window?.rootViewController = OnboardingViewController()
        }

        window?.makeKeyAndVisible()
    }
}
