 //
//  DocumentActionViewController.swift
//  PhotoToPDFMaker
//

import UIKit

class DocumentActionViewController: UIViewController, TextEditDelegate, SignatureDelegate, SignatureEditableDelegate, UIScrollViewDelegate {
    
    private let scannedImage: UIImage
    private var pageImages: [UIImage]
    private var currentPageIndex = 0
    private var enhancedImage: UIImage
    private var unsignedImage: UIImage? // Store version before signature
    private var unsignedImagePageIndex: Int?
    private var extractedText: String?
    private var signatureImage: UIImage?
    
    private let imageScrollView = UIScrollView()
    private let pageStackView = UIStackView()
    private var pageImageViews: [UIImageView] = []
    private var pageStackWidthConstraint: NSLayoutConstraint?
    private let pageLabel = UILabel()
    private let actionStack = UIStackView()
    private let extractTextButton = UIButton(type: .system)
    private let signButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    init(image: UIImage, additionalImages: [UIImage] = []) {
        self.scannedImage = image
        self.pageImages = [image] + additionalImages
        self.enhancedImage = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        performAutoEnhancement()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUnderlyingCenterButtonHidden(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            setUnderlyingCenterButtonHidden(false)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation
        navigationItem.title = "Document"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        
        // Settings button in top-right (will be replaced by undo after signature)
        let settingsButton = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        navigationItem.rightBarButtonItem = settingsButton
        
        imageScrollView.isPagingEnabled = true
        imageScrollView.showsHorizontalScrollIndicator = false
        imageScrollView.delegate = self
        imageScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageScrollView)
        
        pageStackView.axis = .horizontal
        pageStackView.spacing = 0
        pageStackView.distribution = .fill
        pageStackView.translatesAutoresizingMaskIntoConstraints = false
        imageScrollView.addSubview(pageStackView)
        
        for image in pageImages {
            let imageContainer = UIView()
            imageContainer.translatesAutoresizingMaskIntoConstraints = false
            
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .secondarySystemBackground
            imageView.layer.cornerRadius = 12
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            imageContainer.addSubview(imageView)
            pageStackView.addArrangedSubview(imageContainer)
            pageImageViews.append(imageView)
            
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
                imageContainer.widthAnchor.constraint(equalTo: imageScrollView.widthAnchor)
            ])
        }
        
        pageLabel.font = .systemFont(ofSize: 14, weight: .medium)
        pageLabel.textColor = .secondaryLabel
        pageLabel.textAlignment = .center
        pageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageLabel)
        
        // Activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        
        // Action buttons stack
        actionStack.axis = .horizontal
        actionStack.spacing = 16
        actionStack.distribution = .fillEqually
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        
        configureButton(extractTextButton, title: "OCR", icon: "doc.text.viewfinder", action: #selector(extractTextTapped))
        configureButton(signButton, title: "Sign", icon: "signature", action: #selector(signTapped))
        configureButton(shareButton, title: "Share", icon: "square.and.arrow.up", action: #selector(shareTapped))
        configureButton(saveButton, title: "Save", icon: "checkmark.circle.fill", action: #selector(saveTapped), isPrimary: true)
        
        actionStack.addArrangedSubview(extractTextButton)
        actionStack.addArrangedSubview(signButton)
        actionStack.addArrangedSubview(shareButton)
        actionStack.addArrangedSubview(saveButton)
        view.addSubview(actionStack)
        
        NSLayoutConstraint.activate([
            pageLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            pageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            imageScrollView.topAnchor.constraint(equalTo: pageLabel.bottomAnchor, constant: 8),
            imageScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageScrollView.bottomAnchor.constraint(equalTo: actionStack.topAnchor, constant: -16),
            
            pageStackView.topAnchor.constraint(equalTo: imageScrollView.contentLayoutGuide.topAnchor),
            pageStackView.leadingAnchor.constraint(equalTo: imageScrollView.contentLayoutGuide.leadingAnchor),
            pageStackView.trailingAnchor.constraint(equalTo: imageScrollView.contentLayoutGuide.trailingAnchor),
            pageStackView.bottomAnchor.constraint(equalTo: imageScrollView.contentLayoutGuide.bottomAnchor),
            pageStackView.heightAnchor.constraint(equalTo: imageScrollView.frameLayoutGuide.heightAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: imageScrollView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: imageScrollView.centerYAnchor),
            
            actionStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            actionStack.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        pageStackWidthConstraint = pageStackView.widthAnchor.constraint(
            equalTo: imageScrollView.frameLayoutGuide.widthAnchor,
            multiplier: CGFloat(pageImages.count)
        )
        pageStackWidthConstraint?.isActive = true
        
        updatePageUI()
    }
    
    private func configureButton(_ button: UIButton, title: String, icon: String, action: Selector, isPrimary: Bool = false) {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: icon)
        config.title = title
        config.imagePlacement = .top
        config.imagePadding = 4
        config.baseForegroundColor = isPrimary ? .white : .systemBlue
        config.background.backgroundColor = isPrimary ? .systemBlue : .secondarySystemBackground
        config.background.cornerRadius = 12
        
        button.configuration = config
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: isPrimary ? .semibold : .medium)
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    
    private func performAutoEnhancement() {
        activityIndicator.startAnimating()
        imageScrollView.alpha = 0.5
        
        ImageProcessor.enhanceDocument(image: scannedImage) { [weak self] enhancedImage in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.imageScrollView.alpha = 1.0
            
            if let enhanced = enhancedImage {
                self.enhancedImage = enhanced
                self.pageImages[0] = enhanced
                self.pageImageViews[0].image = enhanced
            } else {
                // If enhancement fails, use original
                self.pageImages[0] = self.scannedImage
                self.pageImageViews[0].image = self.scannedImage
            }
        }
    }
    
    private func updatePageUI() {
        enhancedImage = pageImages[currentPageIndex]
        pageLabel.text = "Page \(currentPageIndex + 1) of \(pageImages.count)"
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0 else { return }
        currentPageIndex = Int(round(scrollView.contentOffset.x / pageWidth))
        updatePageUI()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        let pageWidth = scrollView.bounds.width
        guard pageWidth > 0 else { return }
        currentPageIndex = Int(round(scrollView.contentOffset.x / pageWidth))
        updatePageUI()
    }
    
    @objc private func extractTextTapped() {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        OCRService.extractText(from: enhancedImage) { [weak self] text in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
            
            guard let extractedText = text, !extractedText.isEmpty else {
                let alert = UIAlertController(title: "No Text Found", message: "Could not extract any text from this document.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            
            // Show OCR text with export options (NOT embedded in PDF)
            let textVC = OCRTextViewController(text: extractedText)
            self.navigationController?.pushViewController(textVC, animated: true)
        }
    }
    
    @objc private func signTapped() {
        // Check if signature already exists
        if SignatureStore.shared.hasSignature, let savedSignature = SignatureStore.shared.loadSignature() {
            print("✅ Found existing signature, showing placement")
            self.signatureImage = savedSignature
            showSignaturePlacement(with: savedSignature)
        } else {
            print("⚠️ No signature found, creating new one")
            let signatureVC = SignatureViewController()
            signatureVC.delegate = self
            present(signatureVC, animated: true)
        }
    }
    
    @objc private func shareTapped() {
        generatePDF { [weak self] pdfData in
            guard let self = self, let data = pdfData else { return }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("document.pdf")
            try? data.write(to: tempURL)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                try? FileManager.default.removeItem(at: tempURL)
            }
            self.present(activityVC, animated: true)
        }
    }
    
    @objc private func saveTapped() {
        generatePDF { [weak self] pdfData in
            guard let self = self, let data = pdfData else { return }
            
            let pageCount = self.pageImages.count
            if DocumentStore.shared.saveNewDocument(pdfData: data, pageCount: pageCount) != nil {
                self.setUnderlyingCenterButtonHidden(false)
                self.dismiss(animated: true) {
                    self.navigationController?.popToRootViewController(animated: false)
                }
            }
        }
    }
    
    @objc private func cancelTapped() {
        setUnderlyingCenterButtonHidden(false)
        dismiss(animated: true)
    }
    
    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
    
    @objc private func undoSignatureTapped() {
        // Restore the unsigned version
        if let unsigned = unsignedImage {
            enhancedImage = unsigned
            if unsignedImagePageIndex == currentPageIndex {
                pageImages[currentPageIndex] = unsigned
                pageImageViews[currentPageIndex].image = unsigned
            }
            unsignedImage = nil
            unsignedImagePageIndex = nil
            
            // Restore settings button
            let settingsButton = UIBarButtonItem(
                image: UIImage(systemName: "gear"),
                style: .plain,
                target: self,
                action: #selector(settingsTapped)
            )
            navigationItem.rightBarButtonItem = settingsButton
            
            print("✅ Signature removed, image restored")
            
            // Show toast
            let alert = UIAlertController(title: nil, message: "Signature removed", preferredStyle: .alert)
            present(alert, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                alert.dismiss(animated: true)
            }
        }
    }
    
    private func generatePDF(completion: @escaping (Data?) -> Void) {
        // If text was extracted and edited, only single-page docs can be exported as searchable currently.
        if let text = extractedText, pageImages.count == 1 {
            PDFRenderer.createSearchablePDF(from: pageImages[0], text: text, completion: completion)
        } else {
            PDFRenderer.createPDF(from: pageImages, completion: completion)
        }
    }
    
    // REMOVED: overlaySignature method - signature is already burned into enhancedImage
    
    private func overlaySignatureAtPosition(_ signature: UIImage, on image: UIImage, at rect: CGRect) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            // Draw original image
            image.draw(at: .zero)
            
            // Draw signature at specified position
            signature.draw(in: rect)
        }
    }
    
    // MARK: - TextEditDelegate
    
    func textEditDidFinish(with editedText: String) {
        self.extractedText = editedText
        
        // Show confirmation
        let alert = UIAlertController(title: "Text Saved", message: "Your edited text will be embedded in the PDF, making it searchable.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func textEditDidCancel() {
        // Do nothing
    }
    
    // MARK: - SignatureDelegate
    
    func signatureDidFinish(with signature: UIImage) {
        // Save the signature
        SignatureStore.shared.saveSignature(signature)
        self.signatureImage = signature
        
        // Show signature placement overlay
        print("✅ Signature created, showing placement overlay")
        showSignaturePlacement(with: signature)
    }
    
    func signatureDidCancel() {
        // Do nothing
    }
    
    // MARK: - Signature Placement
    
    private func showSignaturePlacement(with signature: UIImage) {
        print("✅ Starting signature placement for scanned document")
        print("   View bounds: \(view.bounds)")
        print("   Signature size: \(signature.size)")
        
        guard let activeImageView = pageImageViews[safe: currentPageIndex] else { return }
        let imageViewRect = activeImageView.convert(activeImageView.bounds, to: view)
        let signatureSize = CGSize(width: imageViewRect.width * 0.4, height: imageViewRect.height * 0.2)
        let initialRect = CGRect(
            x: imageViewRect.midX - signatureSize.width / 2,
            y: imageViewRect.midY - signatureSize.height / 2,
            width: signatureSize.width,
            height: signatureSize.height
        )
        
        // Use SignatureEditableOverlayView which has corner handles
        let overlay = SignatureEditableOverlayView(signatureImage: signature, initialRect: initialRect)
        overlay.delegate = self
        overlay.frame = view.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(overlay)
        
        print("✅ Placement overlay added with corner handles")
    }
    
    // MARK: - SignatureEditableDelegate
    
    func didConfirmSignaturePlacement(rect: CGRect, in overlayView: UIView) {
        print("✅ Signature confirmed at rect: \(rect)")
        
        guard let activeImageView = pageImageViews[safe: currentPageIndex] else { return }
        print("   Image view frame: \(activeImageView.frame)")
        
        // Convert the overlay rect to image coordinates
        let imageViewRect = overlayView.convert(rect, to: activeImageView)
        
        // Convert from view coordinates to image coordinates
        let imageSize = enhancedImage.size
        let imageViewSize = activeImageView.bounds.size
        
        // Calculate scale factor (imageView uses scaleAspectFit)
        let imageAspect = imageSize.width / imageSize.height
        let viewAspect = imageViewSize.width / imageViewSize.height
        
        var displayedImageSize: CGSize
        var displayedImageOrigin: CGPoint
        
        if imageAspect > viewAspect {
            // Image is wider - fits to width
            displayedImageSize = CGSize(width: imageViewSize.width, height: imageViewSize.width / imageAspect)
            displayedImageOrigin = CGPoint(x: 0, y: (imageViewSize.height - displayedImageSize.height) / 2)
        } else {
            // Image is taller - fits to height
            displayedImageSize = CGSize(width: imageViewSize.height * imageAspect, height: imageViewSize.height)
            displayedImageOrigin = CGPoint(x: (imageViewSize.width - displayedImageSize.width) / 2, y: 0)
        }
        
        // Calculate relative position
        let relativeX = (imageViewRect.origin.x - displayedImageOrigin.x) / displayedImageSize.width
        let relativeY = (imageViewRect.origin.y - displayedImageOrigin.y) / displayedImageSize.height
        let relativeWidth = imageViewRect.width / displayedImageSize.width
        let relativeHeight = imageViewRect.height / displayedImageSize.height
        
        // Apply to actual image coordinates
        let imageRect = CGRect(
            x: relativeX * imageSize.width,
            y: relativeY * imageSize.height,
            width: relativeWidth * imageSize.width,
            height: relativeHeight * imageSize.height
        )
        
        print("📍 Overlay rect: \(rect)")
        print("📍 ImageView rect: \(imageViewRect)")
        print("📍 Relative position: (\(relativeX), \(relativeY))")
        print("📍 Image rect: \(imageRect)")
        
        // Save the unsigned version before applying signature
        unsignedImage = enhancedImage
        unsignedImagePageIndex = currentPageIndex
        
        guard let signatureImage else {
            print("❌ Signature image missing at placement confirmation")
            return
        }
        
        // Overlay signature on the image
        if let signedImage = overlaySignatureAtPosition(signatureImage, on: enhancedImage, at: imageRect) {
            enhancedImage = signedImage
            pageImages[currentPageIndex] = signedImage
            pageImageViews[currentPageIndex].image = signedImage
            print("✅ Signature overlaid on image")
            
            // Show undo button in navigation bar
            let undoButton = UIBarButtonItem(
                image: UIImage(systemName: "arrow.uturn.backward"),
                style: .plain,
                target: self,
                action: #selector(undoSignatureTapped)
            )
            navigationItem.rightBarButtonItem = undoButton
            
        } else {
            print("❌ Failed to overlay signature")
        }
    }
    
    func didCancelSignaturePlacement() {
        print("❌ Signature placement cancelled")
    }
    
    private func setUnderlyingCenterButtonHidden(_ hidden: Bool) {
        if let tabController = view.window?.rootViewController as? MainTabBarController {
            tabController.setCenterButtonHidden(hidden)
            return
        }
        
        var candidate: UIViewController? = presentingViewController
        while let current = candidate {
            if let tabController = current as? MainTabBarController {
                tabController.setCenterButtonHidden(hidden)
                return
            }
            if let nav = current as? UINavigationController,
               let tabController = nav.tabBarController as? MainTabBarController {
                tabController.setCenterButtonHidden(hidden)
                return
            }
            candidate = current.presentingViewController
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
