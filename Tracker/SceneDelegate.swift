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

        if !SettingsManager.shared.shouldShowOnboarding {
            showMainInterface()
        } else {
            let onboardingVC = OnboardingViewController()
            onboardingVC.onOnboardingCompleted = { [weak self] in
                self?.showMainInterface()
            }
            window?.rootViewController = onboardingVC
        }

        window?.makeKeyAndVisible()
    }
    
    // MARK: - Private Methods
    func showMainInterface() {
        SettingsManager.shared.hasSeenOnboarding = true
        
        let tabBarController = UITabBarController()
        
        // Первая вкладка - Трекеры
        let labelTrackers = NSLocalizedString("main.trackers.tabTitle", comment: "Tab title for trackers screen")
        let trackersVC = TrackersViewController()
        let trackersNavController = UINavigationController(rootViewController: trackersVC)
        trackersNavController.tabBarItem = UITabBarItem(
            
            title: labelTrackers,
            image: UIImage(named: "trackertab"),
            selectedImage: UIImage(named: "trackertab")
        )
        
        let labelStatistics = NSLocalizedString("main.statistics.tabTitle", comment: "Tab title for statistics screen")
        // Вторая вкладка - Статистика
        let statsVC = StatisticsViewController()
        let statsNavController = UINavigationController(rootViewController: statsVC)
        statsNavController.tabBarItem = UITabBarItem(
            title: labelStatistics,
            image: UIImage(named: "statistictab"),
            selectedImage: UIImage(named: "statistictab")
        )
        
        tabBarController.viewControllers = [trackersNavController, statsNavController]
        window?.rootViewController = tabBarController
    }
}
