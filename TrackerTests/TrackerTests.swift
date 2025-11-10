//
//  TrackerTests.swift
//  TrackerTests
//
//  Created by Илья on 02.11.2025.
//

import SnapshotTesting
import XCTest

@testable import Tracker

extension SceneDelegate {
    func testable_showMainInterface() {
        self.showMainInterface()
    }
}

final class TabBarSnapshotTests: XCTestCase {
    func testMainInterfaceAppearance() {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let sceneDelegate = SceneDelegate()
        sceneDelegate.window = UIWindow(windowScene: scene!)

        sceneDelegate.testable_showMainInterface()
        
        guard let tabBarController = sceneDelegate.window?.rootViewController as? UITabBarController else {
            XCTFail("rootViewController is not UITabBarController")
            return
        }

        if let trackersNav = tabBarController.viewControllers?.first as? UINavigationController,
           let trackersVC = trackersNav.viewControllers.first as? TrackersViewController {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            _ = trackersVC.view
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            trackersVC.datePicker?.date = dateFormatter.date(from: "2025/11/02")!
        }

        // Тест для светлой темы
        assertSnapshot(
            of: tabBarController,
            as: .image(traits: .init(userInterfaceStyle: .light)),
            record: false
        )
    }
    
    func testMainInterfaceAppearanceDark() {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let sceneDelegate = SceneDelegate()
        sceneDelegate.window = UIWindow(windowScene: scene!)

        sceneDelegate.testable_showMainInterface()
        
        guard let tabBarController = sceneDelegate.window?.rootViewController as? UITabBarController else {
            XCTFail("rootViewController is not UITabBarController")
            return
        }

        if let trackersNav = tabBarController.viewControllers?.first as? UINavigationController,
           let trackersVC = trackersNav.viewControllers.first as? TrackersViewController {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            _ = trackersVC.view
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            trackersVC.datePicker?.date = dateFormatter.date(from: "2025/11/02")!
        }

        // Тест для темной темы
        assertSnapshot(
            of: tabBarController,
            as: .image(traits: .init(userInterfaceStyle: .dark)),
            record: false
        )
    }
}
