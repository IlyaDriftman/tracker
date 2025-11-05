import UIKit

protocol CategoryViewControllerDelegate: AnyObject {
    func didSelectCategory(_ category: TrackerCategory?)
}

protocol CategoryCellDelegate: AnyObject {
    func categoryCellDidRequestEdit(at indexPath: IndexPath)
    func categoryCellDidRequestDelete(at indexPath: IndexPath)
}

final class CategoryViewController: AnalyticsViewController {
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
        analyticsScreenName = .selectCategory
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
        let deleteView = DeleteConfirmationView()
        deleteView.show(
            in: self,
            message: "Эта категория точно не нужна?",
            onConfirm: { [weak self] in
                self?.viewModel.deleteCategory(at: indexPath.row)
            }
        )
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
    private var contextMenuInteraction: UIContextMenuInteraction?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupContextMenu()
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
    
    private func setupContextMenu() {
        if #available(iOS 13.0, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            addInteraction(interaction)
            contextMenuInteraction = interaction
        }
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
