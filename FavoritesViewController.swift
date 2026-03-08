//
//  FavoritesViewController.swift
//  PhotoToPDFMaker
//

import UIKit

class FavoritesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView = UITableView()
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    private let emptyStateIcon = UIImageView()
    
    private var favoriteDocuments: [DocumentItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Favorites"
        view.backgroundColor = .systemBackground
        
        setupTableView()
        setupEmptyState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFavorites()
    }
    
    private func setupTableView() {
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
    
    private func setupEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)
        
        // Star icon
        emptyStateIcon.image = UIImage(systemName: "star.fill")
        emptyStateIcon.tintColor = .systemGray3
        emptyStateIcon.contentMode = .scaleAspectFit
        emptyStateIcon.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(emptyStateIcon)
        
        // Message label
        emptyStateLabel.text = "No favorites yet\n\nSwipe right on any document to add it to favorites"
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.font = .systemFont(ofSize: 17)
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            
            emptyStateIcon.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateIcon.widthAnchor.constraint(equalToConstant: 80),
            emptyStateIcon.heightAnchor.constraint(equalToConstant: 80),
            
            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateIcon.bottomAnchor, constant: 24),
            emptyStateLabel.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor),
            emptyStateLabel.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor)
        ])
    }
    
    private func loadFavorites() {
        favoriteDocuments = DocumentStore.shared.listFavoriteDocuments()
        
        let isEmpty = favoriteDocuments.isEmpty
        tableView.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
        
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favoriteDocuments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let doc = favoriteDocuments[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = doc.displayName
        content.image = UIImage(systemName: doc.type.iconName)
        content.imageProperties.tintColor = .systemBlue
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        content.secondaryText = formatter.string(from: doc.createdAt) + " • \(doc.pageCount) page(s)"
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let doc = favoriteDocuments[indexPath.row]
        
        // Open appropriate viewer based on document type
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
        let doc = favoriteDocuments[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            // Unfavorite action (since we're in favorites view)
            let unfavoriteAction = UIAction(title: "Unfavorite", image: UIImage(systemName: "star.slash")) { [weak self] _ in
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
            
            return UIMenu(title: "", children: [unfavoriteAction, renameAction, shareAction, deleteAction, archiveAction])
        }
    }
    
    // MARK: - Swipe Actions
    
    // Swipe Right: Unfavorite (in favorites view)
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let unfavoriteAction = UIContextualAction(style: .normal, title: "Unfavorite") { [weak self] (action, view, completionHandler) in
            self?.toggleFavorite(at: indexPath)
            completionHandler(true)
        }
        unfavoriteAction.backgroundColor = .systemOrange
        unfavoriteAction.image = UIImage(systemName: "star.slash.fill")
        
        let configuration = UISwipeActionsConfiguration(actions: [unfavoriteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    // Swipe to unfavorite or delete
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let doc = favoriteDocuments[indexPath.row]
        
        let archiveAction = UIContextualAction(style: .normal, title: "Archive") { [weak self] (action, view, completionHandler) in
            self?.toggleArchive(at: indexPath)
            completionHandler(true)
        }
        archiveAction.backgroundColor = .systemIndigo
        archiveAction.image = UIImage(systemName: "archivebox.fill")
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            let doc = self.favoriteDocuments[indexPath.row]
            
            // Show confirmation
            let alert = UIAlertController(
                title: "Delete Document?",
                message: "This will permanently delete \"\(doc.displayName)\".",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completionHandler(false)
            })
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                DocumentStore.shared.delete(id: doc.id)
                self.favoriteDocuments.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                if self.favoriteDocuments.isEmpty {
                    self.loadFavorites() // Show empty state
                }
                
                completionHandler(true)
            })
            self.present(alert, animated: true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, archiveAction])
        return configuration
    }
    
    // MARK: - Action Methods
    
    private func toggleFavorite(at indexPath: IndexPath) {
        let doc = favoriteDocuments[indexPath.row]
        DocumentStore.shared.toggleFavorite(id: doc.id)
        
        favoriteDocuments.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        
        if favoriteDocuments.isEmpty {
            loadFavorites() // Show empty state
        }
    }
    
    private func toggleArchive(at indexPath: IndexPath) {
        let doc = favoriteDocuments[indexPath.row]
        DocumentStore.shared.toggleArchive(id: doc.id)
        
        // Remove from favorites list since archived items are hidden
        favoriteDocuments.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
        
        if favoriteDocuments.isEmpty {
            loadFavorites() // Show empty state
        }
    }
    
    private func renameDocument(at indexPath: IndexPath) {
        let doc = favoriteDocuments[indexPath.row]
        
        let alert = UIAlertController(title: "Rename Document", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = doc.displayName
            textField.placeholder = "Document name"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
            guard let newName = alert.textFields?.first?.text, !newName.isEmpty else { return }
            DocumentStore.shared.rename(id: doc.id, newName: newName)
            self?.loadFavorites()
        })
        
        present(alert, animated: true)
    }
    
    private func shareDocument(at indexPath: IndexPath) {
        let doc = favoriteDocuments[indexPath.row]
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
        let doc = favoriteDocuments[indexPath.row]
        
        let alert = UIAlertController(
            title: "Delete Document?",
            message: "This will permanently delete \"\(doc.displayName)\".",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            DocumentStore.shared.delete(id: doc.id)
            self?.favoriteDocuments.remove(at: indexPath.row)
            self?.tableView.deleteRows(at: [indexPath], with: .fade)
            
            if self?.favoriteDocuments.isEmpty == true {
                self?.loadFavorites() // Show empty state
            }
        })
        
        present(alert, animated: true)
    }
}
