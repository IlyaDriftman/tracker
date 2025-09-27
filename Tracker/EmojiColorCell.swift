import UIKit

final class EmojiColorCell: UICollectionViewCell {
    private let emojiLabel = UILabel()
    private let colorView = UIView()
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
        
        // Selection view
        selectionView.backgroundColor = .clear
        selectionView.layer.cornerRadius = 8
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Emoji label
        emojiLabel.font = .systemFont(ofSize: 30)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Color view
        colorView.layer.cornerRadius = 8
        colorView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(selectionView)
        contentView.addSubview(emojiLabel)
        contentView.addSubview(colorView)
        
        NSLayoutConstraint.activate([
            selectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8),
            colorView.heightAnchor.constraint(equalTo: colorView.widthAnchor)
        ])
    }
    
    func configureEmoji(with emoji: String, isSelected: Bool) {
        emojiLabel.text = emoji
        emojiLabel.isHidden = false
        colorView.isHidden = true
        
        if isSelected {
            selectionView.backgroundColor = .systemGray6
            selectionView.layer.borderWidth = 0
            selectionView.layer.borderColor = UIColor.clear.cgColor
        } else {
            selectionView.backgroundColor = .clear
            selectionView.layer.borderWidth = 0
            selectionView.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    func configureColor(with color: UIColor, isSelected: Bool) {
        colorView.backgroundColor = color
        colorView.isHidden = false
        emojiLabel.isHidden = true
        
        if isSelected {
            selectionView.backgroundColor = .systemGray6
            selectionView.layer.borderWidth = 0
            selectionView.layer.borderColor = UIColor.clear.cgColor
        } else {
            selectionView.backgroundColor = .clear
            selectionView.layer.borderWidth = 0
            selectionView.layer.borderColor = UIColor.clear.cgColor
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
