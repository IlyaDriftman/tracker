//
//  OnboardingViewController.swift
//  Tracker
//
//  Created by Илья on 19.10.2025.
//

//
//  OnboardingViewController.swift
//  UIPageViewController
//
//  Created by Илья on 19.10.2025.
//

import UIKit

// MARK: - PageControlDelegate Protocol
protocol PageControlDelegate: AnyObject {
    func updatePageControl(to page: Int)
}

class OnboardingViewController: UIPageViewController {
    
    
    // MARK: - Properties
    private let pages: [OnboardingPageViewController] = {
        let page1 = OnboardingPageViewController()
        page1.configure(
            backgroundImageName: "bg1",
            titleText: "Отслеживайте только\n то, что хотите",
            buttonText: "Вот это технологии!",
            currentPageIndex: 0,
            totalPages: 2
        )
        
        let page2 = OnboardingPageViewController()
        page2.configure(
            backgroundImageName: "bg2",
            titleText: "Даже если это\n не литры воды и йога",
            buttonText: "Вот это технологии!",
            currentPageIndex: 1,
            totalPages: 2
        )
        
        return [page1, page2]
    }()
    
    // MARK: - PageControlDelegate
    weak var pageControlDelegate: PageControlDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageViewController()
    }
    
    // MARK: - Setup Methods
    private func setupPageViewController() {
        dataSource = self
        delegate = self
        
        // Устанавливаем делегат для каждой страницы
        for page in pages {
            page.pageControlDelegate = self
        }
        
        if let first = pages.first {
            setViewControllers([first], direction: .forward, animated: true, completion: nil)
        }
    }
}

extension OnboardingViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        //возвращаем предыдущий (относительно переданного viewController) дочерний контроллер
        guard let onboardingPage = viewController as? OnboardingPageViewController,
              let viewControllerIndex = pages.firstIndex(of: onboardingPage) else {
            return nil
        }
                
        let previousIndex = viewControllerIndex - 1
                
        guard previousIndex >= 0 else {
            return pages[pages.count - 1]
        }
                
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    
        guard let onboardingPage = viewController as? OnboardingPageViewController,
              let viewControllerIndex = pages.firstIndex(of: onboardingPage) else {
            return nil
        }
               
        let nextIndex = viewControllerIndex + 1
               
        guard nextIndex < pages.count else {
            return pages[0]
        }
               
        return pages[nextIndex]
    }
}

extension OnboardingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let currentViewController = pageViewController.viewControllers?.first as? OnboardingPageViewController,
           let currentIndex = pages.firstIndex(of: currentViewController) {

            updateAllPageControls(to: currentIndex)
        }
    }
    
    private func updateAllPageControls(to page: Int) {
        for pageVC in pages {
            pageVC.pageControl.currentPage = page
        }
    }
}

// MARK: - PageControlDelegate
extension OnboardingViewController: PageControlDelegate {
    func updatePageControl(to page: Int) {
        let direction: UIPageViewController.NavigationDirection = page > getCurrentPageIndex() ? .forward : .reverse
        setViewControllers([pages[page]], direction: direction, animated: true, completion: nil)
    }
    
    private func getCurrentPageIndex() -> Int {
        guard let currentVC = viewControllers?.first as? OnboardingPageViewController,
              let index = pages.firstIndex(of: currentVC) else { return 0 }
        return index
    }
}
