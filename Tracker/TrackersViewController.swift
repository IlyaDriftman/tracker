import UIKit

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

    private var trackers: [Tracker] = []
    private var visibleCategories: [TrackerCategory] = []
    private var categories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    private var currentDate: Date
    let defaultCategory = TrackerCategory(
        title: "Общее",
        trackers: []
    )

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
        categories = [defaultCategory]
        setupTestData()
        reloadData()
    }

    // MARK: - Actions
    private func reloadData() {
        applyDateFilter()
    }

    @objc private func plusButtonTapped() {
        let addTrackerVC = AddTrackerViewController()
        addTrackerVC.delegate = self
        addTrackerVC.categories = categories
        present(addTrackerVC, animated: true)
    }

    private func applyDateFilter() {

        let filterText = (searchBar.text ?? "").lowercased()
        let calendar = Calendar.current
        let weekdayFromCalendar = calendar.component(
            .weekday,
            from: currentDate
        )

        // Преобразуем из календарного формата (1=воскресенье) в наш формат (1=понедельник)
        let filterWeekday: Int
        if weekdayFromCalendar == 1 {  // воскресенье в календаре
            filterWeekday = 7  // воскресенье в нашем enum
        } else {
            filterWeekday = weekdayFromCalendar - 1
        }

        visibleCategories = categories.compactMap { category in
            let trackers = category.trackers.filter { tracker in
                let textCondition =
                    filterText.isEmpty
                    || tracker.title.lowercased().contains(filterText)
                guard let schedule = tracker.schedule else { return false }
                let weekday = Weekday(rawValue: filterWeekday) ?? .mon
                return schedule.contains(weekday) && textCondition
            }

            if trackers.isEmpty {
                return nil
            }

            return TrackerCategory(
                title: category.title,
                trackers: trackers
            )
        }
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

    private func setupTestData() {
        // Создаем тестовые трекеры
        let tracker1 = Tracker(
            id: UUID(),
            title: "Полить цветы",
            color: .systemBlue,
            emoji: "🌱",
            schedule: .custom([.mon, .wed])
        )

        let tracker2 = Tracker(
            id: UUID(),
            title: "Позвонить маме",
            color: .systemRed,
            emoji: "📞",
            schedule: .weekdays
        )

        let tracker3 = Tracker(
            id: UUID(),
            title: "Позвонить всем",
            color: .systemRed,
            emoji: "📞",
            schedule: .custom([.mon, .wed])
        )

        trackers = [tracker1, tracker2, tracker3]

        // Создаем тестовые категории
        let habitCategory = TrackerCategory(
            title: "Важно",
            trackers: [tracker1]
        )
        let eventCategory = TrackerCategory(
            title: "После работы",
            trackers: [tracker2, tracker3]
        )

        categories += [habitCategory, eventCategory]

        // Применяем фильтр для инициализации visibleCategories
        applyDateFilter()
    }

    private func updatePlaceholderVisibility() {
        let isEmpty = visibleCategories.isEmpty
        
        placeholderStackView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
        
    }
}
extension TrackersViewController: UISearchBarDelegate {

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
            let trackerRecord = TrackerRecord(trackerId: id, date: currentDate)
            completedTrackers.append(trackerRecord)

            // Обновляем только иконку кнопки без перезагрузки ячейки
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
            completedTrackers.removeAll { TrackerRecord in
                isSameTrackerRecord(trackerRecord: TrackerRecord, id: id)
            }

            // Обновляем только иконку кнопки без перезагрузки ячейки
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
extension TrackersViewController:
    AddTrackerViewControllerDelegate
{

    func didCreateTracker(_ tracker: Tracker, in category: TrackerCategory) {
        // Находим индекс категории в основном массиве categories
        if let categoryIndex = categories.firstIndex(where: {
            $0.title == category.title
        }) {
            var oldCategory = categories[categoryIndex]

            // создаём новый массив трекеров
            let updatedTrackers = oldCategory.trackers + [tracker]

            // создаём новый объект категории
            let updatedCategory = TrackerCategory(
                title: oldCategory.title,
                trackers: updatedTrackers
            )

            // заменяем в массиве категорий
            categories[categoryIndex] = updatedCategory

            applyDateFilter()
        }
    }
}
