import UIKit
import CoreData

class TrackersViewController: UIViewController {

    // MARK: - UI Elements
    private let searchBar = UISearchBar()
    private let contentView = UIView()
    private let placeholderStackView = UIStackView()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private var dateButton = UIButton()
    private let plusImage = UIImage(named: "plus")

    // MARK: - Properties
    private var datePicker: UIDatePicker?
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
        setupUI()
        setupCoreData()
        reloadData()
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
            print("Ошибка загрузки данных: \(error)")
        }
    }
    
    
    private func removeTestCategoryIfExists() throws {
        let categories = try categoryStore.allCategories()
        for (index, category) in categories.enumerated() {
            if category.title == "Тестовая категория" {
                try categoryStore.deleteCategory(at: index)
                print("Удалена тестовая категория")
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
            print("Ошибка загрузки категорий: \(error)")
            addTrackerVC.categories = []
        }
        present(addTrackerVC, animated: true)
    }

    private func applyDateFilter() {
        let filterText = (searchBar.text ?? "").lowercased()
        let calendar = Calendar.current
        let weekdayFromCalendar = calendar.component(.weekday, from: currentDate)

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
            print("[applyDateFilter in TrackersViewController]: predicate update error filterText=\(filterText)")
        }

        // Группируем трекеры по категориям из Core Data
        var categoriesDict: [String: [Tracker]] = [:]
        
        for section in 0..<trackerStore.numberOfSections {
            let sectionTitle = trackerStore.sectionTitle(at: section) ?? "Без категории"
            
            for item in 0..<trackerStore.numberOfObjects(in: section) {
                let indexPath = IndexPath(item: item, section: section)
                let trackerCD = trackerStore.object(at: indexPath)
                
                guard let tracker = trackerStore.tracker(from: trackerCD) else { continue }
                
                let textCondition = filterText.isEmpty || tracker.title.lowercased().contains(filterText)
                guard let schedule = tracker.schedule else { continue }
                let weekday = Weekday(rawValue: filterWeekday) ?? .mon
                
                if schedule.contains(weekday) && textCondition {
                    if categoriesDict[sectionTitle] == nil {
                        categoriesDict[sectionTitle] = []
                    }
                    categoriesDict[sectionTitle]?.append(tracker)
                }
            }
        }
        
        // Преобразуем в массив категорий
        visibleCategories = categoriesDict.compactMap { (title, trackers) in
            guard !trackers.isEmpty else { return nil }
            return TrackerCategory(title: title, trackers: trackers)
        }.sorted { $0.title < $1.title }
        
        collectionView.reloadData()
        updatePlaceholderVisibility()
    }

    @objc private func dateChanged() {
        currentDate = datePicker?.date ?? Date()
        applyDateFilter()
    }

    private func handleTrackerPlusTapped() {
        print("Tracker plus tapped")
    }

    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Setup navigation bar
        setupNavigationBar()

        // Setup UI elements
        setupTitleLabel()
        setupSearchBar()
        setupContentView()
        setupPlaceholderStackView()

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

        setupConstraints()
    }

    private func setupNavigationBar() {
        // Date picker
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.locale = Locale(identifier: "ru_RU")
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
        searchBar.placeholder = "Поиск"
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        searchBar.barTintColor = .clear
        searchBar.isTranslucent = true
        searchBar.delegate = self
    }

    private func setupTitleLabel() {
        titleLabel.text = "Трекеры"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .systemBackground
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
            contentView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
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
        ])
    }


    private func updatePlaceholderVisibility() {
        let isEmpty = visibleCategories.isEmpty
        
        placeholderStackView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
        
    }
}
extension TrackersViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Вызывается при каждом изменении текста в поисковой строке
        print("Поиск изменен: '\(searchText)'")
        applyDateFilter()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // Вызывается при нажатии кнопки "Поиск" на клавиатуре
        print("Нажата кнопка поиска")
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
        let isCompletedToday = isTrackerCompletedToday(id: tracker.id)
        let completedDays = completedTrackers.filter {
            $0.trackerId == tracker.id
        }.count
        cell.configure(
            with: tracker,
            category: category.title,
            onPlusTapped: { [weak self] in
                self?.handleTrackerPlusTapped()
            },
            isCompletedToday: isCompletedToday,
            completedDays: completedDays,
            indexPath: indexPath
        )

        return cell
    }

    private func isTrackerCompletedToday(id: UUID) -> Bool {

        return completedTrackers.contains { TrackerRecord in
            isSameTrackerRecord(trackerRecord: TrackerRecord, id: id)
        }
    }
    private func isSameTrackerRecord(trackerRecord: TrackerRecord, id: UUID)
        -> Bool
    {
        let isSameDay = Calendar.current.isDate(
            trackerRecord.date,
            inSameDayAs: currentDate
        )
        return trackerRecord.trackerId == id && isSameDay
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
                }
            } catch {
                print("[completetracker in TrackersViewController]: Core Data save error id=\(id)")
            }

            // 3. Обновляем UI
            if let cell = collectionView.cellForItem(at: indexPath)
                as? TrackerCell
            {
                let isCompletedToday = isTrackerCompletedToday(id: id)
                let completedDays = completedTrackers.filter {
                    $0.trackerId == id
                }.count
                cell.updateButtonState(
                    isCompletedToday: isCompletedToday,
                    completedDays: completedDays
                )
            }
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
            completedTrackers.removeAll { TrackerRecord in
                isSameTrackerRecord(trackerRecord: TrackerRecord, id: id)
            }
            
            // 2. Удаляем из Core Data
            do {
                try recordStore.deleteRecord(trackerId: id, date: currentDate)
            } catch {
                print("[uncompleteTracker in TrackersViewController]: Core Data delete error id=\(id)")
            }

            // 3. Обновляем UI
            if let cell = collectionView.cellForItem(at: indexPath)
                as? TrackerCell
            {
                let isCompletedToday = isTrackerCompletedToday(id: id)
                let completedDays = completedTrackers.filter {
                    $0.trackerId == id
                }.count
                cell.updateButtonState(
                    isCompletedToday: isCompletedToday,
                    completedDays: completedDays
                )
            }
        }
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
            print("Ошибка добавления трекера: \(error)")
        }
    }
}

// MARK: - StoreChangesDelegate
extension TrackersViewController: StoreChangesDelegate {
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
