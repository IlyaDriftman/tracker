import UIKit

final class ScheduleViewController: UIViewController {
    
    // MARK: - UI Elements
    private let tableView = UITableView()
    private let doneButton = UIButton(type: .system)
    
    // MARK: - Properties
    private let weekdays = ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
    var selectedWeekdays: Set<Weekday> = []
    var onWeekdaysChanged: ((Set<Weekday>) -> Void)?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        title = "Расписание"
        view.backgroundColor = .systemBackground
        
        // Table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ScheduleCell.self, forCellReuseIdentifier: "ScheduleCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(hex: "#E6E8EB4D")
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView() // Убираем лишнее пространство
        tableView.contentInsetAdjustmentBehavior = .never
        
        // Done button
        doneButton.setTitle("Готово", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = UIColor(red: 0.102, green: 0.106, blue: 0.133, alpha: 1.0) // #1A1B22
        doneButton.layer.cornerRadius = 16
        doneButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        view.addSubview(doneButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: 525),
            
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    // MARK: - Actions
    @objc private func doneTapped() {
        onWeekdaysChanged?(selectedWeekdays)
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ScheduleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weekdays.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for: indexPath) as! ScheduleCell
        let weekday = Weekday(rawValue: indexPath.row + 1) ?? .mon
        let isSelected = selectedWeekdays.contains(weekday)
        
        cell.configure(with: weekdays[indexPath.row], isSelected: isSelected) { [weak self] isOn in
            if isOn {
                self?.selectedWeekdays.insert(weekday)
            } else {
                self?.selectedWeekdays.remove(weekday)
            }
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ScheduleViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}

// MARK: - ScheduleCell
class ScheduleCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let switchControl = UISwitch()
    
    private var onSwitchChanged: ((Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        titleLabel.font = .systemFont(ofSize: 17)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        switchControl.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.onTintColor = UIColor(red: 0.216, green: 0.447, blue: 0.906, alpha: 1.0) // #3772E7
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(switchControl)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Добавляем разделитель только между ячейками (не под последней)
        if let tableView = superview as? UITableView,
           let indexPath = tableView.indexPath(for: self),
           indexPath.row < tableView.numberOfRows(inSection: indexPath.section) - 1 {
            
            // Удаляем существующий разделитель
            contentView.subviews.forEach { subview in
                if subview.tag == 999 {
                    subview.removeFromSuperview()
                }
            }
            
            let separatorView = UIView()
            separatorView.tag = 999
            separatorView.backgroundColor = .systemGray4
            separatorView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(separatorView)
            
            NSLayoutConstraint.activate([
                separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                separatorView.heightAnchor.constraint(equalToConstant: 1)
            ])
        }
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        switchControl.isOn = false
        onSwitchChanged = nil
    }
    
    func configure(with title: String, isSelected: Bool, onSwitchChanged: @escaping (Bool) -> Void) {
        titleLabel.text = title
        switchControl.isOn = isSelected
        self.onSwitchChanged = onSwitchChanged
    }
    
    @objc private func switchChanged() {
        onSwitchChanged?(switchControl.isOn)
    }
}
