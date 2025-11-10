import UIKit

enum FilterType: String, CaseIterable {
    case all = "Все трекеры"
    case today = "Трекеры на сегодня"
    case completed = "Завершенные"
    case notCompleted = "Не завершенные"
}

protocol FiltersViewControllerDelegate: AnyObject {
    func didSelectFilter(_ filter: FilterType)
}

final class FiltersViewController: AnalyticsViewController {
    weak var delegate: FiltersViewControllerDelegate?
    var selectedFilter: FilterType = .all
    
    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let title = UILabel()
        title.text = "Фильтры"
        title.font = .boldSystemFont(ofSize: 16)
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()
   

    private let tableView: UITableView = {
        let table = UITableView()
        
        table.register(
            FilterCell.self,
            forCellReuseIdentifier: FilterCell.reuseIdentifier
        )
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.layer.cornerRadius = 16
        table.clipsToBounds = true
        table.translatesAutoresizingMaskIntoConstraints = false
        table.tableFooterView = UIView()
        table.contentInsetAdjustmentBehavior = .never
        table.isScrollEnabled = false
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        analyticsScreenName = .selectCategory // TODO: добавить экран фильтров в enum
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(titleLabel)
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 24
            ),
            titleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 16
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -16
            ),
            
            // Table View
            tableView.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
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
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            ),
        ])
    }
}

// MARK: - UITableViewDataSource
extension FiltersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FilterType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FilterCell.reuseIdentifier,
            for: indexPath
        ) as? FilterCell else {
            assertionFailure("Не удалось привести ячейку к FilterCell")
            return UITableViewCell()
        }

        let filter = FilterType.allCases[indexPath.row]
        // Галочка не показывается для "Все трекеры" и "Трекеры на сегодня"
        let isSelected = filter == selectedFilter && (filter != .all && filter != .today)
        
        cell.configure(with: filter.rawValue, isSelected: isSelected, indexPath: indexPath)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FiltersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedFilter = FilterType.allCases[indexPath.row]
        self.selectedFilter = selectedFilter
        
        // Обновляем UI
        tableView.reloadData()
        
        // Уведомляем делегата
        delegate?.didSelectFilter(selectedFilter)
        
        // Закрываем экран фильтров
        dismiss(animated: true)
    }
}

// MARK: - FilterCell
class FilterCell: UITableViewCell {
    static let reuseIdentifier = String(describing: FilterCell.self)
    private let titleLabel = UILabel()
    private let checkmarkImageView = UIImageView(image: UIImage(systemName: "checkmark"))
    private var indexPath: IndexPath?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor(named: "filterBg")
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
        indexPath = nil
    }
    
    func configure(with title: String, isSelected: Bool, indexPath: IndexPath) {
        titleLabel.text = title
        checkmarkImageView.isHidden = !isSelected
        self.indexPath = indexPath
    }
}

