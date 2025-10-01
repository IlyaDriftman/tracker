import UIKit

protocol CategoryViewControllerDelegate: AnyObject {
    func didSelectCategory(_ category: TrackerCategory?)
}

final class CategoryViewController: UIViewController {
    weak var delegate: CategoryViewControllerDelegate?
    var categories: [TrackerCategory] = []
    var selectedCategory: TrackerCategory?

    private let tableView = UITableView()
    private let doneButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
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

        // Done Button
        doneButton.setTitle("Готово", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = UIColor(
            red: 0.102,
            green: 0.106,
            blue: 0.133,
            alpha: 1.0
        )  // #1A1B22
        doneButton.layer.cornerRadius = 16
        doneButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        doneButton.addTarget(
            self,
            action: #selector(doneButtonTapped),
            for: .touchUpInside
        )
        doneButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(doneButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Table View
            tableView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 16
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
                equalTo: doneButton.topAnchor,
                constant: -20
            ),

            // Done Button
            doneButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor
            ),
            doneButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),
            doneButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),
            doneButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }

    @objc private func doneButtonTapped() {
        // Всегда вызываем delegate, даже если ничего не выбрано
        delegate?.didSelectCategory(selectedCategory)
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension CategoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        return categories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "CategoryCell",
            for: indexPath
        ) as! CategoryCell
        let category = categories[indexPath.row]
        let isSelected = category.title == selectedCategory?.title
        cell.configure(with: category.title, isSelected: isSelected)

        return cell
    }
}

// MARK: - UITableViewDelegate
extension CategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        selectedCategory = categories[indexPath.row]
        tableView.reloadData()
    }
}

class CategoryCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark"))
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
            private func setupUI() {
                backgroundColor = .systemGray6
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
    
    func configure(with title: String, isSelected: Bool) {
        titleLabel.text = title
        checkmarkImageView.isHidden = !isSelected
    }
}
