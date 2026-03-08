//
//  PDFActionViewController.swift
//  PhotoToPDFMaker
//

import UIKit
import PDFKit

class PDFActionViewController: UIViewController, SignatureDelegate, SignatureEditableDelegate {
    
    private let pdfURL: URL
    private var pdfDocument: PDFDocument?
    private var signatureImage: UIImage?
    
    private let pdfView = PDFView()
    private let actionStack = UIStackView()
    private let extractTextButton = UIButton(type: .system)
    private let signButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // Track signature annotations for undo functionality
    private struct SignatureState {
        let annotation: PDFAnnotation
        let pageIndex: Int
        let originalPage: PDFPage
    }
    private var signatureStates: [SignatureState] = []
    private var undoButton: UIBarButtonItem?
    private var isApplyingSignature = false // Prevent duplicate applications
    
    init(pdfURL: URL) {
        self.pdfURL = pdfURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPDF()
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        // Add undo button to navigation bar (initially disabled)
        undoButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.uturn.backward"),
            style: .plain,
            target: self,
            action: #selector(undoSignature)
        )
        undoButton?.isEnabled = false
        navigationItem.rightBarButtonItem = undoButton
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation
        navigationItem.title = "Imported PDF"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        
        // PDF view (top half)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .secondarySystemBackground
        pdfView.layer.cornerRadius = 12
        pdfView.clipsToBounds = true
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)
        
        // Activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        // Action buttons stack
        actionStack.axis = .vertical
        actionStack.spacing = 12
        actionStack.distribution = .fillEqually
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        
        configureButton(extractTextButton, title: "Extract Text (OCR)", icon: "doc.text.viewfinder", action: #selector(extractTextTapped))
        configureButton(signButton, title: "Add Signature", icon: "signature", action: #selector(signTapped))
        configureButton(shareButton, title: "Share PDF", icon: "square.and.arrow.up", action: #selector(shareTapped), isPrimary: true)
        
        actionStack.addArrangedSubview(extractTextButton)
        actionStack.addArrangedSubview(signButton)
        actionStack.addArrangedSubview(shareButton)
        view.addSubview(actionStack)
        
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            pdfView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            activityIndicator.centerXAnchor.constraint(equalTo: pdfView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: pdfView.centerYAnchor),
            
            actionStack.topAnchor.constraint(equalTo: pdfView.bottomAnchor, constant: 24),
            actionStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            actionStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            actionStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func configureButton(_ button: UIButton, title: String, icon: String, action: Selector, isPrimary: Bool = false) {
        button.setTitle(" \(title)", for: .normal)
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: isPrimary ? .bold : .medium)
        button.backgroundColor = isPrimary ? .systemBlue : .secondarySystemBackground
        button.setTitleColor(isPrimary ? .white : .label, for: .normal)
        button.tintColor = isPrimary ? .white : .systemBlue
        button.layer.cornerRadius = 12
        button.contentHorizontalAlignment = .center
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    private func loadPDF() {
        let hasSecurityAccess = pdfURL.startAccessingSecurityScopedResource()
        defer {
            if hasSecurityAccess {
                pdfURL.stopAccessingSecurityScopedResource()
            }
        }
        
        if let document = PDFDocument(url: pdfURL) {
            self.pdfDocument = document
            pdfView.document = document
        }
    }
    
    @objc private func extractTextTapped() {
        guard let document = pdfDocument else { return }
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        OCRService.extractTextFromPDF(document, progress: { _ in }) { [weak self] extractedText in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
            
            if extractedText.isEmpty {
                let alert = UIAlertController(title: "No Text Found", message: "Could not extract any text from this document.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            } else {
                // Show text in a view controller
                let textVC = OCRTextViewController(text: extractedText)
                self.navigationController?.pushViewController(textVC, animated: true)
            }
        }
    }
    
    @objc private func signTapped() {
        print("🖊️ PDFActionVC: Sign button tapped")
        
        // Check if signature exists
        if let savedSignature = SignatureStore.shared.loadSignature() {
            print("✅ PDFActionVC: Found saved signature, showing placement overlay")
            // Use saved signature and show placement overlay
            showSignaturePlacement(with: savedSignature)
        } else {
            print("⚠️ PDFActionVC: No saved signature, showing creation screen")
            // No signature saved, create one
            let signatureVC = SignatureViewController()
            signatureVC.delegate = self
            present(signatureVC, animated: true)
        }
    }
    
    private func showSignaturePlacement(with signature: UIImage) {
        print("📐 PDFActionVC: Setting up signature placement overlay")
        
        guard let currentPage = pdfView.currentPage else {
            print("❌ PDFActionVC: No current page")
            return
        }
        
        let pageRect = pdfView.convert(currentPage.bounds(for: .mediaBox), from: currentPage)
        print("   Page rect in PDFView: \(pageRect)")
        
        // Initial signature rect (bottom right)
        let signatureSize = CGSize(width: pageRect.width * 0.4, height: pageRect.height * 0.2)
        let initialRect = CGRect(
            x: pageRect.midX - signatureSize.width / 2,
            y: pageRect.midY - signatureSize.height / 2,
            width: signatureSize.width,
            height: signatureSize.height
        )
        
        print("   Initial signature rect: \(initialRect)")
        print("   Creating SignatureEditableOverlayView")
        
        let overlayView = SignatureEditableOverlayView(signatureImage: signature, initialRect: initialRect)
        overlayView.delegate = self
        overlayView.frame = view.bounds
        view.addSubview(overlayView)
        
        print("✅ PDFActionVC: Overlay added to view hierarchy")
    }
    
    @objc private func shareTapped() {
        print("📤 Sharing PDF...")
        
        guard let document = pdfDocument else {
            print("❌ No PDF document to share")
            return
        }
        
        // Save any in-memory changes FIRST before sharing
        guard let updatedPDFData = document.dataRepresentation() else {
            print("❌ Could not get PDF data")
            return
        }
        
        // Write to temporary file for sharing
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("shared_document_\(UUID().uuidString).pdf")
        
        do {
            // Write the current (possibly signed) document to temp file
            try updatedPDFData.write(to: tempURL, options: .atomic)
            print("✅ Wrote PDF to temp location: \(tempURL)")
            
            // Share the temp file
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = shareButton
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                // Clean up temp file after sharing
                try? FileManager.default.removeItem(at: tempURL)
                print("🗑️ Cleaned up temp file")
            }
            present(activityVC, animated: true)
            
        } catch {
            print("⚠️ Error preparing PDF for sharing: \(error)")
            
            let alert = UIAlertController(title: "Share Failed", message: "Could not prepare the PDF for sharing.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - SignatureDelegate
    
    func signatureDidFinish(with signature: UIImage) {
        // Save the signature for future use
        SignatureStore.shared.saveSignature(signature)
        // Show placement overlay
        showSignaturePlacement(with: signature)
    }
    
    func signatureDidCancel() {
        // Do nothing
    }
    
    // MARK: - SignatureEditableDelegate
    
    func didConfirmSignaturePlacement(rect: CGRect, in overlayView: UIView) {
        // Prevent duplicate signature applications
        guard !isApplyingSignature else {
            print("⚠️ Already applying signature, ignoring duplicate call")
            return
        }
        
        isApplyingSignature = true
        
        guard let document = pdfDocument,
              let currentPage = pdfView.currentPage,
              let signature = SignatureStore.shared.loadSignature() else {
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
        
        // SIMPLIFIED COORDINATE CONVERSION
        // Convert overlay rect to pdfView coordinates
        let rectInPDFView = overlayView.convert(rect, to: pdfView)
        
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
            updateUndoButton()
            
            // Force PDFView to refresh
            pdfView.document = nil
            pdfView.document = document
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            print("✅ Signature applied successfully")
        } else {
            print("⚠️ Failed to sign document")
            
            let alert = UIAlertController(
                title: "Signature Failed",
                message: "Could not add signature to the document.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
        
        // Reset the flag after a delay to allow for next signature
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isApplyingSignature = false
        }
    }
    
    func didCancelSignaturePlacement() {
        // Do nothing
    }
    
    // MARK: - Undo Signature
    
    @objc private func undoSignature() {
        guard !signatureStates.isEmpty,
              let document = pdfDocument else { return }
        
        // Remove the last signature by restoring the original page
        let lastState = signatureStates.removeLast()
        
        document.removePage(at: lastState.pageIndex)
        document.insert(lastState.originalPage, at: lastState.pageIndex)
        
        // Update undo button state
        updateUndoButton()
        
        // Force PDFView to refresh
        pdfView.document = nil
        pdfView.document = document
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        print("↩️ Signature undone")
    }
    
    private func updateUndoButton() {
        undoButton?.isEnabled = !signatureStates.isEmpty
    }
}
