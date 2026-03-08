//
//  PageSelectionViewController.swift
//  PhotoToPDFMaker
//

import UIKit

protocol PageSelectionDelegate: AnyObject {
    func pageSelectionDidSelect(images: [UIImage])  // Changed to array
    func pageSelectionDidCancel()
}

class PageSelectionViewController: UIViewController {
    
    weak var delegate: PageSelectionDelegate?
    private var images: [UIImage]  // Changed to var for reordering
    private var selectedIndices: Set<Int> = []  // Track multiple selections
    
    private let titleLabel = UILabel()
    private let collectionView: UICollectionView
    private let confirmButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let selectionCountLabel = UILabel()
    
    init(images: [UIImage]) {
        self.images = images
        
        // Select all images by default
        self.selectedIndices = Set(0..<images.count)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Title
        titleLabel.text = "Select Pages"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Selection count label
        selectionCountLabel.font = .systemFont(ofSize: 15, weight: .medium)
        selectionCountLabel.textColor = .secondaryLabel
        selectionCountLabel.textAlignment = .center
        selectionCountLabel.text = "\(selectedIndices.count) of \(images.count) selected"
        selectionCountLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(selectionCountLabel)
        
        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        
        // Collection view
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PageCell.self, forCellWithReuseIdentifier: "PageCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        // Confirm button
        confirmButton.setTitle("Continue", for: .normal)
        confirmButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.layer.cornerRadius = 12
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(confirmButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            selectionCountLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            selectionCountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cancelButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            collectionView.topAnchor.constraint(equalTo: selectionCountLabel.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -20),
            
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            confirmButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func confirmTapped() {
        confirmSelection()
    }
    
    private func confirmSelection() {
        // Get selected images in order
        let selectedImages = selectedIndices.sorted().map { images[$0] }
        
        dismiss(animated: true) {
            self.delegate?.pageSelectionDidSelect(images: selectedImages)
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true) {
            self.delegate?.pageSelectionDidCancel()
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension PageSelectionViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PageCell", for: indexPath) as! PageCell
        let isSelected = selectedIndices.contains(indexPath.item)
        cell.configure(with: images[indexPath.item], isSelected: isSelected)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Toggle selection
        if selectedIndices.contains(indexPath.item) {
            selectedIndices.remove(indexPath.item)
        } else {
            selectedIndices.insert(indexPath.item)
        }
        
        // Update selection count label
        selectionCountLabel.text = "\(selectedIndices.count) of \(images.count) selected"
        
        // Reload the cell
        collectionView.reloadItems(at: [indexPath])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Smaller cards for better overview - about 60% of screen height
        let height = (collectionView.bounds.height - 40) * 0.6
        let width = height * 0.7 // Portrait aspect ratio
        return CGSize(width: width, height: height)
    }
}

// MARK: - PageCell

class PageCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let checkmarkView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 3
        contentView.layer.borderColor = UIColor.clear.cgColor
        
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        checkmarkView.image = UIImage(systemName: "checkmark.circle.fill")
        checkmarkView.tintColor = .systemBlue
        checkmarkView.isHidden = true
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkmarkView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            checkmarkView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkView.widthAnchor.constraint(equalToConstant: 32),
            checkmarkView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    func configure(with image: UIImage, isSelected: Bool) {
        imageView.image = image
        checkmarkView.isHidden = !isSelected
        contentView.layer.borderColor = isSelected ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
    }
}
