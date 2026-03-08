//
//  SignaturePreviewViewController.swift
//  PhotoToPDFMaker
//

import UIKit

class SignaturePreviewViewController: UIViewController {
    
    private let signatureImageView = UIImageView()
    private let editButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSignature()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Your Signature"
        
        // Signature preview container
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        signatureImageView.contentMode = .scaleAspectFit
        signatureImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(signatureImageView)
        
        // Info label
        let infoLabel = UILabel()
        infoLabel.text = "This signature will be used when signing documents"
        infoLabel.font = .systemFont(ofSize: 15, weight: .regular)
        infoLabel.textColor = .secondaryLabel
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoLabel)
        
        // Buttons
        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        editButton.setTitle("Edit Signature", for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        editButton.backgroundColor = .systemBlue
        editButton.setTitleColor(.white, for: .normal)
        editButton.layer.cornerRadius = 12
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
        
        deleteButton.setTitle("Delete Signature", for: .normal)
        deleteButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        deleteButton.backgroundColor = .secondarySystemBackground
        deleteButton.setTitleColor(.systemRed, for: .normal)
        deleteButton.layer.cornerRadius = 12
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        
        buttonStack.addArrangedSubview(editButton)
        buttonStack.addArrangedSubview(deleteButton)
        view.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.heightAnchor.constraint(equalToConstant: 200),
            
            signatureImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            signatureImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            signatureImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            signatureImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            infoLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 20),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            buttonStack.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 40),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            buttonStack.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    private func loadSignature() {
        if let signature = SignatureStore.shared.loadSignature() {
            signatureImageView.image = signature
        }
    }
    
    @objc private func editTapped() {
        let signatureVC = SignatureViewController()
        signatureVC.isCreatingSignature = true
        let nav = UINavigationController(rootViewController: signatureVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
    
    @objc private func deleteTapped() {
        let alert = UIAlertController(
            title: "Delete Signature?",
            message: "Are you sure you want to delete your saved signature?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            SignatureStore.shared.deleteSignature()
            self?.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
}
