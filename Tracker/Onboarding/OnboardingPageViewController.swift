//
//  OnboardingPageViewController.swift
//  Tracker
//
//  Created by Илья on 19.10.2025.
//

import UIKit

class OnboardingPageViewController: UIViewController {
    
    // MARK: - Properties
    private var pageModel: PageModel?
    var currentPageIndex: Int = 0
    var totalPages: Int = 2
    
    weak var pageControlDelegate: PageControlDelegate?
    
    // MARK: - Callbacks
    var onButtonTapped: (() -> Void)?
    
    // MARK: - UI Elements
    private lazy var backgroundImage: UIImageView = {
        let backgroundImg = UIImageView()
        backgroundImg.image = pageModel?.image
        backgroundImg.contentMode = .scaleAspectFill
        backgroundImg.translatesAutoresizingMaskIntoConstraints = false
        return backgroundImg
    }()
    
    // Текст
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textColor = UIColor(named: "trackerBlack")
        label.textAlignment = .center
        label.numberOfLines = 0 // 0 = любое количество строк
        label.lineBreakMode = .byWordWrapping
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // PageControl
    lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = totalPages
        pageControl.currentPage = currentPageIndex
        pageControl.currentPageIndicatorTintColor = UIColor.trackerBlack
        pageControl.pageIndicatorTintColor = UIColor.trackerBlack.withAlphaComponent(0.3)
        pageControl.addTarget(self, action: #selector(pageControlTapped), for: .valueChanged)
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()

    // Кнопка
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(named: "trackerBlack")
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        updateContent()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.addSubview(backgroundImage)
        view.addSubview(titleLabel)
        view.addSubview(pageControl)
        view.addSubview(continueButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImage.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImage.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            // Текст сверху
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -160),

            // PageControl — между текстом и кнопкой
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -24),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -84),
            continueButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func updateContent() {
        titleLabel.text = pageModel?.text
        continueButton.setTitle(pageModel?.buttonText, for: .normal)
        backgroundImage.image = pageModel?.image
        pageControl.currentPage = currentPageIndex
    }
    
    // MARK: - Public Methods
    func configure(pageModel: PageModel, currentPageIndex: Int, totalPages: Int) {
        self.pageModel = pageModel
        self.currentPageIndex = currentPageIndex
        self.totalPages = totalPages
        
        // Обновляем UI если view уже загружен
        if isViewLoaded {
            updateContent()
        }
    }
    
    // MARK: - Actions
    @objc func buttonTapped() {
        onButtonTapped?()
    }
    
    @objc func pageControlTapped(_ sender: UIPageControl) {
        pageControlDelegate?.updatePageControl(to: sender.currentPage)
    }
}
