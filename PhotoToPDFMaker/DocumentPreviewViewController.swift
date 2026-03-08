//
//  DocumentPreviewViewController.swift
//  PhotoToPDFMaker
//

import UIKit
import PDFKit

class DocumentPreviewViewController: UIViewController, SignatureEditableDelegate, SignatureDelegate {

    private let documentItem: DocumentItem
    private let pdfView = PDFView()
    private var pdfDocument: PDFDocument?
    
    private let actionStack = UIStackView()
    private let signButton = UIButton(type: .system)
    private let ocrButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    
    // Activity Indicator for OCR
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // Track signature annotations for undo functionality
    private struct SignatureState {
        let annotation: PDFAnnotation
        let pageIndex: Int
        let originalPage: PDFPage
    }
    private var signatureStates: [SignatureState] = []
    private var isApplyingSignature = false // Prevent duplicate applications
    
    init(documentItem: DocumentItem) {
        self.documentItem = documentItem
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = documentItem.displayName
        setupNavigationBar()
        setupUI()
        loadPDF()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide tab bar when viewing document
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show tab bar when leaving
        tabBarController?.tabBar.isHidden = false
    }
    
    private func setupNavigationBar() {
        // Settings button in top-right (will be replaced by undo after signature)
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // PDF View
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        view.addSubview(pdfView)
        
        // Activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        // Action buttons stack
        actionStack.axis = .horizontal
        actionStack.spacing = 16
        actionStack.distribution = .fillEqually
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        
        configureButton(ocrButton, title: "OCR", icon: "doc.text.viewfinder", action: #selector(ocrTapped))
        configureButton(signButton, title: "Sign", icon: "signature", action: #selector(signTapped))
        configureButton(shareButton, title: "Share", icon: "square.and.arrow.up", action: #selector(shareTapped))
        configureButton(saveButton, title: "Save", icon: "checkmark.circle.fill", action: #selector(saveTapped), isPrimary: true)
        
        actionStack.addArrangedSubview(ocrButton)
        actionStack.addArrangedSubview(signButton)
        actionStack.addArrangedSubview(shareButton)
        actionStack.addArrangedSubview(saveButton)
        view.addSubview(actionStack)
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: actionStack.topAnchor, constant: -16),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            actionStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            actionStack.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func configureButton(_ button: UIButton, title: String, icon: String, action: Selector, isPrimary: Bool = false, isDestructive: Bool = false) {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: icon)
        config.title = title
        config.imagePlacement = .top
        config.imagePadding = 4
        
        if isDestructive {
            config.baseForegroundColor = .systemRed
        } else if isPrimary {
            config.baseForegroundColor = .white
            config.background.backgroundColor = .systemBlue
        } else {
            config.baseForegroundColor = .systemBlue
        }
        
        config.background.backgroundColor = isPrimary ? .systemBlue : .secondarySystemBackground
        config.background.cornerRadius = 12
        
        button.configuration = config
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: isPrimary ? .semibold : .medium)
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    private func loadPDF() {
        let url = DocumentStore.shared.url(for: documentItem.id)
        if let document = PDFDocument(url: url) {
            self.pdfDocument = document
            pdfView.document = document
        } else {
            print("Failed to load PDF at \(url)")
        }
    }
    
    @objc private func signTapped() {
        print("🖊️ Sign button tapped")
        
        if SignatureStore.shared.hasSignature, let signature = SignatureStore.shared.loadSignature() {
            print("✅ Found existing signature: \(signature.size)")
            startSignaturePlacement()
        } else {
            print("⚠️ No signature found, showing signature creation screen")
            let signatureVC = SignatureViewController()
            signatureVC.delegate = self
            signatureVC.modalPresentationStyle = .formSheet
            present(signatureVC, animated: true)
        }
    }
    
    @objc private func ocrTapped() {
        guard let document = pdfDocument else { return }
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        OCRService.extractTextFromPDF(document, progress: { _ in }) { [weak self] extractedText in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
            
            if extractedText.isEmpty {
                let alert = UIAlertController(title: "No Text Found", message: "Could not extract any text from this document.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            } else {
                let textVC = OCRTextViewController(text: extractedText)
                self.navigationController?.pushViewController(textVC, animated: true)
            }
        }
    }
    
    @objc private func shareTapped() {
        let url = DocumentStore.shared.url(for: documentItem.id)
        ShareCoordinator.shareURL(url, from: self, sourceView: shareButton)
    }
    
    @objc private func saveTapped() {
        saveDocument(showFeedback: true)
    }
    
    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
    
    // MARK: - SignatureDelegate
    
    func signatureDidFinish(with signature: UIImage) {
        // Save the signature
        SignatureStore.shared.saveSignature(signature)
        // Start placement
        startSignaturePlacement()
    }
    
    func signatureDidCancel() {
        // Do nothing
    }
    
    // MARK: - Signature Placement
    
    private func startSignaturePlacement() {
        guard let signature = SignatureStore.shared.loadSignature() else {
            print("❌ Could not load signature for placement")
            return
        }
        
        print("✅ Starting signature placement")
        print("   View bounds: \(view.bounds)")
        print("   Signature size: \(signature.size)")
        
        // Calculate initial signature rect
        let pdfViewRect = pdfView.frame
        let signatureSize = CGSize(width: pdfViewRect.width * 0.4, height: pdfViewRect.height * 0.2)
        let initialRect = CGRect(
            x: pdfViewRect.midX - signatureSize.width / 2,
            y: pdfViewRect.midY - signatureSize.height / 2,
            width: signatureSize.width,
            height: signatureSize.height
        )
        
        // Use SignatureEditableOverlayView which has corner handles
        let overlay = SignatureEditableOverlayView(signatureImage: signature, initialRect: initialRect)
        overlay.delegate = self
        overlay.frame = view.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
        
        print("✅ Overlay added to view hierarchy with corner handles")
    }
    
    // MARK: - SignatureEditableDelegate
    
    func didConfirmSignaturePlacement(rect: CGRect, in overlayView: UIView) {
        // Prevent duplicate signature applications
        guard !isApplyingSignature else {
            print("⚠️ Already applying signature, ignoring duplicate call")
            return
        }
        
        isApplyingSignature = true
        
        guard let document = pdfDocument, let signature = SignatureStore.shared.loadSignature(), let currentPage = pdfView.currentPage else {
            isApplyingSignature = false
            return
        }
        
        let pageIndex = document.index(for: currentPage)
        
        // Store the original page for undo
        guard let originalPageCopy = currentPage.copy() as? PDFPage else {
            isApplyingSignature = false
            print("❌ Failed to copy PDF page for undo")
            return
        }
        
        // SIMPLIFIED COORDINATE CONVERSION (same as PDFActionViewController)
        // Convert overlay rect to pdfView coordinates
        let rectInPDFView = view.convert(rect, to: pdfView)
        
        // Get the page's display rect in PDFView coordinates
        let pageRectInPDFView = pdfView.convert(currentPage.bounds(for: .mediaBox), from: currentPage)
        
        // Calculate the signature position relative to the page display area
        let relativeX = (rectInPDFView.origin.x - pageRectInPDFView.origin.x) / pageRectInPDFView.width
        let relativeY = (rectInPDFView.origin.y - pageRectInPDFView.origin.y) / pageRectInPDFView.height
        let relativeWidth = rectInPDFView.width / pageRectInPDFView.width
        let relativeHeight = rectInPDFView.height / pageRectInPDFView.height
        
        // Apply to actual page bounds
        let pageBounds = currentPage.bounds(for: .mediaBox)
        let pageRect = CGRect(
            x: relativeX * pageBounds.width,
            y: relativeY * pageBounds.height,
            width: relativeWidth * pageBounds.width,
            height: relativeHeight * pageBounds.height
        )
        
        print("📍 Overlay rect: \(rect)")
        print("📍 PDFView rect: \(rectInPDFView)")
        print("📍 Page display rect: \(pageRectInPDFView)")
        print("📍 Relative position: (\(relativeX), \(relativeY))")
        print("📍 PDF page rect: \(pageRect)")
        
        // Add signature (flattened into the page)
        if let annotation = PDFSigner.signDocument(document, with: signature, in: pageRect, on: pageIndex) {
            // Track this for undo with original page
            let state = SignatureState(annotation: annotation, pageIndex: pageIndex, originalPage: originalPageCopy)
            signatureStates.append(state)
            
            // Show undo button
            showUndoButton()
            
            if saveDocument(showFeedback: false) {
                // Force PDFView to refresh
                pdfView.document = nil
                pdfView.document = document
                
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                print("✅ Signature applied and saved")
            }
        } else {
            print("Failed to add signature to document")
        }
        
        // Reset the flag after a delay to allow for next signature
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isApplyingSignature = false
        }
    }
    
    func didCancelSignaturePlacement() {
        print("❌ Signature placement cancelled")
    }
    
    // MARK: - Undo Signature
    
    private func showUndoButton() {
        let undoButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.backward"),
            style: .plain,
            target: self,
            action: #selector(undoSignature)
        )
        navigationItem.rightBarButtonItem = undoButton
    }
    
    private func showSettingsButton() {
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        navigationItem.rightBarButtonItem = settingsButton
    }
    
    @objc private func undoSignature() {
        guard !signatureStates.isEmpty,
              let document = pdfDocument else { return }
        
        // Remove the last signature by restoring the original page
        let lastState = signatureStates.removeLast()
        
        document.removePage(at: lastState.pageIndex)
        document.insert(lastState.originalPage, at: lastState.pageIndex)
        
        // Restore settings button if no more signatures
        if signatureStates.isEmpty {
            showSettingsButton()
        }
        
        if saveDocument(showFeedback: false) {
            // Force PDFView to refresh
            pdfView.document = nil
            pdfView.document = document
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            
            print("↩️ Signature undone")
            
            // Show toast
            let alert = UIAlertController(title: nil, message: "Signature removed", preferredStyle: .alert)
            present(alert, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                alert.dismiss(animated: true)
            }
        }
    }
    
    @discardableResult
    private func saveDocument(showFeedback: Bool) -> Bool {
        guard let document = pdfDocument,
              let pdfData = document.dataRepresentation() else {
            return false
        }
        
        let url = DocumentStore.shared.url(for: documentItem.id)
        do {
            try pdfData.write(to: url, options: .atomic)
            if showFeedback {
                let alert = UIAlertController(title: nil, message: "Document saved", preferredStyle: .alert)
                present(alert, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    alert.dismiss(animated: true)
                }
            }
            return true
        } catch {
            if showFeedback {
                let alert = UIAlertController(
                    title: "Save Failed",
                    message: "Could not save document changes.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
            print("Failed to save document: \(error)")
            return false
        }
    }
}
