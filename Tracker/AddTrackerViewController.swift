import UIKit

protocol AddTrackerViewControllerDelegate: AnyObject {
    func didCreateTracker(_ tracker: Tracker, in category: TrackerCategory)
}

extension AddTrackerViewController: CategoryViewControllerDelegate {
    func didSelectCategory(_ category: TrackerCategory?) {
        // Если категория выбрана - используем её, иначе оставляем "Общее"
        if let category = category {
            selectedCategory = category
        } else {
            // Если ничего не выбрано, остается "Общее" по умолчанию
            selectedCategory = TrackerCategory(title: "Общее", trackers: [])
        }
        
        // Находим textStackView внутри categoryStack
        if let textStackView = categoryStack.arrangedSubviews.first
            as? UIStackView,
            let titleLabel = textStackView.arrangedSubviews.first as? UILabel,
            let selectedLabel = textStackView.arrangedSubviews.last as? UILabel
        {
            titleLabel.text = "Категория"
            selectedLabel.text = selectedCategory?.title ?? "Общее"
        }
        updateCreateButtonState()
    }
}

class AddTrackerViewController: UIViewController {
    weak var delegate: AddTrackerViewControllerDelegate?
    var categories: [TrackerCategory] = []
    var selectedCategory: TrackerCategory?
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let nameView = UIView()
    private let titleLabel = UILabel()
    private let nameTextField = UITextField()
    private let nameErrorLabel = UILabel()
    private let optionsContainer = UIView()
    private let categoryButton = UIButton(type: .system)
    private let scheduleButton = UIButton(type: .system)
    private let categoryScheduleSeparator = UIView()  // между категорией и расписанием
    private let collectionView: UICollectionView
    private let buttonsContainer = UIView()
    private let cancelButton = UIButton(type: .system)
    private let createButton = UIButton(type: .system)
    private var categoryStack: UIStackView!
    private var scheduleStack: UIStackView!
    private var nameViewHeightConstraint: NSLayoutConstraint!

    // MARK: - Properties
    private let weekdays = [
        "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота",
        "Воскресенье",
    ]
    private var selectedWeekdays: Set<Weekday> = []
    private var selectedEmoji: String?
    private var selectedColor: UIColor?
    private let heightHeader: CGFloat = 18

    let emojis = [
        "🌱", "💧", "🏃‍♂️", "📚", "🍎", "💪", "🎯", "🌟", "🔥",
        "💡", "🎨", "🎵", "⚽", "🎮", "🎭", "🎪", "🚴‍♂️", "🧘‍♀️",
    ]

    private let colors: [(String, UIColor)] = [
        ("Красный", UIColor(red: 0.961, green: 0.420, blue: 0.424, alpha: 1.0)),  // #F56B6C
        (
            "Оранжевый",
            UIColor(red: 0.992, green: 0.584, blue: 0.318, alpha: 1.0)
        ),  // #FD9531
        ("Желтый", UIColor(red: 0.996, green: 0.769, blue: 0.318, alpha: 1.0)),  // #FEC451
        ("Зеленый", UIColor(red: 0.459, green: 0.820, blue: 0.408, alpha: 1.0)),  // #75D168
        ("Голубой", UIColor(red: 0.318, green: 0.737, blue: 0.996, alpha: 1.0)),  // #51BCFE
        ("Синий", UIColor(red: 0.216, green: 0.447, blue: 0.906, alpha: 1.0)),  // #3772E7
        (
            "Фиолетовый",
            UIColor(red: 0.584, green: 0.318, blue: 0.996, alpha: 1.0)
        ),  // #9551FE
        ("Розовый", UIColor(red: 0.996, green: 0.318, blue: 0.737, alpha: 1.0)),  // #FE51BC
        (
            "Коричневый",
            UIColor(red: 0.584, green: 0.318, blue: 0.216, alpha: 1.0)
        ),  // #955135
        ("Серый", UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1.0)),  // #AEAFB4
        ("Черный", UIColor(red: 0.102, green: 0.106, blue: 0.133, alpha: 1.0)),  // #1A1B22
        ("Лавандовый", UIColor(red: 0.694, green: 0.612, blue: 0.851, alpha: 1.0)),  // #B19CD9
        ("Темно-зеленый", UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)),
        ("Темно-синий", UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1.0)),
        ("Золотой", UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0)),
        ("Серебряный", UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0)),
        ("Бирюзовый", UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 1.0)),
        ("Лавандовый", UIColor(red: 0.9, green: 0.9, blue: 0.98, alpha: 1.0)),
    ]
    // private var selectedCategory: String?

    // MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        layout.sectionInset = UIEdgeInsets(
            top: 24,  // Отступ от заголовка до ячеек
            left: 8,
            bottom: 16,
            right: 8
        )

        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupDefaultCategory()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        nameView.translatesAutoresizingMaskIntoConstraints = false

        // Title
        titleLabel.text = "Новая привычка"
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Name TextField
        nameTextField.placeholder = "Введите название трекера"
        nameTextField.borderStyle = .none
        nameTextField.backgroundColor = .systemGray6
        nameTextField.layer.cornerRadius = 16
        nameTextField.delegate = self
        nameTextField.addTarget(
            self,
            action: #selector(nameTextFieldChanged),
            for: .editingChanged
        )
        nameTextField.translatesAutoresizingMaskIntoConstraints = false

        // Добавляем внутренний отступ для текста
        let leftPaddingView = UIView(
            frame: CGRect(x: 0, y: 0, width: 16, height: 0)
        )
        nameTextField.leftView = leftPaddingView
        nameTextField.leftViewMode = .always

        // Name Error Label
        nameErrorLabel.text = "Ограничение 38 символов"
        nameErrorLabel.font = .systemFont(ofSize: 17)
        nameErrorLabel.textColor = UIColor(
            red: 0.961,
            green: 0.420,
            blue: 0.424,
            alpha: 1.0
        )  // #F56B6C
        nameErrorLabel.textAlignment = .center
        nameErrorLabel.isHidden = true
        nameErrorLabel.translatesAutoresizingMaskIntoConstraints = false

        categoryButton.backgroundColor = .clear
        categoryButton.translatesAutoresizingMaskIntoConstraints = false
        categoryButton.contentHorizontalAlignment = .fill
        categoryButton.adjustsImageWhenHighlighted = false
        categoryButton.showsTouchWhenHighlighted = true
        categoryButton.isEnabled = false

        // Текст "Категория"
        let categoryTitleLabel = UILabel()
        categoryTitleLabel.text = "Категория"
        categoryTitleLabel.textColor = .label
        categoryTitleLabel.font = .systemFont(ofSize: 17)
        categoryTitleLabel.textAlignment = .left

        // Текст для выбранной категории
        let categorySelectedLabel = UILabel()
        categorySelectedLabel.text = ""
        categorySelectedLabel.textColor = .systemGray
        categorySelectedLabel.font = .systemFont(ofSize: 15)
        categorySelectedLabel.textAlignment = .left
        categorySelectedLabel.numberOfLines = 0
        

        // Вертикальный StackView для текста
        let categoryTextStackView = UIStackView()
        categoryTextStackView.axis = .vertical
        categoryTextStackView.alignment = .leading
        categoryTextStackView.spacing = 2
        categoryTextStackView.addArrangedSubview(categoryTitleLabel)
        categoryTextStackView.addArrangedSubview(categorySelectedLabel)

        // Стрелка
        let categoryArrowImageView = UIImageView(
            image: UIImage(systemName: "chevron.right")
        )
        categoryArrowImageView.tintColor = .systemGray2

        // Основной StackView
        categoryStack = UIStackView()
        categoryStack.addArrangedSubview(categoryTextStackView)
        categoryStack.addArrangedSubview(UIView())
        categoryStack.addArrangedSubview(categoryArrowImageView)
        categoryStack.axis = .horizontal
        categoryStack.alignment = .center
        categoryStack.spacing = 8
        categoryStack.translatesAutoresizingMaskIntoConstraints = false
        categoryStack.isUserInteractionEnabled = false

        categoryButton.addSubview(categoryStack)
        categoryButton.addTarget(
            self,
            action: #selector(categoryButtonTapped),
            for: .touchUpInside
        )

        // Schedule Button
        scheduleButton.backgroundColor = .clear
        scheduleButton.translatesAutoresizingMaskIntoConstraints = false
        scheduleButton.contentHorizontalAlignment = .fill

        // Текст "Расписание"
        let scheduleTitleLabel = UILabel()
        scheduleTitleLabel.text = "Расписание"
        scheduleTitleLabel.textColor = .label
        scheduleTitleLabel.font = .systemFont(ofSize: 17)
        scheduleTitleLabel.textAlignment = .left

        // Текст для дней недели
        let scheduleDaysLabel = UILabel()
        scheduleDaysLabel.text = ""
        scheduleDaysLabel.textColor = .systemGray
        scheduleDaysLabel.font = .systemFont(ofSize: 15)
        scheduleDaysLabel.textAlignment = .left
        scheduleDaysLabel.numberOfLines = 0

        // Вертикальный StackView для текста
        let textStackView = UIStackView()
        textStackView.axis = .vertical
        textStackView.alignment = .leading
        textStackView.spacing = 2
        textStackView.addArrangedSubview(scheduleTitleLabel)
        textStackView.addArrangedSubview(scheduleDaysLabel)

        // Стрелка
        let scheduleArrowImageView = UIImageView(
            image: UIImage(systemName: "chevron.right")
        )
        scheduleArrowImageView.tintColor = .systemGray2

        // Основной StackView
        scheduleStack = UIStackView()
        scheduleStack.addArrangedSubview(textStackView)
        scheduleStack.addArrangedSubview(UIView())
        scheduleStack.addArrangedSubview(scheduleArrowImageView)
        scheduleStack.axis = .horizontal
        scheduleStack.alignment = .center
        scheduleStack.spacing = 8
        scheduleStack.translatesAutoresizingMaskIntoConstraints = false
        scheduleStack.isUserInteractionEnabled = false

        scheduleButton.addSubview(scheduleStack)
        scheduleButton.addTarget(
            self,
            action: #selector(scheduleButtonTapped),
            for: .touchUpInside
        )

        // Collection View
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            EmojiColorCell.self,
            forCellWithReuseIdentifier: "EmojiColorCell"
        )
        collectionView.register(
            EmojiColorHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView
                .elementKindSectionHeader,
            withReuseIdentifier: "EmojiColorHeaderView"
        )
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = true  // Включаем скролл коллекции

        // Buttons
        cancelButton.setTitle("Отменить", for: .normal)
        cancelButton.setTitleColor(
            UIColor(red: 0.961, green: 0.420, blue: 0.424, alpha: 1.0),
            for: .normal
        )  // #F56B6C
        cancelButton.backgroundColor = .clear
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor =
            UIColor(red: 0.961, green: 0.420, blue: 0.424, alpha: 1.0).cgColor  // #F56B6C
        cancelButton.layer.cornerRadius = 16
        cancelButton.addTarget(
            self,
            action: #selector(cancelButtonTapped),
            for: .touchUpInside
        )
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        createButton.setTitle("Создать", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = UIColor(
            red: 0.682,
            green: 0.686,
            blue: 0.706,
            alpha: 1.0
        )  // #AEAFB4
        createButton.layer.cornerRadius = 16
        createButton.addTarget(
            self,
            action: #selector(createButtonTapped),
            for: .touchUpInside
        )
        createButton.translatesAutoresizingMaskIntoConstraints = false

        // Buttons Container
        buttonsContainer.backgroundColor = .white
        buttonsContainer.translatesAutoresizingMaskIntoConstraints = false

        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        nameView.addSubview(nameTextField)
        nameView.addSubview(nameErrorLabel)

        // Настраиваем контейнер для опций
        optionsContainer.backgroundColor = .systemGray6
        optionsContainer.layer.cornerRadius = 16
        optionsContainer.translatesAutoresizingMaskIntoConstraints = false

        // Настраиваем разделитель
        categoryScheduleSeparator.backgroundColor = .systemGray4
        categoryScheduleSeparator.translatesAutoresizingMaskIntoConstraints = false

        // Добавляем элементы в контейнер
        optionsContainer.addSubview(categoryButton)
        optionsContainer.addSubview(scheduleButton)
        optionsContainer.addSubview(categoryScheduleSeparator)

        [titleLabel, nameView, optionsContainer, collectionView].forEach {
            contentView.addSubview($0)
        }

        // Добавляем контейнер кнопок и кнопки
        view.addSubview(buttonsContainer)
        [cancelButton, createButton].forEach {
            buttonsContainer.addSubview($0)
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(
                equalTo: buttonsContainer.topAnchor
            ),

            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(
                equalTo: scrollView.leadingAnchor
            ),
            contentView.trailingAnchor.constraint(
                equalTo: scrollView.trailingAnchor
            ),
            contentView.bottomAnchor.constraint(
                equalTo: scrollView.bottomAnchor
            ),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(
                greaterThanOrEqualTo: scrollView.heightAnchor
            ),

            // Title
            titleLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: 24
            ),
            titleLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),

            nameView.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 24
            ),
            nameView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            nameView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),

            // Name TextField
            nameTextField.topAnchor.constraint(
                equalTo: nameView.topAnchor,
                constant: 16
            ),
            nameTextField.leadingAnchor.constraint(
                equalTo: nameView.leadingAnchor,
                constant: 16
            ),
            nameTextField.trailingAnchor.constraint(
                equalTo: nameView.trailingAnchor,
                constant: -16
            ),
            nameTextField.heightAnchor.constraint(equalToConstant: 75),

            // Name Error Label
            nameErrorLabel.topAnchor.constraint(
                equalTo: nameTextField.bottomAnchor,
                constant: 8
            ),
            nameErrorLabel.leadingAnchor.constraint(
                equalTo: nameView.leadingAnchor,
                constant: 16
            ),
            nameErrorLabel.trailingAnchor.constraint(
                equalTo: nameView.trailingAnchor,
                constant: -16
            ),

            // Options Container
            optionsContainer.topAnchor.constraint(
                equalTo: nameView.bottomAnchor,
                constant: 24
            ),
            optionsContainer.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            optionsContainer.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            optionsContainer.heightAnchor.constraint(equalToConstant: 151),  // 75*2 + 1*1 (разделитель)

            // Category Button
            categoryButton.topAnchor.constraint(
                equalTo: optionsContainer.topAnchor
            ),
            categoryButton.leadingAnchor.constraint(
                equalTo: optionsContainer.leadingAnchor
            ),
            categoryButton.trailingAnchor.constraint(
                equalTo: optionsContainer.trailingAnchor
            ),
            categoryButton.heightAnchor.constraint(equalToConstant: 75),

            categoryStack.leadingAnchor.constraint(
                equalTo: categoryButton.leadingAnchor,
                constant: 16
            ),
            categoryStack.trailingAnchor.constraint(
                equalTo: categoryButton.trailingAnchor,
                constant: -16
            ),
            categoryStack.topAnchor.constraint(
                equalTo: categoryButton.topAnchor,
                constant: 16
            ),
            categoryStack.bottomAnchor.constraint(
                equalTo: categoryButton.bottomAnchor,
                constant: -16
            ),

            // Category-Schedule Separator
            categoryScheduleSeparator.topAnchor.constraint(
                equalTo: categoryButton.bottomAnchor
            ),
            categoryScheduleSeparator.leadingAnchor.constraint(
                equalTo: optionsContainer.leadingAnchor,
                constant: 16
            ),
            categoryScheduleSeparator.trailingAnchor.constraint(
                equalTo: optionsContainer.trailingAnchor,
                constant: -16
            ),
            categoryScheduleSeparator.heightAnchor.constraint(equalToConstant: 1),

            // Schedule Button
            scheduleButton.topAnchor.constraint(
                equalTo: categoryScheduleSeparator.bottomAnchor
            ),
            scheduleButton.leadingAnchor.constraint(
                equalTo: optionsContainer.leadingAnchor
            ),
            scheduleButton.trailingAnchor.constraint(
                equalTo: optionsContainer.trailingAnchor
            ),
            scheduleButton.heightAnchor.constraint(equalToConstant: 75),

            scheduleStack.leadingAnchor.constraint(
                equalTo: scheduleButton.leadingAnchor,
                constant: 16
            ),
            scheduleStack.trailingAnchor.constraint(
                equalTo: scheduleButton.trailingAnchor,
                constant: -16
            ),
            scheduleStack.topAnchor.constraint(
                equalTo: scheduleButton.topAnchor,
                constant: 16
            ),
            scheduleStack.bottomAnchor.constraint(
                equalTo: scheduleButton.bottomAnchor,
                constant: -16
            ),

            // Collection View
            collectionView.topAnchor.constraint(
                equalTo: optionsContainer.bottomAnchor,
                constant: 32  // Отступ от расписания до заголовка Emoji
            ),
            collectionView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),
            collectionView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: 600
            ),  // Минимальная высота для коллекции
            collectionView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -100
            ),  // Привязываем к низу contentView с отступом для кнопок

            // Buttons Container - прижимаем к низу экрана
            buttonsContainer.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            ),
            buttonsContainer.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            buttonsContainer.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            buttonsContainer.heightAnchor.constraint(equalToConstant: 100),  // Высота контейнера с отступом

            // Buttons - внутри контейнера
            cancelButton.bottomAnchor.constraint(
                equalTo: buttonsContainer.bottomAnchor,
                constant: -20
            ),
            cancelButton.leadingAnchor.constraint(
                equalTo: buttonsContainer.leadingAnchor,
                constant: 20
            ),
            cancelButton.trailingAnchor.constraint(
                equalTo: buttonsContainer.centerXAnchor,
                constant: -4
            ),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),

            createButton.bottomAnchor.constraint(
                equalTo: buttonsContainer.bottomAnchor,
                constant: -20
            ),
            createButton.leadingAnchor.constraint(
                equalTo: buttonsContainer.centerXAnchor,
                constant: 4
            ),
            createButton.trailingAnchor.constraint(
                equalTo: buttonsContainer.trailingAnchor,
                constant: -20
            ),
            createButton.heightAnchor.constraint(equalToConstant: 60),

            // ContentView bottom constraint
            contentView.bottomAnchor.constraint(
                equalTo: scrollView.bottomAnchor
            ),
            contentView.heightAnchor.constraint(
                greaterThanOrEqualTo: scrollView.heightAnchor
            ),
        ])

        // Создаем констрейнт высоты nameView
        nameViewHeightConstraint = nameView.heightAnchor.constraint(
            equalToConstant: 99
        )
        nameViewHeightConstraint.isActive = true
    }

    // MARK: - Actions
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func createButtonTapped() {
        guard let name = nameTextField.text, !name.isEmpty else {
            showAlert(title: "Ошибка", message: "Введите название трекера")
            return
        }

        // Используем выбранную категорию или категорию по умолчанию
        let categoryToUse = selectedCategory ?? getDefaultCategory()

        guard let selectedEmoji = selectedEmoji else {
            showAlert(title: "Ошибка", message: "Выберите эмодзи")
            return
        }

        guard let selectedColor = selectedColor else {
            showAlert(title: "Ошибка", message: "Выберите цвет")
            return
        }

        // Создаем новый трекер
        let newTracker = Tracker(
            id: UUID(),
            title: name,
            color: selectedColor,
            emoji: selectedEmoji,
            schedule: selectedWeekdays.isEmpty ? nil : .custom(selectedWeekdays)
        )

        print("DEBUG: Создаем трекер с цветом: \(selectedColor)")
        print("Created tracker: \(newTracker)")
        delegate?.didCreateTracker(newTracker, in: categoryToUse)
        dismiss(animated: true)
    }

    @objc private func scheduleButtonTapped() {
        let scheduleVC = ScheduleViewController()
        scheduleVC.selectedWeekdays = selectedWeekdays
        scheduleVC.onWeekdaysChanged = { [weak self] weekdays in
            self?.selectedWeekdays = weekdays
            self?.updateScheduleButtonTitle()
            self?.updateCreateButtonState()
        }

        let navController = UINavigationController(
            rootViewController: scheduleVC
        )
        present(navController, animated: true)
    }

    private func updateScheduleButtonTitle() {
        // Находим textStackView внутри scheduleStack
        if let textStackView = scheduleStack.arrangedSubviews.first
            as? UIStackView,
            let titleLabel = textStackView.arrangedSubviews.first as? UILabel,
            let daysLabel = textStackView.arrangedSubviews.last as? UILabel
        {

            if selectedWeekdays.isEmpty {
                titleLabel.text = "Расписание"
                daysLabel.text = ""
            } else if selectedWeekdays.count == 7 {
                // Если выбраны все 7 дней недели
                titleLabel.text = "Расписание"
                daysLabel.text = "Каждый день"
            } else {
                titleLabel.text = "Расписание"
                let selectedDays = selectedWeekdays.sorted {
                    $0.rawValue < $1.rawValue
                }
                let shortDayNames = selectedDays.map {
                    getShortDayName(for: $0)
                }
                daysLabel.text = shortDayNames.joined(separator: ", ")
            }
        }
    }

    private func getShortDayName(for weekday: Weekday) -> String {
        switch weekday {
        case .mon: return "Пн"
        case .tue: return "Вт"
        case .wed: return "Ср"
        case .thu: return "Чт"
        case .fri: return "Пт"
        case .sat: return "Сб"
        case .sun: return "Вс"
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updateCreateButtonState() {
        let hasName = !(nameTextField.text?.isEmpty ?? true) && !isNameTooLong()
        let hasCategory = selectedCategory != nil
        let hasSchedule = !selectedWeekdays.isEmpty
        let hasEmoji = selectedEmoji != nil
        let hasColor = selectedColor != nil
        
        let isEnabled = hasName && hasCategory && hasSchedule && hasEmoji && hasColor
        
        createButton.isEnabled = isEnabled
        let trackerBlack = UIColor(named: "trackerBlack") ?? UIColor(red: 0.102, green: 0.106, blue: 0.133, alpha: 1.0) // #1A1B22
        let trackerGrey = UIColor(named: "trackerGrey") ?? UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1.0) // #AEAFB4
        createButton.backgroundColor = isEnabled ? trackerBlack : trackerGrey
    }

    private func isNameTooLong() -> Bool {
        return (nameTextField.text?.count ?? 0) >= 38
    }

    @objc private func nameTextFieldChanged() {
        let isTooLong = isNameTooLong()
        nameErrorLabel.isHidden = !isTooLong
        updateCreateButtonState()

        // Динамически изменяем высоту nameView
        nameViewHeightConstraint.constant = isTooLong ? 125 : 99
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func categoryButtonTapped() {
        print("Category button tapped!")  // Отладочный print
        let categoryVC = CategoryViewController()
        categoryVC.categories = categories
        categoryVC.selectedCategory = selectedCategory
        categoryVC.delegate = self

        let navController = UINavigationController(
            rootViewController: categoryVC
        )
        present(navController, animated: true)
    }

}

// MARK: - UICollectionViewDataSource
extension AddTrackerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2  // Эмодзи и Цвета
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return section == 0 ? emojis.count : colors.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: "EmojiColorCell",
                for: indexPath
            ) as! EmojiColorCell

        if indexPath.section == 0 {
            let emoji = emojis[indexPath.item]
            let isSelected = emoji == selectedEmoji
            cell.configureEmoji(with: emoji, isSelected: isSelected)
        } else {
            let colorData = colors[indexPath.item]
            let isSelected = areColorsEqual(colorData.1, selectedColor)
            cell.configureColor(with: colorData.1, isSelected: isSelected)
        }

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let header =
            collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "EmojiColorHeaderView",
                for: indexPath
            ) as! EmojiColorHeaderView

        if indexPath.section == 0 {
            header.configure(with: "Emoji")
        } else {
            header.configure(with: "Цвет")
        }

        return header
    }
}

// MARK: - UICollectionViewDelegate
extension AddTrackerViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        if indexPath.section == 0 {
            // Эмодзи секция
            selectedEmoji = emojis[indexPath.item]
        } else {
            // Цвета секция
            let colorData = colors[indexPath.item]
            selectedColor = colorData.1
        }

        collectionView.reloadData()
        updateCreateButtonState()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AddTrackerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: 52, height: 52)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        5  // Расстояние между рядами
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        5  // Расстояние между элементами в ряду
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(width: collectionView.frame.width, height: heightHeader)
    }

    // MARK: - Color Comparison Helper
    private func areColorsEqual(_ firstColor: UIColor?, _ secondColor: UIColor?) -> Bool {
        guard let firstColor = firstColor, let secondColor = secondColor else {
            return firstColor == nil && secondColor == nil
        }
        
        // Конвертируем оба цвета в RGB пространство для корректного сравнения
        let rgbFirstColor = firstColor.converted(to: CGColorSpaceCreateDeviceRGB())
        let rgbSecondColor = secondColor.converted(to: CGColorSpaceCreateDeviceRGB())
        
        guard let firstComponents = rgbFirstColor.components,
              let secondComponents = rgbSecondColor.components,
              firstComponents.count >= 3,
              secondComponents.count >= 3 else {
            return false
        }
        
        // Сравниваем RGB компоненты с небольшой погрешностью
        let tolerance: CGFloat = 0.01
        return abs(firstComponents[0] - secondComponents[0]) < tolerance &&
               abs(firstComponents[1] - secondComponents[1]) < tolerance &&
               abs(firstComponents[2] - secondComponents[2]) < tolerance
    }
    
    // MARK: - Default Category Setup
    private func setupDefaultCategory() {
        // Всегда устанавливаем "Общее" как категорию по умолчанию
        selectedCategory = TrackerCategory(title: "Общее", trackers: [])
        updateCategoryButtonTitle()
    }
    
    private func getDefaultCategory() -> TrackerCategory {
        // Всегда возвращаем "Общее" - либо существующую, либо создаем новую
        if let generalCategory = categories.first(where: { $0.title == "Общее" }) {
            return generalCategory
        } else {
            // Если категории "Общее" нет, создаем временную для передачи в delegate
            return TrackerCategory(title: "Общее", trackers: [])
        }
    }

    private func updateCategoryButtonTitle() {
        guard let selectedCategory = selectedCategory else { return }

        // Находим textStackView внутри categoryStack
        if let textStackView = categoryStack.arrangedSubviews.first
            as? UIStackView,
            let titleLabel = textStackView.arrangedSubviews.first as? UILabel,
            let selectedLabel = textStackView.arrangedSubviews.last as? UILabel
        {

            titleLabel.text = "Категория"
            selectedLabel.text = selectedCategory.title
        }
        updateCreateButtonState()
    }
}

// MARK: - UITextFieldDelegate
extension AddTrackerViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(
            in: range,
            with: string
        )

        // Ограничиваем ввод до 38 символов
        return newText.count <= 38
    }
}
