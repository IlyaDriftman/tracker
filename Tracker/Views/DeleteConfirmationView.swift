import UIKit

/// Переиспользуемый компонент для диалога подтверждения удаления
final class DeleteConfirmationView {
    
    private weak var parentViewController: UIViewController?
    private var containerView: UIView?
    private var onConfirm: (() -> Void)?
    
    /// Показывает диалог подтверждения удаления снизу экрана
    /// - Parameters:
    ///   - viewController: ViewController, который будет показывать диалог
    ///   - message: Текст сообщения
    ///   - onConfirm: Замыкание, вызываемое при подтверждении
    func show(
        in viewController: UIViewController,
        message: String,
        onConfirm: @escaping () -> Void
    ) {
        self.parentViewController = viewController
        self.onConfirm = onConfirm
        
        // Создаем контейнер для диалога
        let containerView = UIView()
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Добавляем обработчик нажатия на фон для закрытия диалога
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        containerView.addGestureRecognizer(tapGesture)
        
        // Создаем action sheet
        let actionSheetView = UIView()
        actionSheetView.backgroundColor = .clear
        actionSheetView.translatesAutoresizingMaskIntoConstraints = false
        // Блокируем распространение событий на контейнер при нажатии на actionSheetView
        let actionSheetTapGesture = UITapGestureRecognizer(target: self, action: nil)
        actionSheetView.addGestureRecognizer(actionSheetTapGesture)
        
        // Блок с текстом и кнопкой удалить
        let contentView = UIView()
        contentView.backgroundColor = UIColor(hex: "#F5F5F5B2")
        contentView.layer.cornerRadius = 13
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Сообщение
        let messageLabel = UILabel()
        messageLabel.text = message
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
        deleteButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        
        // Кнопка "Отменить" (белая с синим текстом)
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Отменить", for: .normal)
        cancelButton.setTitleColor(.systemBlue, for: .normal)
        cancelButton.backgroundColor = .white
        cancelButton.layer.cornerRadius = 16
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        // Добавляем элементы
        // Добавляем контейнер в tabBarController.view, чтобы он был поверх табов
        // Если tabBarController недоступен, используем window или view
        let parentView: UIView
        if let tabBarController = viewController.tabBarController {
            parentView = tabBarController.view
        } else if let window = viewController.view.window {
            parentView = window
        } else {
            parentView = viewController.view
        }
        parentView.addSubview(containerView)
        // Убеждаемся, что контейнер находится поверх всех элементов
        parentView.bringSubviewToFront(containerView)
        containerView.addSubview(actionSheetView)
        actionSheetView.addSubview(contentView)
        contentView.addSubview(messageLabel)
        contentView.addSubview(separatorView)
        contentView.addSubview(deleteButton)
        actionSheetView.addSubview(cancelButton) // Кнопка отмены поверх contentView
        
        // Констрейнты
        NSLayoutConstraint.activate([
            // Контейнер на весь экран (относительно parentView)
            containerView.topAnchor.constraint(equalTo: parentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            
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
        
        // Сохраняем ссылку для удаления
        self.containerView = containerView
    }
    
    /// Скрывает диалог
    func dismiss() {
        guard let container = containerView else { return }
        UIView.animate(withDuration: 0.3, animations: {
            container.alpha = 0
        }) { _ in
            container.removeFromSuperview()
        }
        containerView = nil
        onConfirm = nil
    }
    
    @objc private func confirmTapped() {
        onConfirm?()
        dismiss()
    }
    
    @objc private func cancelTapped() {
        dismiss()
    }
}



