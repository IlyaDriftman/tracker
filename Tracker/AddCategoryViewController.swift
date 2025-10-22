//
//  AddCategoryViewController.swift
//  Tracker
//
//  Created by Илья on 19.10.2025.
//

import UIKit

protocol AddCategoryViewControllerDelegate: AnyObject {
    func didAddCategory(_ categoryTitle: String)
}

final class AddCategoryViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: AddCategoryViewControllerDelegate?
    
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
        button.backgroundColor = UIColor(hex: "#AEAFB4") // Серый цвет по умолчанию
        button.layer.cornerRadius = 16
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addTarget(AddCategoryViewController.self, action: #selector(doneButtonTapped), for: .touchUpInside)
        button.isEnabled = false // Неактивна по умолчанию
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupKeyboardHandling()
        setupTextFieldObserver()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Настройка навигации
        navigationItem.title = "Новая категория"
        
        view.addSubview(textField)
        view.addSubview(doneButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
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
    
    private func setupTextFieldObserver() {
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    // MARK: - Actions
    @objc private func textFieldDidChange() {
        let hasText = !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        updateDoneButtonState(isEnabled: hasText)
    }
    
    private func updateDoneButtonState(isEnabled: Bool) {
        doneButton.isEnabled = isEnabled
        if isEnabled {
            doneButton.backgroundColor = UIColor(named: "trackerBlack")
        } else {
            doneButton.backgroundColor = UIColor(hex: "#AEAFB4")
        }
    }
    
    @objc private func doneButtonTapped() {
        guard let categoryTitle = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !categoryTitle.isEmpty else {
            showAlert(title: "Ошибка", message: "Введите название категории")
            return
        }
        
        delegate?.didAddCategory(categoryTitle)
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

// MARK: - PaddedTextField
class PaddedTextField: UITextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 41))
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 41))
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 41))
    }
}
