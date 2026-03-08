//
//  HistoryViewController.swift
//  PhotoToPDFMaker
//

import UIKit

class HistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView = UITableView()
    private var documents: [DocumentItem] = []
    private var showingArchived = false
    private var archivedButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "History"
        view.backgroundColor = .systemBackground
        
        // Add "Show Archived" button
        archivedButton = UIBarButtonItem(title: "Show Archived", style: .plain, target: self, action: #selector(toggleArchivedView))
        navigationItem.rightBarButtonItem = archivedButton
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDocuments()
    }
    
    @objc private func toggleArchivedView() {
        showingArchived.toggle()
        archivedButton.title = showingArchived ? "Hide Archived" : "Show Archived"
        title = showingArchived ? "All Documents" : "History"
        loadDocuments()
    }
    
    private func loadDocuments() {
        if showingArchived {
            // Show ALL documents (archived + active)
            documents = DocumentStore.shared.listDocuments()
        } else {
            // Show only active documents
            documents = DocumentStore.shared.listActiveDocuments()
        }
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return documents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let doc = documents[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = doc.displayName
        content.image = UIImage(systemName: doc.type.iconName)
        content.imageProperties.tintColor = doc.isFavorite ? .systemYellow : .systemBlue
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        content.secondaryText = formatter.string(from: doc.createdAt) + " - \(doc.pageCount) page(s)"
        
        cell.contentConfiguration = content
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let doc = documents[indexPath.row]
        
        switch doc.type {
        case .pdf:
            let vc = DocumentPreviewViewController(documentItem: doc)
            navigationController?.pushViewController(vc, animated: true)
        case .text:
            let fileURL = DocumentStore.shared.url(for: doc)
            if let textContent = try? String(contentsOf: fileURL, encoding: .utf8) {
                let vc = OCRTextViewController(text: textContent)
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    // MARK: - Context Menu (Long Press)
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let doc = documents[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            // Favorite action
            let favoriteTitle = doc.isFavorite ? "Unfavorite" : "Favorite"
            let favoriteIcon = doc.isFavorite ? "star.slash" : "star.fill"
            let favoriteAction = UIAction(title: favoriteTitle, image: UIImage(systemName: favoriteIcon)) { [weak self] _ in
                self?.toggleFavorite(at: indexPath)
            }
            
            // Rename action
            let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.renameDocument(at: indexPath)
            }
            
            // Share action
            let shareAction = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                self?.shareDocument(at: indexPath)
            }
            
            // Delete action
            let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.deleteDocument(at: indexPath)
            }
            
            // Archive action
            let archiveTitle = doc.isArchived ? "Unarchive" : "Archive"
            let archiveIcon = doc.isArchived ? "tray.and.arrow.up" : "archivebox"
            let archiveAction = UIAction(title: archiveTitle, image: UIImage(systemName: archiveIcon)) { [weak self] _ in
                self?.toggleArchive(at: indexPath)
            }
            
            return UIMenu(title: "", children: [favoriteAction, renameAction, shareAction, deleteAction, archiveAction])
        }
    }
    
    // MARK: - Swipe Actions
    
    // Swipe right to favorite/unfavorite
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let doc = documents[indexPath.row]
        
        let favoriteAction = UIContextualAction(style: .normal, title: doc.isFavorite ? "Unfavorite" : "Favorite") { [weak self] (action, view, completionHandler) in
            self?.toggleFavorite(at: indexPath)
            completionHandler(true)
        }
        favoriteAction.backgroundColor = .systemYellow
        favoriteAction.image = UIImage(systemName: doc.isFavorite ? "star.slash.fill" : "star.fill")
        
        let configuration = UISwipeActionsConfiguration(actions: [favoriteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    // Swipe left to archive/unarchive
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let doc = documents[indexPath.row]
        
        let archiveAction = UIContextualAction(style: .normal, title: doc.isArchived ? "Unarchive" : "Archive") { [weak self] (action, view, completionHandler) in
            self?.toggleArchive(at: indexPath)
            completionHandler(true)
        }
        archiveAction.backgroundColor = .systemIndigo
        archiveAction.image = UIImage(systemName: doc.isArchived ? "tray.and.arrow.up.fill" : "archivebox.fill")
        
        let configuration = UISwipeActionsConfiguration(actions: [archiveAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    // MARK: - Action Methods
    
    private func toggleFavorite(at indexPath: IndexPath) {
        let doc = documents[indexPath.row]
        DocumentStore.shared.toggleFavorite(id: doc.id)
        loadDocuments()
    }
    
    private func toggleArchive(at indexPath: IndexPath) {
        let doc = documents[indexPath.row]
        DocumentStore.shared.toggleArchive(id: doc.id)
        
        // Remove from current list with animation
        documents.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
    
    private func renameDocument(at indexPath: IndexPath) {
        let doc = documents[indexPath.row]
        
        let alert = UIAlertController(title: "Rename Document", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = doc.displayName
            textField.placeholder = "Document name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            DocumentStore.shared.rename(id: doc.id, newName: newName)
            self?.loadDocuments()
        })
        
        present(alert, animated: true)
    }
    
    private func shareDocument(at indexPath: IndexPath) {
        let doc = documents[indexPath.row]
        let fileURL = DocumentStore.shared.url(for: doc)
        
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        // For iPad support
        if let popover = activityVC.popoverPresentationController {
            if let cell = tableView.cellForRow(at: indexPath) {
                popover.sourceView = cell
                popover.sourceRect = cell.bounds
            }
        }
        
        present(activityVC, animated: true)
    }
    
    private func deleteDocument(at indexPath: IndexPath) {
        let doc = documents[indexPath.row]
        
        let alert = UIAlertController(
            title: "Delete Document?",
            message: "This will permanently delete \"\(doc.displayName)\".",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            DocumentStore.shared.delete(id: doc.id)
            self?.documents.remove(at: indexPath.row)
            self?.tableView.deleteRows(at: [indexPath], with: .fade)
        })
        
        present(alert, animated: true)
    }
}
