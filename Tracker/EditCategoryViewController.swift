//
//  EditCategoryViewController.swift
//  Tracker
//
//  Created by Илья on 19.10.2025.
//

import UIKit

protocol EditCategoryViewControllerDelegate: AnyObject {
    func didUpdateCategory(_ categoryTitle: String)
}

final class EditCategoryViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: EditCategoryViewControllerDelegate?
    private let currentTitle: String
    
    // MARK: - UI Elements
    
    private let textField: UITextField = {
        let textField = PaddedTextField()
        textField.placeholder = "Введите название категории"
        textField.borderStyle = .none // Убираем бордеры
        textField.font = .systemFont(ofSize: 17)
        textField.backgroundColor = UIColor(hex: "#E6E8EB4D")
        textField.layer.cornerRadius = 16
        textField.layer.masksToBounds = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = UIColor(named: "trackerBlack")
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    init(currentTitle: String) {
        self.currentTitle = currentTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupKeyboardHandling()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
        textField.selectAll(nil) // Выделяем весь текст для удобства редактирования
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Настройка навигации
        navigationItem.title = "Редактировать категорию"
        
        view.addSubview(textField)
        view.addSubview(doneButton)
        
        // Устанавливаем текущее название в текстовое поле
        textField.text = currentTitle
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Text Field - отступ от safeArea 24px, высота 75px, отступы по 16px (слева, справа)
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 75),
            
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupKeyboardHandling() {
        textField.addTarget(self, action: #selector(textFieldDidEndOnExit), for: .editingDidEndOnExit)
    }
    
    // MARK: - Actions
    @objc private func doneButtonTapped() {
        guard let newTitle = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !newTitle.isEmpty else {
            showAlert(title: "Ошибка", message: "Введите название категории")
            return
        }
        
        // Проверяем, что название изменилось
        guard newTitle != currentTitle else {
            dismiss(animated: true)
            return
        }
        
        delegate?.didUpdateCategory(newTitle)
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func textFieldDidEndOnExit() {
        doneButtonTapped()
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

