//
//  OnboardingPageView.swift
//  PhotoToPDFMaker
//

import UIKit

struct OnboardingPage {
    let title: String
    let body: String
    let imageName: String // using system names for simplicity
}

class OnboardingPageView: UIView {
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    
    init(page: OnboardingPage) {
        super.init(frame: .zero)
        setupUI(page: page)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(page: OnboardingPage) {
        imageView.image = UIImage(systemName: page.imageName)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 100, weight: .regular))
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        titleLabel.text = page.title
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        bodyLabel.text = page.body
        bodyLabel.font = .systemFont(ofSize: 18, weight: .regular)
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bodyLabel)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -100),
            imageView.widthAnchor.constraint(equalToConstant: 150),
            imageView.heightAnchor.constraint(equalToConstant: 150),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32)
        ])
    }
}
