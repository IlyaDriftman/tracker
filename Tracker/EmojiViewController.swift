import UIKit

protocol EmojiViewControllerDelegate: AnyObject {
    func didSelectEmoji(_ emoji: String)
}

class EmojiViewController: UIViewController {
    
    weak var delegate: EmojiViewControllerDelegate?
    var selectedEmoji: String?
    
    private let collectionView: UICollectionView
    private let doneButton = UIButton(type: .system)
    
    private let emojis = ["🌱", "💧", "🏃‍♂️", "📚", "🍎", "💪", "🎯", "🌟", "🔥", "💡", "🎨", "🎵"]
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        title = "Эмодзи"
        view.backgroundColor = .systemBackground
        
        // Collection View
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "EmojiCell")
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Done button
        doneButton.setTitle("Готово", for: .normal)
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.backgroundColor = UIColor(red: 0.102, green: 0.106, blue: 0.133, alpha: 1.0) // #1A1B22
        doneButton.layer.cornerRadius = 16
        doneButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(collectionView)
        view.addSubview(doneButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: doneButton.topAnchor, constant: -20),
            
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    @objc private func doneTapped() {
        if let selectedEmoji = selectedEmoji {
            delegate?.didSelectEmoji(selectedEmoji)
        }
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension EmojiViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiCell
        let emoji = emojis[indexPath.item]
        let isSelected = emoji == selectedEmoji
        cell.configure(with: emoji, isSelected: isSelected)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension EmojiViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedEmoji = emojis[indexPath.item]
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension EmojiViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 50, height: 50)
    }
}

// MARK: - EmojiCell
class EmojiCell: UICollectionViewCell {
    private let emojiLabel = UILabel()
    private let selectionView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Selection view
        selectionView.backgroundColor = .systemGray6
        selectionView.layer.cornerRadius = 8
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Emoji label
        emojiLabel.font = .systemFont(ofSize: 30)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(selectionView)
        contentView.addSubview(emojiLabel)
        
        NSLayoutConstraint.activate([
            selectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with emoji: String, isSelected: Bool) {
        emojiLabel.text = emoji
        selectionView.backgroundColor = isSelected ? .systemBlue : .systemGray6
        selectionView.layer.borderWidth = isSelected ? 2 : 0
        selectionView.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
    }
}