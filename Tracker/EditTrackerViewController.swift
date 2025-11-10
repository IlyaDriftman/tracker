import UIKit

protocol EditTrackerViewControllerDelegate: AnyObject {
    func didUpdateTracker(_ tracker: Tracker)
}

extension EditTrackerViewController: CategoryViewControllerDelegate {
    func didSelectCategory(_ category: TrackerCategory?) {
        selectedCategory = category
        updateCategoryButtonTitle()
    }
}

class EditTrackerViewController: AnalyticsViewController {
    weak var delegate: EditTrackerViewControllerDelegate?
    var categories: [TrackerCategory] = []
    var selectedCategory: TrackerCategory? {
        didSet {
            // Обновляем UI при изменении категории
            if isViewLoaded {
                updateCategoryButtonTitle()
            }
        }
    }
    
    // MARK: - Editing Properties
    private let tracker: Tracker
    private var completedDays: Int
    private let recordStore = TrackerRecordStore()
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    
    // Поле с количеством дней
    private let daysView = UIView()
    private let daysContainer = UIView()
    private let daysLabel = UILabel()
    
    private let nameView = UIView()
    private let nameTextField = UITextField()
    private let nameErrorLabel = UILabel()
    private let optionsContainer = UIView()
    private let categoryButton = UIButton(type: .system)
    private let scheduleButton = UIButton(type: .system)
    private let categoryScheduleSeparator = UIView()
    private let collectionView: UICollectionView
    private let buttonsContainer = UIView()
    private let cancelButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private var categoryStack: UIStackView!
    private var scheduleStack: UIStackView!
    private var categoryTitleLabel: UILabel?
    private var categorySelectedLabel: UILabel?
    private var scheduleDaysLabel: UILabel?
    
    // MARK: - Properties
    private let weekdays = [
        "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота",
        "Воскресенье",
    ]
    private var selectedWeekdays: Set<Weekday> = []
    private var selectedEmoji: String?
    private var selectedColor: UIColor?
    private let heightHeader: CGFloat = 18
    
    private let emojis = AppConstants.emojis
    private let colors = AppConstants.colors
    
    // MARK: - Initialization
    init(tracker: Tracker, completedDays: Int) {
        self.tracker = tracker
        self.completedDays = completedDays
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        layout.sectionInset = UIEdgeInsets(
            top: 24,
            left: 8,
            bottom: 46,
            right: 8
        )
        
        collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout
        )
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        analyticsScreenName = .addTrackers // TODO: добавить экран редактирования в enum
        setupUI()
        setupConstraints()
        setupInitialValues()
        updateDaysLabel()
        updateCategoryButtonTitle()
        updateScheduleButtonTitle()
        updateSaveButtonState()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Принудительно обновляем layout collectionView после установки constraints
        if collectionView.bounds.width > 0 {
            collectionView.layoutIfNeeded()
            
            // Вычисляем необходимую высоту collectionView на основе содержимого
            if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                var totalHeight: CGFloat = 0
                
                // Параметры для расчета
                let itemSize: CGFloat = 52
                let itemSpacing: CGFloat = flowLayout.minimumInteritemSpacing // 5
                let lineSpacing: CGFloat = flowLayout.minimumLineSpacing // 5
                let sectionInsetLeft: CGFloat = flowLayout.sectionInset.left // 8
                let sectionInsetRight: CGFloat = flowLayout.sectionInset.right // 8
                let headerHeight: CGFloat = 18
                let sectionTopInset: CGFloat = flowLayout.sectionInset.top // 24
                let sectionBottomInset: CGFloat = flowLayout.sectionInset.bottom // 46
                
                // Доступная ширина для ячеек (collectionView уже имеет отступы 16px слева и справа)
                let availableWidth = collectionView.bounds.width - sectionInsetLeft - sectionInsetRight
                
                // Количество элементов в ряду
                let itemsPerRow = max(1, Int((availableWidth + itemSpacing) / (itemSize + itemSpacing)))
                
                // Высота для секции эмодзи
                let emojiRows = (emojis.count + itemsPerRow - 1) / itemsPerRow
                let emojiItemsHeight = CGFloat(emojiRows) * itemSize + CGFloat(max(0, emojiRows - 1)) * lineSpacing
                let emojiSectionHeight = headerHeight + sectionTopInset + emojiItemsHeight + sectionBottomInset
                
                // Высота для секции цветов
                let colorRows = (colors.count + itemsPerRow - 1) / itemsPerRow
                let colorItemsHeight = CGFloat(colorRows) * itemSize + CGFloat(max(0, colorRows - 1)) * lineSpacing
                let colorSectionHeight = headerHeight + sectionTopInset + colorItemsHeight + sectionBottomInset
                
                totalHeight = emojiSectionHeight + colorSectionHeight
                
                // Обновляем height constraint для collectionView
                collectionView.constraints.forEach { constraint in
                    if constraint.firstAttribute == .height {
                        constraint.isActive = false
                    }
                }
                collectionView.heightAnchor.constraint(equalToConstant: totalHeight).isActive = true
                collectionView.layoutIfNeeded()
                
                // Перезагружаем данные только после того, как collectionView имеет правильные размеры
                if collectionView.numberOfSections == 0 {
                    collectionView.reloadData()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Перезагружаем данные перед появлением экрана
        collectionView.reloadData()
    }
    
    private func setupInitialValues() {
        // Заполняем поля данными трекера
        nameTextField.text = tracker.title
        selectedEmoji = tracker.emoji
        selectedColor = tracker.color
        
        if let schedule = tracker.schedule {
            switch schedule {
            case .everyDay:
                selectedWeekdays = Set(Weekday.allCases)
            case .weekdays:
                selectedWeekdays = [.mon, .tue, .wed, .thu, .fri]
            case .custom(let weekdays):
                selectedWeekdays = weekdays
            }
        }
        
        // Находим категорию трекера
        // TODO: нужно получить категорию из Core Data
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        nameView.translatesAutoresizingMaskIntoConstraints = false
        nameView.backgroundColor = .clear // Убеждаемся, что nameView виден
        
        // Title
        titleLabel.text = "Редактирование привычки"
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Days View
        daysView.translatesAutoresizingMaskIntoConstraints = false
        daysContainer.backgroundColor = .clear
        daysContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Label с количеством дней
        daysLabel.textAlignment = .center
        daysLabel.font = .boldSystemFont(ofSize: 32)
        daysLabel.textColor = .label
        daysLabel.translatesAutoresizingMaskIntoConstraints = false
        
        daysContainer.addSubview(daysLabel)
        daysView.addSubview(daysContainer)
        
        // Name TextField
        nameTextField.placeholder = "Введите название трекера"
        nameTextField.borderStyle = .none
        nameTextField.backgroundColor = UIColor(hex: "#E6E8EB4D")
        nameTextField.layer.cornerRadius = 16
        nameTextField.delegate = self
        nameTextField.addTarget(
            self,
            action: #selector(nameTextFieldChanged),
            for: .editingChanged
        )
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        
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
        )
        nameErrorLabel.textAlignment = .center
        nameErrorLabel.isHidden = true
        nameErrorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Category Button (аналогично AddTrackerViewController)
        categoryButton.backgroundColor = .clear
        categoryButton.translatesAutoresizingMaskIntoConstraints = false
        categoryButton.contentHorizontalAlignment = .fill
        categoryButton.adjustsImageWhenHighlighted = false
        categoryButton.showsTouchWhenHighlighted = false
        
        let categoryTitleLabel = UILabel()
        categoryTitleLabel.text = "Категория"
        categoryTitleLabel.textColor = .label
        categoryTitleLabel.font = .systemFont(ofSize: 17)
        categoryTitleLabel.textAlignment = .left
        categoryTitleLabel.numberOfLines = 1 // Ограничиваем одной строкой
        self.categoryTitleLabel = categoryTitleLabel // Сохраняем ссылку
        
        let categorySelectedLabel = UILabel()
        categorySelectedLabel.text = ""
        categorySelectedLabel.textColor = .systemGray
        categorySelectedLabel.font = .systemFont(ofSize: 15)
        categorySelectedLabel.textAlignment = .left
        categorySelectedLabel.numberOfLines = 1 // Ограничиваем одной строкой
        self.categorySelectedLabel = categorySelectedLabel // Сохраняем ссылку
        
        let categoryTextStackView = UIStackView()
        categoryTextStackView.axis = .vertical
        categoryTextStackView.alignment = .leading
        categoryTextStackView.spacing = 2
        categoryTextStackView.distribution = .fill
        categoryTextStackView.addArrangedSubview(categoryTitleLabel)
        categoryTextStackView.addArrangedSubview(categorySelectedLabel)
        
        // Убеждаемся, что label'ы не перекрываются
        categoryTitleLabel.setContentHuggingPriority(.required, for: .vertical)
        categorySelectedLabel.setContentHuggingPriority(.required, for: .vertical)
        categoryTitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        categorySelectedLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        let categoryArrowImageView = UIImageView(
            image: UIImage(systemName: "chevron.right")
        )
        categoryArrowImageView.tintColor = .systemGray2
        
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
        
        // Schedule Button (аналогично AddTrackerViewController)
        scheduleButton.backgroundColor = .clear
        scheduleButton.translatesAutoresizingMaskIntoConstraints = false
        scheduleButton.contentHorizontalAlignment = .fill
        scheduleButton.adjustsImageWhenHighlighted = false
        scheduleButton.showsTouchWhenHighlighted = false
        
        let scheduleTitleLabel = UILabel()
        scheduleTitleLabel.text = "Расписание"
        scheduleTitleLabel.textColor = .label
        scheduleTitleLabel.font = .systemFont(ofSize: 17)
        scheduleTitleLabel.textAlignment = .left
        
        let scheduleDaysLabel = UILabel()
        scheduleDaysLabel.text = ""
        scheduleDaysLabel.textColor = .systemGray
        scheduleDaysLabel.font = .systemFont(ofSize: 15)
        scheduleDaysLabel.textAlignment = .left
        scheduleDaysLabel.numberOfLines = 0
        self.scheduleDaysLabel = scheduleDaysLabel // Сохраняем ссылку
        
        let textStackView = UIStackView()
        textStackView.axis = .vertical
        textStackView.alignment = .leading
        textStackView.spacing = 2
        textStackView.addArrangedSubview(scheduleTitleLabel)
        textStackView.addArrangedSubview(scheduleDaysLabel)
        
        let scheduleArrowImageView = UIImageView(
            image: UIImage(systemName: "chevron.right")
        )
        scheduleArrowImageView.tintColor = .systemGray2
        
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
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "EmojiColorHeaderView"
        )
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false  // Отключаем скролл, так как collectionView внутри scrollView
        
        // Buttons
        cancelButton.setTitle("Отменить", for: .normal)
        cancelButton.setTitleColor(
            UIColor(red: 0.961, green: 0.420, blue: 0.424, alpha: 1.0),
            for: .normal
        )
        cancelButton.backgroundColor = .clear
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor =
            UIColor(red: 0.961, green: 0.420, blue: 0.424, alpha: 1.0).cgColor
        cancelButton.layer.cornerRadius = 16
        cancelButton.addTarget(
            self,
            action: #selector(cancelButtonTapped),
            for: .touchUpInside
        )
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1.0)
        saveButton.layer.cornerRadius = 16
        saveButton.addTarget(
            self,
            action: #selector(saveButtonTapped),
            for: .touchUpInside
        )
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Buttons Container
        buttonsContainer.backgroundColor = .white
        buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        daysView.addSubview(daysContainer)
        nameView.addSubview(nameTextField)
        nameView.addSubview(nameErrorLabel)
        
        optionsContainer.backgroundColor = UIColor(hex: "#E6E8EB4D")
        optionsContainer.layer.cornerRadius = 16
        optionsContainer.translatesAutoresizingMaskIntoConstraints = false
        
        categoryScheduleSeparator.backgroundColor = .systemGray4
        categoryScheduleSeparator.translatesAutoresizingMaskIntoConstraints = false
        
        optionsContainer.addSubview(categoryButton)
        optionsContainer.addSubview(scheduleButton)
        optionsContainer.addSubview(categoryScheduleSeparator)
        
        [titleLabel, daysView, nameView, optionsContainer, collectionView, buttonsContainer].forEach {
            contentView.addSubview($0)
        }
        
        // Добавляем кнопки в контейнер
        [cancelButton, saveButton].forEach {
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
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
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
            
            // Days View
            daysView.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 24
            ),
            daysView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            daysView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),
            daysView.heightAnchor.constraint(equalToConstant: 38),
            
            // Days Container
            daysContainer.topAnchor.constraint(equalTo: daysView.topAnchor),
            daysContainer.leadingAnchor.constraint(equalTo: daysView.leadingAnchor),
            daysContainer.trailingAnchor.constraint(equalTo: daysView.trailingAnchor),
            daysContainer.bottomAnchor.constraint(equalTo: daysView.bottomAnchor),
            
            // Days Label - по центру
            daysLabel.centerXAnchor.constraint(equalTo: daysContainer.centerXAnchor),
            daysLabel.centerYAnchor.constraint(equalTo: daysContainer.centerYAnchor),
            
            // Name View
            nameView.topAnchor.constraint(
                equalTo: daysView.bottomAnchor,
                constant: 40
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
            nameTextField.bottomAnchor.constraint(
                equalTo: nameView.bottomAnchor,
                constant: -16
            ),
            
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
            // nameView будет иметь высоту на основе nameTextField (16 + 75 + 16 = 107)
            // Если errorLabel виден, он добавит дополнительную высоту
            
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
            optionsContainer.heightAnchor.constraint(equalToConstant: 151),
            
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
            
            // Separator
            categoryScheduleSeparator.topAnchor.constraint(
                equalTo: categoryButton.bottomAnchor
            ),
            categoryScheduleSeparator.leadingAnchor.constraint(
                equalTo: optionsContainer.leadingAnchor
            ),
            categoryScheduleSeparator.trailingAnchor.constraint(
                equalTo: optionsContainer.trailingAnchor
            ),
            categoryScheduleSeparator.heightAnchor.constraint(equalToConstant: 0.5),
            
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
                constant: 24
            ),
            collectionView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: 16
            ),
            collectionView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -16
            ),

            // Buttons Container - размещаем под collectionView на расстоянии 16px
            buttonsContainer.topAnchor.constraint(
                equalTo: collectionView.bottomAnchor,
                constant: 16
            ),
            buttonsContainer.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor
            ),
            buttonsContainer.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor
            ),
            buttonsContainer.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor
            ),
            buttonsContainer.heightAnchor.constraint(equalToConstant: 60),
            
            // Cancel Button
            cancelButton.leadingAnchor.constraint(
                equalTo: buttonsContainer.leadingAnchor,
                constant: 20
            ),
            cancelButton.topAnchor.constraint(
                equalTo: buttonsContainer.topAnchor
            ),
            cancelButton.bottomAnchor.constraint(
                equalTo: buttonsContainer.bottomAnchor
            ),
            cancelButton.widthAnchor.constraint(
                equalTo: saveButton.widthAnchor
            ),
            cancelButton.trailingAnchor.constraint(
                equalTo: saveButton.leadingAnchor,
                constant: -8
            ),
            
            // Save Button
            saveButton.trailingAnchor.constraint(
                equalTo: buttonsContainer.trailingAnchor,
                constant: -20
            ),
            saveButton.topAnchor.constraint(
                equalTo: buttonsContainer.topAnchor
            ),
            saveButton.bottomAnchor.constraint(
                equalTo: buttonsContainer.bottomAnchor
            ),
        ])
    }
    
    // MARK: - Actions
    private func updateDaysLabel() {
        let wordDay = pluralizeDays(completedDays)
        daysLabel.text = "\(completedDays) \(wordDay)"
    }
    
    private func pluralizeDays(_ count: Int) -> String {
        let remainder = count % 10
        let remainder100 = count % 100
        
        if remainder100 >= 11 && remainder100 <= 19 {
            return "дней"
        } else if remainder == 1 {
            return "день"
        } else if remainder >= 2 && remainder <= 4 {
            return "дня"
        } else {
            return "дней"
        }
    }
    
    @objc private func nameTextFieldChanged() {
        // Аналогично AddTrackerViewController
        updateSaveButtonState()
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let name = nameTextField.text, !name.isEmpty else {
            showAlert(title: "Ошибка", message: "Введите название трекера")
            return
        }
        
        guard let selectedEmoji = selectedEmoji else {
            showAlert(title: "Ошибка", message: "Выберите эмодзи")
            return
        }
        
        guard let selectedColor = selectedColor else {
            showAlert(title: "Ошибка", message: "Выберите цвет")
            return
        }
        
        guard let categoryToUse = selectedCategory else {
            showAlert(title: "Ошибка", message: "Выберите категорию")
            return
        }
        
        // Сохраняем изменения в Core Data
        do {
            let trackerStore = TrackerStore()
            let categoryStore = TrackerCategoryStore()
            
            // Находим категорию в Core Data
            let categoriesCD = try categoryStore.fetchAllCategories()
            guard let categoryCD = categoriesCD.first(where: { $0.title == categoryToUse.title }) else {
                showAlert(title: "Ошибка", message: "Категория не найдена")
                return
            }
            
            // Обновляем трекер (сохраняем isPinned из оригинального трекера)
            let updatedTracker = Tracker(
                id: tracker.id,
                title: name,
                color: selectedColor,
                emoji: selectedEmoji,
                schedule: selectedWeekdays.isEmpty ? nil : .custom(selectedWeekdays),
                isPinned: tracker.isPinned
            )
            
            try trackerStore.updateTracker(updatedTracker, category: categoryCD)
            
            delegate?.didUpdateTracker(updatedTracker)
            dismiss(animated: true)
        } catch {
            showAlert(title: "Ошибка", message: "Не удалось сохранить изменения")
        }
    }
    
    @objc private func categoryButtonTapped() {
        let categoryVC = CategoryViewController()
        categoryVC.selectedCategory = selectedCategory
        categoryVC.delegate = self
        
        let navController = UINavigationController(rootViewController: categoryVC)
        present(navController, animated: true)
    }
    
    @objc private func scheduleButtonTapped() {
        let scheduleVC = ScheduleViewController()
        scheduleVC.selectedWeekdays = selectedWeekdays
        scheduleVC.onWeekdaysChanged = { [weak self] weekdays in
            self?.selectedWeekdays = weekdays
            self?.updateScheduleButtonTitle()
        }
        
        let navController = UINavigationController(
            rootViewController: scheduleVC
        )
        present(navController, animated: true)
    }
    
    private func updateCategoryButtonTitle() {
        // Находим textStackView и обновляем оба label'а явно
        guard let textStackView = categoryStack.arrangedSubviews.first as? UIStackView,
              textStackView.arrangedSubviews.count >= 2 else {
            return
        }
        
        // Первый элемент (индекс 0) - это "Категория" (titleLabel)
        if let titleLabel = textStackView.arrangedSubviews[0] as? UILabel {
            titleLabel.text = "Категория"
            titleLabel.textColor = .label
            titleLabel.font = .systemFont(ofSize: 17)
            titleLabel.numberOfLines = 1
            titleLabel.isHidden = false
        }
        
        // Второй элемент (индекс 1) - это выбранная категория (selectedLabel)
        if let selectedLabel = textStackView.arrangedSubviews[1] as? UILabel {
            // Очищаем текст перед установкой нового
            selectedLabel.text = ""
            
            // Убеждаемся, что мы НЕ используем tracker.title
            if let category = selectedCategory {
                // ВАЖНО: используем category.title, а НЕ tracker.title!
                selectedLabel.text = category.title
            } else {
                selectedLabel.text = ""
            }
            
            selectedLabel.textColor = .systemGray
            selectedLabel.font = .systemFont(ofSize: 15)
            selectedLabel.numberOfLines = 1
            selectedLabel.isHidden = false
        }
        
        // Также обновляем сохраненные ссылки для консистентности
        if let categoryTitleLabel = categoryTitleLabel {
            categoryTitleLabel.text = "Категория"
        }
        
        if let categorySelectedLabel = categorySelectedLabel {
            // ВАЖНО: используем category.title, а НЕ tracker.title!
            if let category = selectedCategory {
                categorySelectedLabel.text = category.title
            } else {
                categorySelectedLabel.text = ""
            }
        }
    }
    
    private func updateScheduleButtonTitle() {
        if let scheduleDaysLabel = scheduleDaysLabel {
            if selectedWeekdays.isEmpty {
                scheduleDaysLabel.text = ""
            } else if selectedWeekdays.count == 7 {
                scheduleDaysLabel.text = "Каждый день"
            } else {
                let selectedDays = selectedWeekdays.sorted {
                    $0.rawValue < $1.rawValue
                }
                let shortDayNames = selectedDays.map {
                    getShortDayName(for: $0)
                }
                scheduleDaysLabel.text = shortDayNames.joined(separator: ", ")
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
    
    private func updateSaveButtonState() {
        let hasName = !(nameTextField.text?.isEmpty ?? true)
        let hasEmoji = selectedEmoji != nil
        let hasColor = selectedColor != nil
        
        if hasName && hasEmoji && hasColor {
            saveButton.backgroundColor = UIColor(named: "trackerBlack")
        } else {
            saveButton.backgroundColor = UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1.0)
        }
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
}

// MARK: - UITextFieldDelegate
extension EditTrackerViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let currentText = textField.text ?? ""
        let newLength = currentText.count + string.count - range.length
        
        if newLength > 38 {
            nameErrorLabel.isHidden = false
            return false
        } else {
            nameErrorLabel.isHidden = true
            return true
        }
    }
}

// MARK: - UICollectionViewDataSource
extension EditTrackerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2 // Эмодзи и цвета
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
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "EmojiColorCell",
            for: indexPath
        ) as! EmojiColorCell
        
        if indexPath.section == 0 {
            let emoji = emojis[indexPath.item]
            let isSelected = selectedEmoji == emoji
            cell.configureEmoji(with: emoji, isSelected: isSelected)
        } else {
            let color = colors[indexPath.item]
            let isSelected = areColorsEqual(selectedColor, color)
            cell.configureColor(with: color, isSelected: isSelected)
        }
        
        return cell
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
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
extension EditTrackerViewController: UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        if indexPath.section == 0 {
            selectedEmoji = emojis[indexPath.item]
        } else {
            selectedColor = colors[indexPath.item]
        }
        collectionView.reloadData()
        updateSaveButtonState()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension EditTrackerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: 52, height: 52)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: heightHeader)
    }
}

