//
//  OCRTextViewController.swift
//  PhotoToPDFMaker
//

import UIKit

class OCRTextViewController: UIViewController {
    
    private let textView = UITextView()
    private let text: String
    
    init(text: String) {
        self.text = text
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Extracted Text"
        view.backgroundColor = .systemBackground
        
        textView.text = text
        textView.font = .systemFont(ofSize: 16)
        textView.isEditable = true // Allow editing before export or save
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        let copyButton = UIBarButtonItem(title: "Copy", style: .plain, target: self, action: #selector(copyTapped))
        let saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveTapped))
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
        navigationItem.rightBarButtonItems = [shareButton, saveButton, copyButton]
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func copyTapped() {
        let currentText = textView.text ?? text
        UIPasteboard.general.string = currentText
        
        // Show brief confirmation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let alert = UIAlertController(title: "✓ Copied", message: "Text copied to clipboard.", preferredStyle: .alert)
        present(alert, animated: true)
        
        // Auto-dismiss after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
    
    @objc private func saveTapped() {
        let alert = UIAlertController(title: "Save Text", message: "Choose file format", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Save as .txt", style: .default) { [weak self] _ in
            self?.saveAsTextFile(format: .txt)
        })
        
        alert.addAction(UIAlertAction(title: "Save as .docx", style: .default) { [weak self] _ in
            self?.saveAsTextFile(format: .docx)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?.first(where: { $0.title == "Save" })
        }
        
        present(alert, animated: true)
    }
    
    private func saveAsTextFile(format: TextFormat) {
        let currentText = textView.text ?? text
        
        // Create text data based on format
        let textData: Data?
        if format == .txt {
            textData = currentText.data(using: .utf8)
        } else {
            textData = createRTFData(from: currentText)
        }
        
        guard let data = textData else {
            showError("Failed to create \(format.rawValue.uppercased()) file")
            return
        }
        
        // Save to DocumentStore
        if let savedItem = DocumentStore.shared.saveTextDocument(textData: data, format: format, relatedPDFName: nil) {
            // Show success message
            let alert = UIAlertController(
                title: "✓ Saved",
                message: "Text saved as \(savedItem.displayName)",
                preferredStyle: .alert
            )
            present(alert, animated: true)
            
            // Auto-dismiss and go back
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                alert.dismiss(animated: true) {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        } else {
            showError("Failed to save text file")
        }
    }
    
    private func createRTFData(from text: String) -> Data? {
        // Create a simple RTF file that can be opened as .docx
        let rtfString = """
        {\\rtf1\\ansi\\deff0
        {\\fonttbl{\\f0 Times New Roman;}}
        \\f0\\fs24 \(text.replacingOccurrences(of: "\n", with: "\\par "))
        }
        """
        return rtfString.data(using: .utf8)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func shareTapped() {
        ShareCoordinator.shareText(textView.text ?? text, from: self, sourceView: view)
    }
}
