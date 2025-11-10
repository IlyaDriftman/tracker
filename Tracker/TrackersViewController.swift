import UIKit
import CoreData

class TrackersViewController: AnalyticsViewController {
    

    // MARK: - UI Elements
    private let searchBar = UISearchBar()
    private let contentView = UIView()
    private let placeholderStackView = UIStackView()
    private let searchEmptyStateView = UIView()
    private let searchEmptyStateImageView = UIImageView()
    private let searchEmptyStateLabel = UILabel()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private var dateButton = UIButton()
    private let plusImage = UIImage(named: "plus")
    private let filtersButton = UIButton(type: .system)
    let colors = MyColor()
    private let labelSearch = NSLocalizedString("main.trackers.searchPlaceholder", comment: "Search field placeholder on trackers screen")
    private let labelFilter = NSLocalizedString("main.trackers.filtersButtonTitle", comment: "Filters button title on trackers screen")
    private let labelPinned = NSLocalizedString("main.trackers.pinnedSectionTitle", comment: "Pinned section title on trackers screen")

    // MARK: - Properties
    var datePicker: UIDatePicker?
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(
            top: 12,
            left: 16,
            bottom: 16,
            right: 16
        )

        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true  // Оверскролл для прокрутки выше кнопки фильтров
        return collectionView
    }()

    // MARK: - Core Data
    private let trackerStore = TrackerStore()
    private let categoryStore = TrackerCategoryStore()
    private let recordStore = TrackerRecordStore()
    
    // MARK: - UI State
    private var visibleCategories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    private var currentDate: Date
    private var pendingChanges: [() -> Void] = []
    private var selectedFilter: FilterType = .all
    
    // MARK: - Delete Dialog State
    private var currentDeleteIndexPath: IndexPath?
    private var currentDeleteTrackerId: UUID?
    private var deleteConfirmationView: DeleteConfirmationView?
    //let defaultCategory = TrackerCategory(
   //     title: "Общее",
    //    trackers: []
    //)

    // MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        currentDate = Date()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        currentDate = Date()
        super.init(coder: coder)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        analyticsScreenName = .main
        setupUI()
        setupCoreData()
        updateFiltersButtonAppearance()  // Инициализируем цвет кнопки
        reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Настраиваем цвета searchBar после layout
        configureSearchBarColors()
    }
    
    
    private func setupCoreData() {
        // Подписываемся на изменения в сторах
        trackerStore.delegate = self
        
        // Загружаем данные из Core Data
        do {
            try trackerStore.performFetch()
            try loadCompletedRecords()
            
            // Удаляем тестовую категорию, если она существует
            try removeTestCategoryIfExists()
        } catch {
            // Ошибка загрузки данных
        }
    }
    
    
    private func removeTestCategoryIfExists() throws {
        let categoriesCD = try categoryStore.fetchAllCategories()
        for (index, categoryCD) in categoriesCD.enumerated() {
            if categoryCD.title == "Тестовая категория" {
                try categoryStore.deleteCategory(at: index)
                break
            }
        }
    }
    
    private func loadCompletedRecords() throws {
        let records = try recordStore.fetchAllRecords()
        completedTrackers = records.compactMap { recordCD in
            guard let id = recordCD.tracker?.id,
                  let date = recordCD.date else { return nil }
            return TrackerRecord(trackerId: id, date: date)
        }
    }

    // MARK: - Actions
    private func reloadData() {
        applyDateFilter()
    }

    @objc private func plusButtonTapped() {
        
        let addTrackerVC = AddTrackerViewController()
        addTrackerVC.delegate = self
        // Загружаем категории из Core Data
        do {
            let categoriesCD = try categoryStore.fetchAllCategories()
            let categories: [TrackerCategory] = categoriesCD.compactMap { categoryCD in
                guard let title = categoryCD.title else { return nil }
                return TrackerCategory(title: title, trackers: [])
            }
            addTrackerVC.categories = categories
        } catch {
            addTrackerVC.categories = []
        }
        present(addTrackerVC, animated: true)
    }

    private func applyDateFilter() {
        let filterText = (searchBar.text ?? "").lowercased()
        let calendar = Calendar.current
        
        // Определяем дату для фильтрации по расписанию
        let filterDate: Date
        if selectedFilter == .today {
            filterDate = Date()
        } else {
            filterDate = currentDate
        }
        
        let weekdayFromCalendar = calendar.component(.weekday, from: filterDate)

        // Преобразуем из календарного формата (1=воскресенье) в наш формат (1=понедельник)
        let filterWeekday: Int
        if weekdayFromCalendar == 1 {
            filterWeekday = 7
        } else {
            filterWeekday = weekdayFromCalendar - 1
        }

        // Обновляем predicate FRC для поиска по названию
        do {
            if filterText.isEmpty {
                try trackerStore.updateFetchPredicate(nil)
            } else {
                let predicate = NSPredicate(format: "title CONTAINS[cd] %@", filterText)
                try trackerStore.updateFetchPredicate(predicate)
            }
        } catch {
            // Ошибка обновления predicate
        }

        // Группируем трекеры по категориям из Core Data
        var categoriesDict: [String: [Tracker]] = [:]
        var pinnedTrackers: [Tracker] = []
        
        for section in 0..<trackerStore.numberOfSections {
            let sectionTitle = trackerStore.sectionTitle(at: section) ?? "Без категории"
            
            for item in 0..<trackerStore.numberOfObjects(in: section) {
                let indexPath = IndexPath(item: item, section: section)
                let trackerCD = trackerStore.object(at: indexPath)
                
                guard let tracker = trackerStore.tracker(from: trackerCD) else { continue }
                
                let textCondition = filterText.isEmpty || tracker.title.lowercased().contains(filterText)
                guard let schedule = tracker.schedule else { continue }
                let weekday = Weekday(rawValue: filterWeekday) ?? .mon
                
                // Проверяем, соответствует ли трекер расписанию
                let scheduleMatches = schedule.contains(weekday)
                
                // Проверяем статус завершенности для фильтров
                // Для фильтров "Завершенные" и "Не завершенные" проверяем на выбранную дату
                // Для фильтра "Трекеры на сегодня" проверяем на текущую дату
                let dateToCheck: Date
                if selectedFilter == .today {
                    dateToCheck = Date()
                } else {
                    dateToCheck = currentDate
                }
                
                let isCompleted = isTrackerCompleted(id: tracker.id, date: dateToCheck)
                let shouldInclude: Bool
                
                switch selectedFilter {
                case .all:
                    shouldInclude = scheduleMatches && textCondition
                case .today:
                    shouldInclude = scheduleMatches && textCondition
                case .completed:
                    shouldInclude = scheduleMatches && textCondition && isCompleted
                case .notCompleted:
                    shouldInclude = scheduleMatches && textCondition && !isCompleted
                }
                
                if shouldInclude {
                    // Разделяем на закрепленные и незакрепленные
                    if tracker.isPinned {
                        pinnedTrackers.append(tracker)
                    } else {
                        if categoriesDict[sectionTitle] == nil {
                            categoriesDict[sectionTitle] = []
                        }
                        categoriesDict[sectionTitle]?.append(tracker)
                    }
                }
            }
        }
        
        // Формируем массив категорий: сначала закрепленные, затем остальные по категориям
        var resultCategories: [TrackerCategory] = []
        
        // Добавляем секцию "Закрепленные" если есть закрепленные трекеры
        if !pinnedTrackers.isEmpty {
            resultCategories.append(TrackerCategory(title: labelPinned, trackers: pinnedTrackers))
        }
        
        // Добавляем остальные категории отсортированные по названию
        let otherCategories = categoriesDict.compactMap { (title, trackers) -> TrackerCategory? in
            guard !trackers.isEmpty else { return nil }
            return TrackerCategory(title: title, trackers: trackers)
        }.sorted { $0.title < $1.title }
        
        resultCategories.append(contentsOf: otherCategories)
        visibleCategories = resultCategories
        
        collectionView.reloadData()
        updatePlaceholderVisibility()
        updateFiltersButtonVisibility()
        updateFiltersButtonAppearance()
    }

    @objc private func dateChanged() {
        currentDate = datePicker?.date ?? Date()
        // Перезагружаем записи для новой даты
        do {
            try loadCompletedRecords()
        } catch {
            // Ошибка загрузки записей
        }
        applyDateFilter()
    }


    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = colors.viewBackgroundColor

        // Setup navigation bar
        setupNavigationBar()

        // Setup UI elements
        setupTitleLabel()
        setupSearchBar()
        setupContentView()
        setupPlaceholderStackView()
        setupSearchEmptyState()
        setupFiltersButton()

        // Collection View
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            TrackerCell.self,
            forCellWithReuseIdentifier: "TrackerCell"
        )
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView
                .elementKindSectionHeader,
            withReuseIdentifier: "SectionHeader"
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        // Add collection view to content view
        contentView.addSubview(collectionView)

        // Add all elements to view
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(contentView)
        contentView.addSubview(placeholderStackView)
        contentView.addSubview(searchEmptyStateView)
        view.addSubview(filtersButton)

        setupConstraints()
    }
    
    private func setupFiltersButton() {
        
        filtersButton.setTitle(labelFilter, for: .normal)
        filtersButton.setTitleColor(.white, for: .normal)
        filtersButton.titleLabel?.font = .systemFont(ofSize: 17)
        filtersButton.backgroundColor = UIColor(hex: "#3772E7")
        filtersButton.layer.cornerRadius = 16
        filtersButton.translatesAutoresizingMaskIntoConstraints = false
        filtersButton.addTarget(
            self,
            action: #selector(filtersButtonTapped),
            for: .touchUpInside
        )
    }
    
    @objc private func filtersButtonTapped() {
        let filtersVC = FiltersViewController()
        filtersVC.delegate = self
        filtersVC.selectedFilter = selectedFilter
        
        present(filtersVC, animated: true)
    }

    private func setupNavigationBar() {
        // Date picker
        let datePicker = UIDatePicker()
        datePicker.backgroundColor = colors.bgDatePicker
        //datePicker.tintColor = colors.labelDatePicker
        datePicker.layer.cornerRadius = 8
        datePicker.layer.masksToBounds = true
        NSLayoutConstraint.activate([
                datePicker.widthAnchor.constraint(equalToConstant: 100)
            ])
       
        
        // Принудительно используем светлую тему для datePicker, чтобы текст был черным
        datePicker.overrideUserInterfaceStyle = .light
        
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        //datePicker.locale = Locale(identifier: "ru_RU")
        datePicker.addTarget(
            self,
            action: #selector(dateChanged),
            for: .valueChanged
        )

        // Plus button
        let plusButton = UIButton(type: .custom)
        plusButton.setImage(plusImage, for: .normal)
        plusButton.tintColor = .label

        plusButton.addTarget(
            self,
            action: #selector(plusButtonTapped),
            for: .touchUpInside
        )
        //plusButton.frame = CGRect(x: 0, y: 0, width: 42, height: 42)

        // Add to navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            customView: plusButton
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            customView: datePicker
        )

        self.datePicker = datePicker

    }

    private func setupSearchBar() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = labelSearch
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        searchBar.barTintColor = .clear
        searchBar.isTranslucent = true
        searchBar.delegate = self
    }
    
    private func configureSearchBarColors() {
        // Находим UITextField внутри searchBar
        if #available(iOS 13.0, *) {
            // Для iOS 13+ используем прямой доступ
            let textField = searchBar.searchTextField
            textField.attributedPlaceholder = NSAttributedString(
                string: labelSearch,
                attributes: [NSAttributedString.Key.foregroundColor: colors.phSearch ?? .placeholderText]
            )
            textField.leftView?.tintColor = colors.phSearch
        } else {
            // Для iOS 12 и ниже используем поиск через view hierarchy
            if let textField = findTextField(in: searchBar) {
                textField.attributedPlaceholder = NSAttributedString(
                    string: labelSearch,
                    attributes: [NSAttributedString.Key.foregroundColor: colors.phSearch ?? .placeholderText]
                )
                textField.leftView?.tintColor = colors.phSearch
            }
        }
    }
    
    private func findTextField(in view: UIView) -> UITextField? {
        for subview in view.subviews {
            if let textField = subview as? UITextField {
                return textField
            }
            if let found = findTextField(in: subview) {
                return found
            }
        }
        return nil
    }

    private func setupTitleLabel() {
        let labelTrackers = NSLocalizedString("main.trackers.navigationTitle", comment: "Navigation title for trackers screen")

        titleLabel.text = labelTrackers
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = colors.viewBackgroundColor
    }

    private func setupPlaceholderStackView() {
        placeholderStackView.translatesAutoresizingMaskIntoConstraints = false
        placeholderStackView.axis = .vertical
        placeholderStackView.alignment = .center
        placeholderStackView.spacing = 16

        // Placeholder image
        let placeholderImage = UIImageView(image: UIImage(named: "1"))
        placeholderImage.contentMode = .scaleAspectFit
        placeholderImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            placeholderImage.widthAnchor.constraint(equalToConstant: 80),
            placeholderImage.heightAnchor.constraint(equalToConstant: 80),
        ])

        // Placeholder label
        let placeholderLabel = UILabel()
        placeholderLabel.text = "Что будем отслеживать?"
        placeholderLabel.textAlignment = .center
        placeholderLabel.font = UIFont.systemFont(ofSize: 17)
        placeholderLabel.textColor = .label

        placeholderStackView.addArrangedSubview(placeholderImage)
        placeholderStackView.addArrangedSubview(placeholderLabel)
    }
    
    private func setupSearchEmptyState() {
        searchEmptyStateView.translatesAutoresizingMaskIntoConstraints = false
        
        searchEmptyStateImageView.image = UIImage(named: "searchError")
        searchEmptyStateImageView.contentMode = .scaleAspectFit
        searchEmptyStateImageView.translatesAutoresizingMaskIntoConstraints = false
        
        searchEmptyStateLabel.text = "Ничего не найдено"
        searchEmptyStateLabel.font = .systemFont(ofSize: 12)
        searchEmptyStateLabel.textColor = .label
        searchEmptyStateLabel.textAlignment = .center
        searchEmptyStateLabel.numberOfLines = 0
        searchEmptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        searchEmptyStateView.addSubview(searchEmptyStateImageView)
        searchEmptyStateView.addSubview(searchEmptyStateLabel)
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
            
            // Search Bar
            searchBar.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 0
            ),
            searchBar.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 8
            ),
            searchBar.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -8
            ),

            // Content View
            contentView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 24),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            ),

            // Collection View
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),
            collectionView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor
            ),

            // Placeholder Stack View
            placeholderStackView.centerXAnchor.constraint(
                equalTo: contentView.centerXAnchor
            ),
            placeholderStackView.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            
            // Search Empty State View - по центру экрана
            searchEmptyStateView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            searchEmptyStateView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // Search Empty State Image
            searchEmptyStateImageView.centerXAnchor.constraint(equalTo: searchEmptyStateView.centerXAnchor),
            searchEmptyStateImageView.topAnchor.constraint(equalTo: searchEmptyStateView.topAnchor),
            searchEmptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            searchEmptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Search Empty State Label - отступы 16px по бокам, 8px снизу от картинки
            searchEmptyStateLabel.topAnchor.constraint(equalTo: searchEmptyStateImageView.bottomAnchor, constant: 8),
            searchEmptyStateLabel.leadingAnchor.constraint(equalTo: searchEmptyStateView.leadingAnchor, constant: 16),
            searchEmptyStateLabel.trailingAnchor.constraint(equalTo: searchEmptyStateView.trailingAnchor, constant: -16),
            searchEmptyStateLabel.bottomAnchor.constraint(equalTo: searchEmptyStateView.bottomAnchor),
            
            // Filters Button - по центру, 16px над табами
            filtersButton.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            filtersButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            ),
            filtersButton.widthAnchor.constraint(equalToConstant: 114),
            filtersButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    /// Скрывает кнопку фильтров, если нет трекеров на выбранный день
    /// Проверяет наличие трекеров БЕЗ учета фильтра
    private func updateFiltersButtonVisibility() {
        let hasAnyTrackersOnDate = checkIfAnyTrackersExistOnDate()
        filtersButton.isHidden = !hasAnyTrackersOnDate
    }
    
    /// Проверяет, есть ли трекеры на выбранную дату БЕЗ учета фильтра
    private func checkIfAnyTrackersExistOnDate() -> Bool {
        let calendar = Calendar.current
        let weekdayFromCalendar = calendar.component(.weekday, from: currentDate)
        
        // Преобразуем из календарного формата (1=воскресенье) в наш формат (1=понедельник)
        let filterWeekday: Int
        if weekdayFromCalendar == 1 {
            filterWeekday = 7
        } else {
            filterWeekday = weekdayFromCalendar - 1
        }
        
        // Проверяем все трекеры без фильтра по завершенности
        for section in 0..<trackerStore.numberOfSections {
            for item in 0..<trackerStore.numberOfObjects(in: section) {
                let indexPath = IndexPath(item: item, section: section)
                let trackerCD = trackerStore.object(at: indexPath)
                
                guard let tracker = trackerStore.tracker(from: trackerCD) else { continue }
                guard let schedule = tracker.schedule else { continue }
                let weekday = Weekday(rawValue: filterWeekday) ?? .mon
                
                // Если трекер соответствует расписанию на этот день - значит есть трекеры
                if schedule.contains(weekday) {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Обновляет внешний вид кнопки фильтров
    /// Белый цвет = фильтр не активен (.all или .today)
    /// Красный цвет = фильтр активен (.completed или .notCompleted)
    private func updateFiltersButtonAppearance() {
        let isFilterActive = selectedFilter == .completed || selectedFilter == .notCompleted
        filtersButton.setTitleColor(isFilterActive ? .systemRed : .white, for: .normal)
    }

    private func updatePlaceholderVisibility() {
        let isEmpty = visibleCategories.isEmpty
        let hasSearchText = !(searchBar.text?.isEmpty ?? true)
        let hasActiveFilter = selectedFilter == .completed || selectedFilter == .notCompleted
        
        // Если есть поисковый запрос, но нет результатов - показываем empty state поиска
        if hasSearchText && isEmpty {
            searchEmptyStateView.isHidden = false
            placeholderStackView.isHidden = true
            collectionView.isHidden = true
        } else if isEmpty && hasActiveFilter {
            // Если фильтр активен и ничего не найдено - показываем заглушку "Ничего не найдено"
            searchEmptyStateView.isHidden = false
            placeholderStackView.isHidden = true
            collectionView.isHidden = true
        } else if isEmpty {
            // Если нет трекеров вообще - показываем обычный placeholder
            searchEmptyStateView.isHidden = true
            placeholderStackView.isHidden = false
            collectionView.isHidden = true
        } else {
            // Есть результаты - показываем collection view
            searchEmptyStateView.isHidden = true
            placeholderStackView.isHidden = true
            collectionView.isHidden = false
        }
    }
}
extension TrackersViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Вызывается при каждом изменении текста в поисковой строке
        applyDateFilter()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Вызывается при нажатии кнопки "Поиск" на клавиатуре
        applyDateFilter()
        searchBar.resignFirstResponder()  // Скрыть клавиатуру
    }
}

// MARK: - UICollectionViewDataSource
extension TrackersViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return visibleCategories.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return visibleCategories[section].trackers.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: "TrackerCell",
                for: indexPath
            ) as! TrackerCell

        let category = visibleCategories[indexPath.section]
        let tracker = category.trackers[indexPath.item]

        cell.delegate = self
        cell.contextMenuDelegate = self
        let isCompletedToday = isTrackerCompletedToday(id: tracker.id)
        let completedDays = completedTrackers.filter {
            $0.trackerId == tracker.id
        }.count
        cell.configure(
            with: tracker,
            category: category.title,
            onPlusTapped: { },
            isCompletedToday: isCompletedToday,
            completedDays: completedDays,
            indexPath: indexPath
        )

        return cell
    }

    private func isTrackerCompletedToday(id: UUID) -> Bool {
        return isTrackerCompleted(id: id, date: currentDate)
    }
    
    private func isTrackerCompleted(id: UUID, date: Date) -> Bool {
        return completedTrackers.contains { record in
            let isSameDay = Calendar.current.isDate(
                record.date,
                inSameDayAs: date
            )
            return record.trackerId == id && isSameDay
        }
    }

}
extension TrackersViewController: TrackerCellDelegate {

    func completetracker(id: UUID, at indexPath: IndexPath) {
        // Проверяем, что дата не в будущем
        let today = Date()
        let calendar = Calendar.current
        if calendar.isDate(currentDate, inSameDayAs: today)
            || currentDate < today
        {
            // 1. Обновляем локальный массив
            let trackerRecord = TrackerRecord(trackerId: id, date: currentDate)
            completedTrackers.append(trackerRecord)
            
            // 2. Сохраняем в Core Data
            do {
                if let trackerCD = try trackerStore.findTracker(by: id) {
                    try recordStore.addRecord(tracker: trackerCD, date: currentDate)
                    
                    // Отслеживаем аналитику завершения трекера
                    AnalyticsService.click(screen: .main, item: .complete)
                }
            } catch {
                // Ошибка сохранения записи в Core Data
            }

            // 3. Пересчитываем фильтрацию (трекер может появиться/исчезнуть в зависимости от фильтра)
            applyDateFilter()
        }
    }

    func uncompleteTracker(id: UUID, at indexPath: IndexPath) {
        // Проверяем, что дата не в будущем
        let today = Date()
        let calendar = Calendar.current
        if calendar.isDate(currentDate, inSameDayAs: today)
            || currentDate < today
        {
            // 1. Удаляем из локального массива
            completedTrackers.removeAll { record in
                let isSameDay = Calendar.current.isDate(
                    record.date,
                    inSameDayAs: currentDate
                )
                return record.trackerId == id && isSameDay
            }
            
            // 2. Удаляем из Core Data
            do {
                try recordStore.deleteRecord(trackerId: id, date: currentDate)
                
                // Отслеживаем аналитику отмены завершения трекера
                AnalyticsService.click(screen: .main, item: .uncomplete)
            } catch {
                // Ошибка удаления записи из Core Data
            }

            // 3. Пересчитываем фильтрацию (трекер может появиться/исчезнуть в зависимости от фильтра)
            applyDateFilter()
        }
    }
}

// MARK: - TrackerCellContextMenuDelegate
extension TrackersViewController: TrackerCellContextMenuDelegate {
    func trackerCellDidRequestPin(at indexPath: IndexPath) {
        let category = visibleCategories[indexPath.section]
        let tracker = category.trackers[indexPath.item]
        
        do {
            try trackerStore.togglePin(for: tracker.id)
            // Обновляем данные после изменения
            applyDateFilter()
        } catch {
            showAlert(title: "Ошибка", message: "Не удалось изменить статус закрепления")
        }
    }
    
    func trackerCellDidRequestEdit(at indexPath: IndexPath) {
        let category = visibleCategories[indexPath.section]
        let tracker = category.trackers[indexPath.item]
        
        // Подсчитываем количество выполненных дней
        let completedDays = completedTrackers.filter {
            $0.trackerId == tracker.id
        }.count
        
        // Используем категорию из visibleCategories, которая уже содержит этот трекер
        let trackerCategory = TrackerCategory(title: category.title, trackers: [])
        
        // Загружаем все категории для выбора
        var categories: [TrackerCategory] = []
        do {
            let categoriesCD = try categoryStore.fetchAllCategories()
            categories = categoriesCD.compactMap { categoryCD in
                guard let title = categoryCD.title else { return nil }
                return TrackerCategory(title: title, trackers: [])
            }
        } catch {
            // Ошибка загрузки категорий
        }
        
        let editVC = EditTrackerViewController(tracker: tracker, completedDays: completedDays)
        editVC.categories = categories
        editVC.selectedCategory = trackerCategory
        editVC.delegate = self
        
        present(editVC, animated: true)
    }
    
    func trackerCellDidRequestDelete(at indexPath: IndexPath) {
        let category = visibleCategories[indexPath.section]
        let tracker = category.trackers[indexPath.item]
        
        // Сохраняем indexPath и trackerId для использования в делегате
        currentDeleteIndexPath = indexPath
        currentDeleteTrackerId = tracker.id
        
        showBottomDeleteAlert(for: indexPath)
    }
    
    private func showBottomDeleteAlert(for indexPath: IndexPath) {
        guard let trackerId = currentDeleteTrackerId else { return }
        
        let deleteView = DeleteConfirmationView()
        deleteView.show(
            in: self,
            message: "Уверены что хотите удалить трекер?",
            onConfirm: { [weak self] in
                guard let self = self,
                      let indexPath = self.currentDeleteIndexPath,
                      let trackerId = self.currentDeleteTrackerId else { return }
                self.deleteTracker(at: indexPath, trackerId: trackerId)
            }
        )
        self.deleteConfirmationView = deleteView
        self.currentDeleteIndexPath = indexPath
    }
    
    private func deleteTracker(at indexPath: IndexPath, trackerId: UUID) {
        do {
            // Удаляем из Core Data
            if let trackerCD = try trackerStore.findTracker(by: trackerId) {
                try trackerStore.deleteTracker(trackerCD)
            }
            
            // Обновляем UI через applyDateFilter
            applyDateFilter()
        } catch {
            showAlert(title: "Ошибка", message: "Не удалось удалить трекер")
        }
    }
    
}

// MARK: - FiltersViewControllerDelegate
extension TrackersViewController: FiltersViewControllerDelegate {
    func didSelectFilter(_ filter: FilterType) {
        selectedFilter = filter
        
        // Для фильтра "Трекеры на сегодня" автоматически устанавливаем текущую дату
        if filter == .today {
            currentDate = Date()
            datePicker?.date = Date()
        }
        
        // Перезагружаем записи при смене фильтра
        do {
            try loadCompletedRecords()
        } catch {
            // Ошибка загрузки записей
        }
        applyDateFilter()
        updateFiltersButtonAppearance()
    }
}

extension TrackersViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let headerView =
                collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: "SectionHeader",
                    for: indexPath
                ) as! SectionHeaderView

            let category = visibleCategories[indexPath.section]
            headerView.configure(with: category.title)
            return headerView
        }
        return UICollectionReusableView()
    }
}
// MARK: - UICollectionViewDelegateFlowLayout
extension TrackersViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = (collectionView.frame.width - 48) / 2  // 16*2 (insets) + 16 (spacing) = 48
        return CGSize(width: width, height: 148)
    }
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 18)
    }
}
extension TrackersViewController: AddTrackerViewControllerDelegate {
    func didCreateTracker(_ tracker: Tracker, in category: TrackerCategory) {
        // Находим или создаем категорию в Core Data
        do {
            let categoryCD = try categoryStore.findOrCreateCategory(title: category.title)
            try trackerStore.addTracker(tracker, category: categoryCD)
            // FRC автоматически обновит UI через делегат
        } catch {
            // Ошибка добавления трекера
        }
    }
}

// MARK: - StoreChangesDelegate
extension TrackersViewController: StoreChangesDelegate {
    func trackerRecordsDidUpdate() {
        //
    }
    
    func storeWillChangeContent() {
        // Подготавливаемся к батч-обновлениям
        pendingChanges.removeAll()
    }
    
    func storeDidChangeSection(at sectionIndex: Int, for type: StoreChangeType) {
        // Сохраняем изменения секций для выполнения в батче
        switch type {
        case .insert:
            pendingChanges.append {
                self.collectionView.insertSections(IndexSet(integer: sectionIndex))
            }
        case .delete:
            pendingChanges.append {
                self.collectionView.deleteSections(IndexSet(integer: sectionIndex))
            }
        default:
            break
        }
    }
    
    func storeDidChangeObject(at indexPath: IndexPath?, for type: StoreChangeType, newIndexPath: IndexPath?) {
        // Сохраняем изменения объектов для выполнения в батче
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                pendingChanges.append {
                    // Проверяем, что секция существует перед вставкой элемента
                    if newIndexPath.section < self.collectionView.numberOfSections {
                        self.collectionView.insertItems(at: [newIndexPath])
                    } else {
                        // Если секции нет, обновляем данные полностью
                        self.applyDateFilter()
                    }
                }
            }
        case .delete:
            if let indexPath = indexPath {
                pendingChanges.append {
                    // Проверяем, что секция и элемент существуют перед удалением
                    if indexPath.section < self.collectionView.numberOfSections &&
                       indexPath.item < self.collectionView.numberOfItems(inSection: indexPath.section) {
                        self.collectionView.deleteItems(at: [indexPath])
                    } else {
                        // Если что-то не так, обновляем данные полностью
                        self.applyDateFilter()
                    }
                }
            }
        case .update:
            if let indexPath = indexPath {
                pendingChanges.append {
                    // Проверяем, что элемент существует перед обновлением
                    if indexPath.section < self.collectionView.numberOfSections &&
                       indexPath.item < self.collectionView.numberOfItems(inSection: indexPath.section) {
                        self.collectionView.reloadItems(at: [indexPath])
                    } else {
                        // Если что-то не так, обновляем данные полностью
                        self.applyDateFilter()
                    }
                }
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                pendingChanges.append {
                    // Проверяем, что оба индекса существуют перед перемещением
                    if indexPath.section < self.collectionView.numberOfSections &&
                       indexPath.item < self.collectionView.numberOfItems(inSection: indexPath.section) &&
                       newIndexPath.section < self.collectionView.numberOfSections &&
                       newIndexPath.item < self.collectionView.numberOfItems(inSection: newIndexPath.section) {
                        self.collectionView.moveItem(at: indexPath, to: newIndexPath)
                    } else {
                        // Если что-то не так, обновляем данные полностью
                        self.applyDateFilter()
                    }
                }
            }
        @unknown default:
            break
        }
    }
    
    func storeDidChangeContent() {
        // Временно используем простой reloadData для тестирования
        // TODO: Восстановить батч-обновления после отладки
        DispatchQueue.main.async {
            self.applyDateFilter()
        }
        pendingChanges.removeAll()
    }
}

// MARK: - EditTrackerViewControllerDelegate
extension TrackersViewController: EditTrackerViewControllerDelegate {
    func didUpdateTracker(_ tracker: Tracker) {
        // Изменения уже сохранены в Core Data через EditTrackerViewController
        // Обновляем UI
        applyDateFilter()
    }
}
