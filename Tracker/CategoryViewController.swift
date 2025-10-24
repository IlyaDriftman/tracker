import UIKit

protocol CategoryViewControllerDelegate: AnyObject {
    func didSelectCategory(_ category: TrackerCategory?)
}

protocol CategoryCellDelegate: AnyObject {
    func categoryCellDidRequestEdit(at indexPath: IndexPath)
    func categoryCellDidRequestDelete(at indexPath: IndexPath)
}

final class CategoryViewController: UIViewController {
    weak var delegate: CategoryViewControllerDelegate?
    var selectedCategory: TrackerCategory? // Выбранная категория для отображения галочки
    
    // MARK: - MVVM Properties
    private let viewModel: CategoryViewModelProtocol
    
    // MARK: - UI Elements
    private let tableView = UITableView()
    private let addCategoryButton = UIButton(type: .system)
    
    // MARK: - Empty State Elements
    private let emptyStateView = UIView()
    private let emptyStateImageView = UIImageView()
    private let emptyStateLabel = UILabel()
    
    // MARK: - Editing Properties
    private var currentEditingIndexPath: IndexPath?
    
    
    // MARK: - Initialization
    init(viewModel: CategoryViewModelProtocol = CategoryViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setupBindings()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
       // setupContextMenu()
        viewModel.loadCategories()
        
        // Устанавливаем выбранную категорию после загрузки
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.setSelectedCategory(self?.selectedCategory)
        }
    }
    
    // MARK: - MVVM Setup
    private func setupBindings() {
        // Привязываем ViewModel к View через замыкания
        viewModel.onCategoriesUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.updateEmptyState()
            }
        }
        
        viewModel.onSelectionChanged = { [weak self] selectedIndex in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                // Вызываем делегат при выборе категории
                if let selectedIndex = selectedIndex {
                    let selectedCategory = self?.viewModel.getCategoryData(for: selectedIndex)
                    let category = selectedCategory
                    self?.delegate?.didSelectCategory(category)
                }
            }
        }
        
        viewModel.onError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Ошибка", message: errorMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
        
        // Устанавливаем делегат для ViewModel
        viewModel.delegate = self
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Title
        title = "Категория"

        // Table View
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            CategoryCell.self,
            forCellReuseIdentifier: "CategoryCell"
        )
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.isScrollEnabled = false

        // Add Category Button
        addCategoryButton.setTitle("Добавить категорию", for: .normal)
        addCategoryButton.setTitleColor(.white, for: .normal)
        addCategoryButton.backgroundColor = UIColor(named: "trackerBlack")
        addCategoryButton.layer.cornerRadius = 16
        addCategoryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        addCategoryButton.addTarget(
            self,
            action: #selector(addCategoryButtonTapped),
            for: .touchUpInside
        )
        addCategoryButton.translatesAutoresizingMaskIntoConstraints = false

        // Empty State
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateImageView.image = UIImage(named: "1")
        emptyStateImageView.contentMode = .scaleAspectFit
        emptyStateImageView.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateLabel.text = "Привычки и события можно\nобъединить по смыслу"
        emptyStateLabel.font = .systemFont(ofSize: 12)
        emptyStateLabel.textColor = UIColor(hex: "#1A1B22")
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        emptyStateView.addSubview(emptyStateImageView)
        emptyStateView.addSubview(emptyStateLabel)

        view.addSubview(tableView)
        view.addSubview(addCategoryButton)
        view.addSubview(emptyStateView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Table View
            tableView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 24
            ),
            tableView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 16
            ),
            tableView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -16
            ),
            tableView.bottomAnchor.constraint(
                equalTo: addCategoryButton.topAnchor,
                constant: -20
            ),

            // Add Category Button - 16px от низа экрана
            addCategoryButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            ),
            addCategoryButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),
            addCategoryButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),
            addCategoryButton.heightAnchor.constraint(equalToConstant: 60),
            
            // Empty State View - по центру экрана
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Empty State Image - 80x80, отступ 8px снизу от текста
            emptyStateImageView.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateImageView.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Empty State Label - отступы 16px по бокам, 8px снизу от картинки
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor, constant: 8),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 16),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -16),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor),
        ])
    }

    private func updateEmptyState() {
        let hasCategories = viewModel.numberOfCategories > 0
        emptyStateView.isHidden = hasCategories
        tableView.isHidden = !hasCategories
    }
    
    @objc private func addCategoryButtonTapped() {
        let addCategoryVC = AddCategoryViewController()
        addCategoryVC.delegate = self
        
        let navController = UINavigationController(rootViewController: addCategoryVC)
        present(navController, animated: true)
    }
    
    // MARK: - Context Menu Setup
   
    private func editCategory(at indexPath: IndexPath, currentTitle: String) {
        let editCategoryVC = EditCategoryViewController(currentTitle: currentTitle)
        editCategoryVC.delegate = self
        
        let navController = UINavigationController(rootViewController: editCategoryVC)
        present(navController, animated: true)
        
        // Сохраняем indexPath для использования в делегате
        currentEditingIndexPath = indexPath
    }
    
    private func deleteCategory(at indexPath: IndexPath, title: String) {
        showBottomDeleteAlert(for: indexPath)
    }
    
    private func showBottomDeleteAlert(for indexPath: IndexPath) {
        // Создаем контейнер для диалога
        let containerView = UIView()
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Создаем action sheet
        let actionSheetView = UIView()
        actionSheetView.backgroundColor = .clear
        actionSheetView.translatesAutoresizingMaskIntoConstraints = false
        
        // Блок с текстом и кнопкой удалить
        let contentView = UIView()
        contentView.backgroundColor = UIColor(hex: "#F5F5F5B2")
        contentView.layer.cornerRadius = 13
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Сообщение
        let messageLabel = UILabel()
        messageLabel.text = "Эта категория точно не нужна?"
        messageLabel.font = .systemFont(ofSize: 13)
        messageLabel.textColor = UIColor(hex: "#3C3C4399")
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Сепаратор
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor(hex: "#3C3C435C")
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        
        // Кнопка "Удалить" (красный текст, без фона)
        let deleteButton = UIButton(type: .system)
        deleteButton.setTitle("Удалить", for: .normal)
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.backgroundColor = .clear
        deleteButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(confirmDelete), for: .touchUpInside)
        
        // Кнопка "Отменить" (белая с синим текстом)
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Отменить", for: .normal)
        cancelButton.setTitleColor(.systemBlue, for: .normal)
        cancelButton.backgroundColor = .white
        cancelButton.layer.cornerRadius = 16
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelDelete), for: .touchUpInside)
        
        // Добавляем элементы
        view.addSubview(containerView)
        containerView.addSubview(actionSheetView)
        actionSheetView.addSubview(contentView)
        contentView.addSubview(messageLabel)
        contentView.addSubview(separatorView)
        contentView.addSubview(deleteButton)
        actionSheetView.addSubview(cancelButton) // Кнопка отмены поверх contentView
        
        // Констрейнты
        NSLayoutConstraint.activate([
            // Контейнер на весь экран
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Action sheet снизу, перекрывает список
            actionSheetView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            actionSheetView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            actionSheetView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Content view (блок с текстом и кнопкой удалить) - 8px над кнопкой отмена
            contentView.leadingAnchor.constraint(equalTo: actionSheetView.leadingAnchor, constant: 8),
            contentView.trailingAnchor.constraint(equalTo: actionSheetView.trailingAnchor, constant: -8),
            contentView.topAnchor.constraint(equalTo: actionSheetView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -8),
            
            // Сообщение (отступы 12px сверху и снизу, высота блока с текстом 42px)
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            messageLabel.heightAnchor.constraint(equalToConstant: 18), // Блок с текстом 18px
            
            // Сепаратор под текстом (после отступа 12px)
            separatorView.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 12),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),
            
            // Кнопка "Удалить" под сепаратором (высота 61px, по центру)
            deleteButton.topAnchor.constraint(equalTo: separatorView.bottomAnchor),
            deleteButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            deleteButton.heightAnchor.constraint(equalToConstant: 61), // Высота кнопки 61px
            deleteButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Кнопка "Отменить" (высота 61px, отступ сверху 8px, снизу 32px)
            cancelButton.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 8),
            cancelButton.leadingAnchor.constraint(equalTo: actionSheetView.leadingAnchor, constant: 8),
            cancelButton.trailingAnchor.constraint(equalTo: actionSheetView.trailingAnchor, constant: -8),
            cancelButton.heightAnchor.constraint(equalToConstant: 61),
            cancelButton.bottomAnchor.constraint(equalTo: actionSheetView.bottomAnchor, constant: -32)
        ])
        
        // Анимация появления снизу
        actionSheetView.transform = CGAffineTransform(translationX: 0, y: 200)
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            actionSheetView.transform = .identity
        }
        
        // Сохраняем ссылки для удаления
        self.currentDeleteContainer = containerView
        self.currentDeleteIndexPath = indexPath
    }
    
    private var currentDeleteContainer: UIView?
    private var currentDeleteIndexPath: IndexPath?
    
    @objc private func confirmDelete() {
        guard let indexPath = currentDeleteIndexPath else { return }
        viewModel.deleteCategory(at: indexPath.row)
        dismissDeleteAlert()
    }
    
    @objc private func cancelDelete() {
        dismissDeleteAlert()
    }
    
    private func dismissDeleteAlert() {
        guard let container = currentDeleteContainer else { return }
        UIView.animate(withDuration: 0.3, animations: {
            container.alpha = 0
        }) { _ in
            container.removeFromSuperview()
        }
        currentDeleteContainer = nil
        currentDeleteIndexPath = nil
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension CategoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCategories
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "CategoryCell",
            for: indexPath
        ) as! CategoryCell
        
        // Получаем данные из ViewModel
        guard let categoryData = viewModel.getCategoryDataForCell(for: indexPath.row) else {
            return cell
        }
        
        cell.configure(with: categoryData.title, isSelected: categoryData.isSelected, indexPath: indexPath)
        cell.contextMenuDelegate = self
        return cell
    }
}

// MARK: - UITableViewDelegate
extension CategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectCategory(at: indexPath.row)
        
        // Закрываем экран выбора категории при выборе
        dismiss(animated: true)
    }
}

// MARK: - CategoryViewModelDelegate
extension CategoryViewController: CategoryViewModelDelegate {
    func didSelectCategory(_ category: TrackerCategory?) {
        delegate?.didSelectCategory(category)
    }
}

// MARK: - AddCategoryViewControllerDelegate
extension CategoryViewController: AddCategoryViewControllerDelegate {
    func didAddCategory(_ categoryTitle: String) {
        viewModel.addCategory(categoryTitle)
    }
}

// MARK: - CategoryCellDelegate
extension CategoryViewController: CategoryCellDelegate {
    func categoryCellDidRequestEdit(at indexPath: IndexPath) {
        guard let categoryData = viewModel.getCategoryDataForCell(for: indexPath.row) else { return }
        editCategory(at: indexPath, currentTitle: categoryData.title)
    }
    
    func categoryCellDidRequestDelete(at indexPath: IndexPath) {
        guard let categoryData = viewModel.getCategoryDataForCell(for: indexPath.row) else { return }
        deleteCategory(at: indexPath, title: categoryData.title)
    }
}

// MARK: - EditCategoryViewControllerDelegate
extension CategoryViewController: EditCategoryViewControllerDelegate {
    func didUpdateCategory(_ categoryTitle: String) {
        guard let indexPath = currentEditingIndexPath else { return }
        viewModel.updateCategory(at: indexPath.row, newTitle: categoryTitle)
        currentEditingIndexPath = nil
    }
}

class CategoryCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark"))
    
    // Делегат для контекстного меню
    weak var contextMenuDelegate: CategoryCellDelegate?
    private var indexPath: IndexPath?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
       // setupContextMenu()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
            private func setupUI() {
                backgroundColor = UIColor(hex: "#E6E8EB4D")
                selectionStyle = .none
        
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        checkmarkImageView.tintColor = .systemBlue
        checkmarkImageView.isHidden = true
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
            override func layoutSubviews() {
                super.layoutSubviews()
                
                // Добавляем разделитель только если это не последняя ячейка
                if let tableView = superview as? UITableView,
                   let indexPath = tableView.indexPath(for: self) {
                    let isLastCell = indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
                    
                    // Удаляем все существующие разделители
                    layer.sublayers?.removeAll { $0.name == "separator" }
                    
                    if !isLastCell {
                        let separator = CALayer()
                        separator.name = "separator"
                        separator.backgroundColor = UIColor.systemGray4.cgColor
                        separator.frame = CGRect(x: 16, y: bounds.height - 0.5, width: bounds.width - 32, height: 0.5)
                        layer.addSublayer(separator)
                    }
                    
                    // Добавляем скругление для первой и последней ячейки
                    let isFirstCell = indexPath.row == 0
                    if isFirstCell && isLastCell {
                        // Если только одна ячейка - скругляем все углы
                        layer.cornerRadius = 16
                        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                    } else if isFirstCell {
                        // Первая ячейка - скругляем верхние углы
                        layer.cornerRadius = 16
                        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    } else if isLastCell {
                        // Последняя ячейка - скругляем нижние углы
                        layer.cornerRadius = 16
                        layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                    } else {
                        // Средние ячейки - без скругления
                        layer.cornerRadius = 0
                        layer.maskedCorners = []
                    }
                }
            }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        checkmarkImageView.isHidden = true
    }
    
    func configure(with title: String, isSelected: Bool, indexPath: IndexPath) {
        titleLabel.text = title
        checkmarkImageView.isHidden = !isSelected
        self.indexPath = indexPath
    }
}

// MARK: - UIContextMenuInteractionDelegate
@available(iOS 13.0, *)
extension CategoryCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let indexPath = indexPath else { return nil }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let editAction = UIAction(title: "Редактировать") { _ in
                self.contextMenuDelegate?.categoryCellDidRequestEdit(at: indexPath)
            }
            
            let deleteAction = UIAction(title: "Удалить", attributes: .destructive) { _ in
                self.contextMenuDelegate?.categoryCellDidRequestDelete(at: indexPath)
            }
            
            let menu = UIMenu(title: "", children: [editAction, deleteAction])
            menu.preferredElementSize = .large
            
            return menu
        }
    }
}
