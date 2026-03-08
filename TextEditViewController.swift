//
//  TextEditViewController.swift
//  PhotoToPDFMaker
//

import UIKit

protocol TextEditDelegate: AnyObject {
    func textEditDidFinish(with editedText: String)
    func textEditDidCancel()
}

class TextEditViewController: UIViewController {
    
    weak var delegate: TextEditDelegate?
    private let originalText: String
    private let sourceImage: UIImage
    
    private let textView = UITextView()
    private let toolbar = UIToolbar()
    
    init(text: String, sourceImage: UIImage) {
        self.originalText = text
        self.sourceImage = sourceImage
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        textView.text = originalText
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation bar
        navigationItem.title = "Edit Text"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        
        // Text view
        textView.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -16)
        ])
    }
    
    @objc private func cancelTapped() {
        textView.resignFirstResponder()
        dismiss(animated: true) {
            self.delegate?.textEditDidCancel()
        }
    }
    
    @objc private func doneTapped() {
        textView.resignFirstResponder()
        let editedText = textView.text ?? ""
        dismiss(animated: true) {
            self.delegate?.textEditDidFinish(with: editedText)
        }
    }
}
