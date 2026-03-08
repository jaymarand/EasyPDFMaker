//
//  SettingsViewController.swift
//  PhotoToPDFMaker
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private enum Section: Int, CaseIterable {
        case general
        case notifications
        case purchases
        case backup
        case helpSupport
        case legal
        case other
        case version
        
        var title: String? {
            switch self {
            case .general: return "General"
            case .notifications: return "Notifications"
            case .purchases: return "Purchases"
            case .backup: return "Backup & Export"
            case .helpSupport: return "Help & Support"
            case .legal: return "Legal"
            case .other: return "Other"
            case .version: return nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ValueCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - TableView Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .general: return 1 // Manage Signature
        case .notifications: return 1
        case .purchases: return 1 // Restore Purchases
        case .backup: return 3 // Export PDFs, Export Text Files, Export Everything
        case .helpSupport: return 2
        case .legal: return 2 // Terms of Service, Privacy Policy
        case .other: return 2
        case .version: return 1
        case .none: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .general:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = SignatureStore.shared.hasSignature ? "View Signature" : "Add Signature"
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .notifications:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = "Notifications"
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .purchases:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = "Restore Purchases"
            cell.contentConfiguration = content
            cell.accessoryType = .none
            return cell
            
        case .backup:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            
            switch indexPath.row {
            case 0:
                content.text = "Export All PDFs"
            case 1:
                content.text = "Export All Text Files"
            case 2:
                content.text = "Export Everything"
            default:
                break
            }
            
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .helpSupport:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = indexPath.row == 0 ? "Help Center" : "Contact Support"
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .legal:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = indexPath.row == 0 ? "Terms of Service" : "Privacy Policy"
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .other:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = indexPath.row == 0 ? "Share This App" : "Rate Us"
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .version:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = "App Version 1.0"
            content.textProperties.color = .secondaryLabel
            cell.contentConfiguration = content
            cell.selectionStyle = .none
            return cell
            
        case .none:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch Section(rawValue: indexPath.section) {
        case .general:
            // Manage Signature
            if SignatureStore.shared.hasSignature {
                // Show signature preview
                let previewVC = SignaturePreviewViewController()
                navigationController?.pushViewController(previewVC, animated: true)
            } else {
                // Create new signature
                let signatureVC = SignatureViewController()
                signatureVC.isCreatingSignature = true
                let nav = UINavigationController(rootViewController: signatureVC)
                nav.modalPresentationStyle = .formSheet
                present(nav, animated: true)
            }
        case .notifications:
            // Show notification settings
            let notificationVC = NotificationSettingsViewController()
            navigationController?.pushViewController(notificationVC, animated: true)
        case .purchases:
            // Restore Purchases
            restorePurchases()
        case .backup:
            // Handle backup/export options
            handleBackupOption(at: indexPath.row)
        case .legal:
            if indexPath.row == 0 {
                // Terms of Service
                showTermsOfService()
            } else {
                // Privacy Policy
                showPrivacyPolicy()
            }
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func restorePurchases() {
        // Show loading indicator
        let alert = UIAlertController(title: "Restoring Purchases", message: "Please wait...", preferredStyle: .alert)
        present(alert, animated: true)
        
        // TODO: Implement StoreKit restore purchases logic
        // For now, we'll simulate the restore process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            alert.dismiss(animated: true) {
                // Show success or failure message
                let resultAlert = UIAlertController(
                    title: "Restore Complete",
                    message: "Your purchases have been restored successfully.",
                    preferredStyle: .alert
                )
                resultAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(resultAlert, animated: true)
            }
        }
        
        /* Uncomment and implement when you add StoreKit:
        
        import StoreKit
        
        SKPaymentQueue.default().restoreCompletedTransactions()
        
        // Implement SKPaymentTransactionObserver delegate methods:
        // - paymentQueueRestoreCompletedTransactionsFinished(_:)
        // - paymentQueue(_:restoreCompletedTransactionsFailedWithError:)
        
        */
    }
    
    private func handleBackupOption(at row: Int) {
        // Show loading indicator
        let loadingAlert = UIAlertController(title: "Exporting...", message: "Please wait", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        // Determine export type based on selected row
        let exportClosure: (@escaping (URL?) -> Void) -> Void
        let exportTitle: String
        
        switch row {
        case 0: // Export All PDFs
            exportClosure = DocumentStore.shared.exportPDFs
            exportTitle = "PDFs"
        case 1: // Export All Text Files
            exportClosure = DocumentStore.shared.exportTextFiles
            exportTitle = "Text Files"
        case 2: // Export Everything
            exportClosure = DocumentStore.shared.exportAllDocuments
            exportTitle = "All Documents"
        default:
            loadingAlert.dismiss(animated: true)
            return
        }
        
        // Perform the export
        exportClosure { [weak self] zipURL in
            loadingAlert.dismiss(animated: true) {
                guard let self = self else { return }
                
                if let zipURL = zipURL {
                    // Show share sheet
                    let activityVC = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
                    activityVC.completionWithItemsHandler = { _, _, _, _ in
                        // Clean up ZIP file after sharing
                        try? FileManager.default.removeItem(at: zipURL)
                    }
                    
                    // For iPad support
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = self.view
                        popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                    
                    self.present(activityVC, animated: true)
                } else {
                    // Show error
                    let errorAlert = UIAlertController(
                        title: "Export Failed",
                        message: "No \(exportTitle.lowercased()) to export or an error occurred.",
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }
    
    private func showTermsOfService() {
        guard let termsURL = Bundle.main.url(forResource: "TermsAndConditions", withExtension: "md"),
              let termsText = try? String(contentsOf: termsURL, encoding: .utf8) else {
            // Fallback to web URL if the file isn't found
            openURL("http://imagetopdfmaker.com/terms")
            return
        }
        
        let textViewController = TextDisplayViewController()
        textViewController.title = "Terms of Service"
        textViewController.displayText = termsText
        navigationController?.pushViewController(textViewController, animated: true)
    }
    
    private func showPrivacyPolicy() {
        guard let privacyURL = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "md"),
              let privacyText = try? String(contentsOf: privacyURL, encoding: .utf8) else {
            // Fallback to web URL if the file isn't found
            openURL("http://imagetopdfmaker.com/privacy")
            return
        }
        
        let textViewController = TextDisplayViewController()
        textViewController.title = "Privacy Policy"
        textViewController.displayText = privacyText
        navigationController?.pushViewController(textViewController, animated: true)
    }
}
