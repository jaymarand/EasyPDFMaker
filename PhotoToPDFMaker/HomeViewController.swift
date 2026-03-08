//
//  HomeViewController.swift
//  PhotoToPDFMaker
//

import UIKit

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ImportCoordinatorDelegate, PageSelectionDelegate {

    private var importCoordinator: ImportCoordinator?
    private var scannedImages: [UIImage] = []
    private var recentDocuments: [DocumentItem] = []
    
    // UI Elements
    private let titleLabel = UILabel()
    private let scanButton = UIButton(type: .system)
    private let importImageButton = UIButton(type: .system)
    private let importFileButton = UIButton(type: .system)
    private let recentLabel = UILabel()
    private let recentTableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateRecentDocuments()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Title with export button
        titleLabel.text = "Photo to PDF"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        let exportButton = UIButton(type: .system)
        exportButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        exportButton.tintColor = .systemBlue
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(exportButton)
        
        // Import buttons
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        importImageButton.setTitle(" Import Image", for: .normal)
        importImageButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        importImageButton.backgroundColor = .secondarySystemBackground
        importImageButton.layer.cornerRadius = 12
        importImageButton.contentHorizontalAlignment = .center
        importImageButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        importImageButton.addTarget(self, action: #selector(importImageTapped), for: .touchUpInside)
        
        importFileButton.setTitle(" Import File", for: .normal)
        importFileButton.setImage(UIImage(systemName: "doc"), for: .normal)
        importFileButton.backgroundColor = .secondarySystemBackground
        importFileButton.layer.cornerRadius = 12
        importFileButton.contentHorizontalAlignment = .center
        importFileButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        importFileButton.addTarget(self, action: #selector(importFileTapped), for: .touchUpInside)
        
        buttonStack.addArrangedSubview(importImageButton)
        buttonStack.addArrangedSubview(importFileButton)
        view.addSubview(buttonStack)
        
        // Recent Documents header
        recentLabel.text = "Recent Documents"
        recentLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        recentLabel.textColor = .secondaryLabel
        recentLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recentLabel)
        
        let viewAllBtn = UIButton(type: .system)
        viewAllBtn.setTitle("View All", for: .normal)
        viewAllBtn.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        viewAllBtn.addTarget(self, action: #selector(viewAllTapped), for: .touchUpInside)
        viewAllBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewAllBtn)
        
        // Recent documents table view
        recentTableView.delegate = self
        recentTableView.dataSource = self
        recentTableView.register(UITableViewCell.self, forCellReuseIdentifier: "RecentCell")
        recentTableView.backgroundColor = .systemBackground
        recentTableView.separatorStyle = .none
        recentTableView.isScrollEnabled = false
        recentTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(recentTableView)
        
        NSLayoutConstraint.activate([
            // Title and export button
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            exportButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            exportButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            exportButton.widthAnchor.constraint(equalToConstant: 44),
            exportButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Import buttons - more compact, right below title
            buttonStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 52),
            
            // Recent Documents
            recentLabel.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 40),
            recentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            viewAllBtn.centerYAnchor.constraint(equalTo: recentLabel.centerYAnchor),
            viewAllBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            recentTableView.topAnchor.constraint(equalTo: recentLabel.bottomAnchor, constant: 16),
            recentTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            recentTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            recentTableView.heightAnchor.constraint(equalToConstant: 504) // 6 rows * 84pt (72pt cell + 12pt spacing)
        ])
    }
    
    private func updateRecentDocuments() {
        recentDocuments = Array(DocumentStore.shared.listActiveDocuments().prefix(6))
        recentTableView.reloadData()
        
        // Update table height based on actual number of documents
        let rowHeight: CGFloat = 72
        let spacing: CGFloat = 12
        let totalHeight = CGFloat(recentDocuments.count) * (rowHeight + spacing) - (recentDocuments.isEmpty ? 0 : spacing)
        
        // Update height constraint
        for constraint in recentTableView.constraints {
            if constraint.firstAttribute == .height {
                constraint.constant = max(totalHeight, 50) // Minimum height for empty state
            }
        }
    }
    
    // MARK: - UITableView DataSource & Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentDocuments.isEmpty ? 1 : recentDocuments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return recentDocuments.isEmpty ? 50 : 84 // 72pt cell + 12pt bottom margin
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecentCell", for: indexPath)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        // Remove all existing subviews
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        if recentDocuments.isEmpty {
            // Empty state
            let emptyLabel = UILabel()
            emptyLabel.text = "No recent documents"
            emptyLabel.textColor = .secondaryLabel
            emptyLabel.font = .systemFont(ofSize: 17)
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(emptyLabel)
            
            NSLayoutConstraint.activate([
                emptyLabel.centerXAnchor.constraint(equalTo: cell.contentView.centerXAnchor),
                emptyLabel.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
            ])
            
            return cell
        }
        
        let doc = recentDocuments[indexPath.row]
        
        // Create container view (same as before)
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(container)
        
        // Document icon
        let iconView = UIImageView(image: UIImage(systemName: doc.type.iconName))
        iconView.tintColor = doc.isFavorite ? .systemYellow : .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconView)
        
        // Document name
        let nameLabel = UILabel()
        nameLabel.text = doc.displayName
        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameLabel)
        
        // Date
        let dateLabel = UILabel()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        dateLabel.text = formatter.string(from: doc.createdAt)
        dateLabel.font = .systemFont(ofSize: 15, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(dateLabel)
        
        // Page count
        let pageCountLabel = UILabel()
        pageCountLabel.text = "\(doc.pageCount)"
        pageCountLabel.font = .systemFont(ofSize: 17, weight: .regular)
        pageCountLabel.textColor = .secondaryLabel
        pageCountLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pageCountLabel)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            container.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            container.heightAnchor.constraint(equalToConstant: 72),
            
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            
            dateLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            
            pageCountLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            pageCountLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !recentDocuments.isEmpty else { return }
        let doc = recentDocuments[indexPath.row]
        
        switch doc.type {
        case .pdf:
            let vc = DocumentPreviewViewController(documentItem: doc)
            navigationController?.pushViewController(vc, animated: true)
        case .text:
            let fileURL = DocumentStore.shared.url(for: doc)
            if let textContent = try? String(contentsOf: fileURL, encoding: .utf8) {
                let vc = OCRTextViewController(text: textContent)
                navigationController?.pushViewController(vc, animated: true)
            } else {
                let alert = UIAlertController(title: "Error", message: "Could not open text file.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }
    
    // Context Menu (Long Press)
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard !recentDocuments.isEmpty else { return nil }
        let doc = recentDocuments[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let favoriteTitle = doc.isFavorite ? "Unfavorite" : "Favorite"
            let favoriteAction = UIAction(title: favoriteTitle, image: UIImage(systemName: doc.isFavorite ? "star.slash" : "star.fill")) { [weak self] _ in
                self?.toggleFavorite(for: doc)
            }
            
            let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.renameDocument(doc)
            }
            
            let shareAction = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                self?.shareDocument(doc, sourceView: tableView.cellForRow(at: indexPath) ?? tableView)
            }
            
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.deleteDocument(doc)
            }
            
            let archiveAction = UIAction(title: "Archive", image: UIImage(systemName: "archivebox")) { [weak self] _ in
                self?.archiveDocument(doc)
            }
            
            return UIMenu(title: "", children: [favoriteAction, renameAction, shareAction, deleteAction, archiveAction])
        }
    }
    
    // Swipe Actions
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !recentDocuments.isEmpty else { return nil }
        let doc = recentDocuments[indexPath.row]
        
        let favoriteAction = UIContextualAction(style: .normal, title: doc.isFavorite ? "Unfavorite" : "Favorite") { [weak self] (_, _, completionHandler) in
            self?.toggleFavorite(for: doc)
            completionHandler(true)
        }
        favoriteAction.backgroundColor = .systemYellow
        favoriteAction.image = UIImage(systemName: doc.isFavorite ? "star.slash.fill" : "star.fill")
        
        let configuration = UISwipeActionsConfiguration(actions: [favoriteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !recentDocuments.isEmpty else { return nil }
        let doc = recentDocuments[indexPath.row]
        
        let archiveAction = UIContextualAction(style: .normal, title: "Archive") { [weak self] (_, _, completionHandler) in
            self?.archiveDocument(doc)
            completionHandler(true)
        }
        archiveAction.backgroundColor = .systemIndigo
        archiveAction.image = UIImage(systemName: "archivebox.fill")
        
        let configuration = UISwipeActionsConfiguration(actions: [archiveAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    // Remove old document row methods
    
    private func removeOldDocumentRowMethods() {
        // This method is just a marker - remove documentRowTapped, documentRowLongPressed, documentRowSwipedRight, documentRowSwipedLeft, createDocumentRow
    }
    
    @objc private func importImageTapped() {
        importCoordinator = ImportCoordinator(presentingViewController: self)
        importCoordinator?.delegate = self
        importCoordinator?.startImageImport()
    }
    
    @objc private func importFileTapped() {
        importCoordinator = ImportCoordinator(presentingViewController: self)
        importCoordinator?.delegate = self
        importCoordinator?.startFileImport()
    }
    
    @objc private func viewAllTapped() {
        tabBarController?.selectedIndex = 1
    }
    
    @objc private func exportTapped() {
        let alert = UIAlertController(title: "Export Documents", message: "Choose what to export", preferredStyle: .actionSheet)
        
        let pdfCount = DocumentStore.shared.documentCount(ofType: .pdf)
        let textCount = DocumentStore.shared.documentCount(ofType: .text(.txt))
        let totalCount = DocumentStore.shared.documentCount()
        
        alert.addAction(UIAlertAction(title: "Export All PDFs (\(pdfCount))", style: .default) { [weak self] _ in
            self?.performExport(type: .pdf)
        })
        
        alert.addAction(UIAlertAction(title: "Export All Text Files (\(textCount))", style: .default) { [weak self] _ in
            self?.performExport(type: .text(.txt))
        })
        
        alert.addAction(UIAlertAction(title: "Export Everything (\(totalCount))", style: .default) { [weak self] _ in
            self?.performExport(type: nil)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func performExport(type: DocumentType?) {
        // Show loading
        let loadingAlert = UIAlertController(title: "Exporting...", message: "Please wait", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        // Perform export based on type
        let exportClosure: (@escaping (URL?) -> Void) -> Void
        
        if let type = type {
            switch type {
            case .pdf:
                exportClosure = DocumentStore.shared.exportPDFs
            case .text:
                exportClosure = DocumentStore.shared.exportTextFiles
            }
        } else {
            exportClosure = DocumentStore.shared.exportAllDocuments
        }
        
        exportClosure { [weak self] zipURL in
            loadingAlert.dismiss(animated: true) {
                guard let self = self else { return }
                
                if let zipURL = zipURL {
                    // Show share sheet
                    let activityVC = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
                    activityVC.completionWithItemsHandler = { _, _, _, _ in
                        // Clean up ZIP file
                        try? FileManager.default.removeItem(at: zipURL)
                    }
                    self.present(activityVC, animated: true)
                } else {
                    // Show error
                    let errorAlert = UIAlertController(
                        title: "Export Failed",
                        message: "No documents to export or an error occurred.",
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }
    
    // MARK: - PageSelectionDelegate
    
    func pageSelectionDidSelect(images: [UIImage]) {
        guard let firstImage = images.first else { return }
        scannedImages.removeAll()
        
        if images.count == 1 {
            showDocumentActions(for: firstImage)
        } else {
            let remainingImages = Array(images.dropFirst())
            showDocumentActions(for: firstImage, additionalImages: remainingImages)
        }
    }
    
    func pageSelectionDidCancel() {
        scannedImages = []
    }
    
    private func showDocumentActions(for image: UIImage) {
        showDocumentActions(for: image, additionalImages: [])
    }
    
    private func showDocumentActions(for image: UIImage, additionalImages: [UIImage]) {
        let actionVC = DocumentActionViewController(image: image, additionalImages: additionalImages)
        let nav = UINavigationController(rootViewController: actionVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    // MARK: - ImportCoordinatorDelegate
    func importCoordinatorDidFinishWithImages(_ images: [UIImage]) {
        print("✅ importCoordinatorDidFinishWithImages called with \(images.count) images")
        scannedImages = images
        
        // If only one image, skip selection
        if images.count == 1 {
            print("✅ Showing document actions for single image")
            showDocumentActions(for: images[0])
        } else {
            print("✅ Showing page selection for \(images.count) images")
            // Show page selection for multiple images
            let selectionVC = PageSelectionViewController(images: images)
            selectionVC.delegate = self
            selectionVC.modalPresentationStyle = .fullScreen
            present(selectionVC, animated: true)
        }
    }
    
    func importCoordinatorDidFinishWithPDF(_ url: URL) {
        print("✅ importCoordinatorDidFinishWithPDF called")
        // Show the PDF action screen with OCR, Sign, Share, Save options
        let actionVC = PDFActionViewController(pdfURL: url)
        let nav = UINavigationController(rootViewController: actionVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
    
    func importCoordinatorDidCancel() {
        print("✅ importCoordinatorDidCancel called")
    }
    
    // MARK: - Document Actions (Swipe & Context Menu)
    
    @objc private func documentRowLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let view = gesture.view else { return }
        let docs = Array(DocumentStore.shared.listActiveDocuments().prefix(6))
        guard view.tag < docs.count else { return }
        let doc = docs[view.tag]
        
        let alert = UIAlertController(title: doc.displayName, message: nil, preferredStyle: .actionSheet)
        
        // Favorite action
        let favoriteTitle = doc.isFavorite ? "Unfavorite" : "Favorite"
        alert.addAction(UIAlertAction(title: favoriteTitle, style: .default, handler: { [weak self] _ in
            self?.toggleFavorite(for: doc)
        }))
        
        // Rename action
        alert.addAction(UIAlertAction(title: "Rename", style: .default, handler: { [weak self] _ in
            self?.renameDocument(doc)
        }))
        
        // Share action
        alert.addAction(UIAlertAction(title: "Share", style: .default, handler: { [weak self] _ in
            self?.shareDocument(doc, sourceView: view)
        }))
        
        // Delete action
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.deleteDocument(doc)
        }))
        
        // Archive action
        alert.addAction(UIAlertAction(title: "Archive", style: .default, handler: { [weak self] _ in
            self?.archiveDocument(doc)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = view.bounds
        }
        
        present(alert, animated: true)
    }
    
    @objc private func documentRowSwipedRight(_ gesture: UISwipeGestureRecognizer) {
        guard let view = gesture.view else { return }
        let docs = Array(DocumentStore.shared.listActiveDocuments().prefix(6))
        guard view.tag < docs.count else { return }
        let doc = docs[view.tag]
        
        toggleFavorite(for: doc)
        
        // Visual feedback
        UIView.animate(withDuration: 0.2, animations: {
            view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                view.transform = .identity
            }
        }
    }
    
    @objc private func documentRowSwipedLeft(_ gesture: UISwipeGestureRecognizer) {
        guard let view = gesture.view else { return }
        let docs = Array(DocumentStore.shared.listActiveDocuments().prefix(6))
        guard view.tag < docs.count else { return }
        let doc = docs[view.tag]
        
        archiveDocument(doc)
        
        // Visual feedback
        UIView.animate(withDuration: 0.2, animations: {
            view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                view.transform = .identity
            }
        }
    }
    
    private func toggleFavorite(for doc: DocumentItem) {
        DocumentStore.shared.toggleFavorite(id: doc.id)
        updateRecentDocuments()
        
        let message = doc.isFavorite ? "Removed from favorites" : "Added to favorites"
        showToast(message: message)
    }
    
    private func archiveDocument(_ doc: DocumentItem) {
        DocumentStore.shared.toggleArchive(id: doc.id)
        updateRecentDocuments()
        showToast(message: "Document archived")
    }
    
    private func renameDocument(_ doc: DocumentItem) {
        let alert = UIAlertController(title: "Rename Document", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = doc.displayName
            textField.placeholder = "Document name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            DocumentStore.shared.rename(id: doc.id, newName: newName)
            self?.updateRecentDocuments()
        })
        
        present(alert, animated: true)
    }
    
    private func shareDocument(_ doc: DocumentItem, sourceView: UIView) {
        let fileURL = DocumentStore.shared.url(for: doc)
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    private func deleteDocument(_ doc: DocumentItem) {
        let alert = UIAlertController(
            title: "Delete Document?",
            message: "This will permanently delete \"\(doc.displayName)\".",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            DocumentStore.shared.delete(id: doc.id)
            self?.updateRecentDocuments()
        })
        
        present(alert, animated: true)
    }
    
    private func showToast(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
}
