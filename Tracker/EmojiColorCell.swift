import UIKit

final class EmojiColorCell: UICollectionViewCell {
    private let emojiLabel = UILabel()
    private let colorView = UIView()
    private let whiteBorderView = UIView()
    private let selectionView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Cell background
        backgroundColor = .clear
        
        // Selection view (фон всей ячейки 52x52 с цветом и прозрачностью)
        selectionView.backgroundColor = .clear
        selectionView.layer.cornerRadius = 8
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // White border view (белая рамка 46x46)
        whiteBorderView.backgroundColor = .white
        whiteBorderView.layer.cornerRadius = 8
        whiteBorderView.isHidden = true
        whiteBorderView.translatesAutoresizingMaskIntoConstraints = false
        
        // Emoji label
        emojiLabel.font = .systemFont(ofSize: 30)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Color view (центральный квадрат 40x40)
        colorView.layer.cornerRadius = 8
        colorView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(selectionView)
        contentView.addSubview(whiteBorderView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(colorView)
        
        NSLayoutConstraint.activate([
            // Selection view - вся ячейка 52x52
            selectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // White border - 46x46 (отступ 3px от края)
            whiteBorderView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            whiteBorderView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            whiteBorderView.widthAnchor.constraint(equalToConstant: 46),
            whiteBorderView.heightAnchor.constraint(equalToConstant: 46),
            
            // Emoji - по центру
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // Color view - 40x40 (отступ 3px от белой рамки)
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 40),
            colorView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configureEmoji(with emoji: String, isSelected: Bool) {
        emojiLabel.text = emoji
        emojiLabel.isHidden = false
        colorView.isHidden = true
        whiteBorderView.isHidden = true
        
        if isSelected {
            selectionView.backgroundColor = .systemGray6
        } else {
            selectionView.backgroundColor = .clear
        }
    }
    
    func configureColor(with color: UIColor, isSelected: Bool) {
        colorView.backgroundColor = color
        colorView.isHidden = false
        emojiLabel.isHidden = true
        
        if isSelected {
            // Слой 1: Фон ячейки (52x52) - цвет с прозрачностью 30%
            selectionView.backgroundColor = color.withAlphaComponent(0.3)
            // Слой 2: Белая рамка (46x46)
            whiteBorderView.isHidden = false
            // Слой 3: Центральный цвет (40x40)
            // colorView уже настроен
        } else {
            selectionView.backgroundColor = .clear
            whiteBorderView.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        emojiLabel.text = nil
        emojiLabel.isHidden = true
        colorView.backgroundColor = .clear
        colorView.isHidden = true
        selectionView.backgroundColor = .clear
        selectionView.layer.borderWidth = 0
        selectionView.layer.borderColor = UIColor.clear.cgColor
        backgroundColor = .clear
    }
}
