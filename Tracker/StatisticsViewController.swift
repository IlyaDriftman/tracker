import UIKit

final class StatisticsViewController: AnalyticsViewController, StoreChangesDelegate {
    
    private let recordStore = TrackerRecordStore()
    private let statisticService = TrackerStatisticService()
    
    // MARK: - UI Elements
    private let titleLabel = UILabel()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let cardsStackView = UIStackView()
    
    // MARK: - Statistics Cards
    private let bestPeriodCard = StatisticCard()
    private let idealDaysCard = StatisticCard()
    private let completedTrackersCard = StatisticCard()
    private let averageValueCard = StatisticCard()
    
    // MARK: - Empty State Elements
    private let emptyStateView = UIView()
    private let emptyStateImageView = UIImageView()
    private let emptyStateLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        analyticsScreenName = .statistics
        // TODO: Добавить .statistics в AnalyticsService.Screen enum и установить analyticsScreenName
        setupCoreData()
        setupUI()
        setupConstraints()
        configureCards()
    }
    
    private func setupCoreData() {
        // Устанавливаем делегат для получения обновлений
        recordStore.delegate = self
        
        // performFetch() нужен для работы NSFetchedResultsControllerDelegate
        // Без него trackerRecordsDidUpdate() не будет вызываться при изменениях
        // Используем try? для упрощения - если fetch не удастся, делегат просто не будет работать
        try? recordStore.performFetch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Обновляем статистику при появлении экрана
        configureCards()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Title Label
        titleLabel.text = "Статистика"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Scroll View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        
        // Content View
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Stack View для карточек
        cardsStackView.axis = .vertical
        cardsStackView.spacing = 12
        cardsStackView.distribution = .fill
        cardsStackView.alignment = .fill
        cardsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Добавляем карточки в stack view
        cardsStackView.addArrangedSubview(bestPeriodCard)
        cardsStackView.addArrangedSubview(idealDaysCard)
        cardsStackView.addArrangedSubview(completedTrackersCard)
        cardsStackView.addArrangedSubview(averageValueCard)
        
        // Empty State
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateImageView.image = UIImage(named: "statisticsError")
        emptyStateImageView.contentMode = .scaleAspectFit
        emptyStateImageView.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateLabel.text = "Анализировать пока нечего"
        emptyStateLabel.font = .systemFont(ofSize: 12)
        emptyStateLabel.textColor = .label
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateView.addSubview(emptyStateImageView)
        emptyStateView.addSubview(emptyStateLabel)
        
        // Добавляем в иерархию
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(cardsStackView)
        view.addSubview(emptyStateView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 1
            ),
            titleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 16
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -16
            ),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Cards Stack View
            // 206px от верха экрана до первой ячейки
            cardsStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 206),
            cardsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            // Высота карточек (одинаковая для всех)
            bestPeriodCard.heightAnchor.constraint(equalToConstant: 90),
            idealDaysCard.heightAnchor.constraint(equalToConstant: 90),
            completedTrackersCard.heightAnchor.constraint(equalToConstant: 90),
            averageValueCard.heightAnchor.constraint(equalToConstant: 90),
            
            // Empty State View - по центру экрана
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Empty State Image
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Empty State Label - отступы 16px по бокам, 8px снизу от картинки
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 8),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 16),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -16),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }
    
    private func configureCards() {
        // Проверяем, есть ли данные для статистики
        let totalCompleted = statisticService.totalCompletedTrackers()
        let hasData = totalCompleted > 0
        
        // Обновляем видимость карточек и empty state
        updateEmptyState(hasData: hasData)
        
        guard hasData else {
            return
        }
        
        // Карточка 1: Лучший период
        let bestPeriod = statisticService.calculateBestPeriod()
        bestPeriodCard.configure(
            number: "\(bestPeriod)",
            description: "Лучший период"
        )
        
        // Карточка 2: Идеальные дни
        let idealDays = statisticService.calculateIdealDays()
        idealDaysCard.configure(
            number: "\(idealDays)",
            description: "Идеальные дни"
        )
        
        // Карточка 3: Трекеров завершено
        completedTrackersCard.configure(
            number: "\(totalCompleted)",
            description: "Трекеров завершено"
        )
        
        // Карточка 4: Среднее значение
        let averageValue = statisticService.calculateAverageValue()
        averageValueCard.configure(
            number: "\(averageValue)",
            description: "Среднее значение"
        )
    }
    
    private func updateEmptyState(hasData: Bool) {
        emptyStateView.isHidden = hasData
        cardsStackView.isHidden = !hasData
    }
    func storeWillChangeContent() { }
        func storeDidChangeSection(at sectionIndex: Int, for type: StoreChangeType) { }
        func storeDidChangeObject(at indexPath: IndexPath?, for type: StoreChangeType, newIndexPath: IndexPath?) { }
        func storeDidChangeContent() { }
        
    func trackerRecordsDidUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.configureCards()
        }
    }
    
}

