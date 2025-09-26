import UIKit

protocol CategoryViewControllerDelegate: AnyObject {
    func didSelectCategory(_ category: TrackerCategory)
}

class CategoryViewController: UIViewController {
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
            UITableViewCell.self,
            forCellReuseIdentifier: "CategoryCell"
        )
        tableView.translatesAutoresizingMaskIntoConstraints = false

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
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(
                equalTo: doneButton.topAnchor,
                constant: -20
            ),

            // Done Button
            doneButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -20
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
        if let selectedCategory = selectedCategory {
            delegate?.didSelectCategory(selectedCategory)
        }
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
        )
        let category = categories[indexPath.row]

        cell.textLabel?.text = category.title
        cell.accessoryType =
            (selectedCategory?.title == category.title) ? .checkmark : .none

        return cell
    }
}

// MARK: - UITableViewDelegate
extension CategoryViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        selectedCategory = categories[indexPath.row]
        tableView.reloadData()
    }
}
