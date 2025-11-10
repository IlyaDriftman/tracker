import UIKit

final class StatisticCard: UIView {
    // MARK: - Constants
    static let defaultGradientColors: [UIColor] = [
        UIColor(hex: "#FD4C49") ?? .red,
        UIColor(hex: "#46E69D") ?? .green,
        UIColor(hex: "#007BFA") ?? .blue
    ]
    
    // MARK: - UI Elements
    private let containerView = UIView() // Внутренний view с белым фоном
    private let numberLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let gradientLayer = CAGradientLayer()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Внешний view с градиентным фоном (будет виден как бордер)
        layer.cornerRadius = 16
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        layer.addSublayer(gradientLayer)
        
        // Внутренний view с белым фоном (создает эффект бордера через отступ)
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 14 // Чуть меньше, чтобы градиент был виден
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        // Настраиваем число
        numberLabel.font = .systemFont(ofSize: 34, weight: .bold)
        numberLabel.textColor = .label
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(numberLabel)
        
        // Настраиваем описание
        descriptionLabel.font = .systemFont(ofSize: 12)
        descriptionLabel.textColor = .label
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Внутренний view с отступом 1px со всех сторон (создает бордер)
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
            
            // Число
            numberLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            numberLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            numberLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -12),
            
            // Описание под числом
            descriptionLabel.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 7),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -12),
            descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Обновляем размер градиентного слоя при изменении layout
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = 16
    }
    
    // MARK: - Configuration
    func configure(number: String, description: String, gradientColors: [UIColor] = StatisticCard.defaultGradientColors) {
        numberLabel.text = number
        descriptionLabel.text = description
        
        // Настраиваем градиент
        gradientLayer.colors = gradientColors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = 16
    }
}

