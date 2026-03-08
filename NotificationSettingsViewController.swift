//
//  NotificationSettingsViewController.swift
//  PhotoToPDFMaker
//

import UIKit
import UserNotifications

class NotificationSettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private var notificationsEnabled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notifications"
        view.backgroundColor = .systemGroupedBackground
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        checkNotificationStatus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh status when returning from Settings
        checkNotificationStatus()
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationsEnabled = settings.authorizationStatus == .authorized
                self?.tableView.reloadData()
            }
        }
    }
    
    // MARK: - TableView Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Notification Settings"
        case 1: return "About Notifications"
        default: return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return notificationsEnabled
                ? "Notifications are enabled. You'll receive updates about your PDF conversions."
                : "Enable notifications to receive updates when your PDF conversions are complete."
        case 1:
            return "If notifications are disabled, you can enable them in your device Settings app."
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Enable Notifications toggle
        case 1: return 1 // Open System Settings
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = "Enable Notifications"
            cell.contentConfiguration = content
            
            let switchControl = UISwitch()
            switchControl.isOn = notificationsEnabled
            switchControl.addTarget(self, action: #selector(notificationSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchControl
            cell.selectionStyle = .none
            
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = "Open System Settings"
            content.textProperties.color = .systemBlue
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            // Open system settings
            openSystemSettings()
        }
    }
    
    // MARK: - Actions
    
    @objc private func notificationSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            // Request notification permission
            requestNotificationPermission()
        } else {
            // Show alert that user needs to disable in Settings
            showDisableNotificationsAlert()
            sender.isOn = true // Revert switch since we can't disable programmatically
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    self?.notificationsEnabled = true
                    self?.tableView.reloadData()
                    self?.showSuccessAlert()
                } else {
                    self?.notificationsEnabled = false
                    self?.tableView.reloadData()
                    if error == nil {
                        // User denied permission
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
        }
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "Notifications Enabled",
            message: "You'll now receive notifications about your PDF conversions.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Permission Denied",
            message: "To enable notifications, please allow them in your device Settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { [weak self] _ in
            self?.openSystemSettings()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showDisableNotificationsAlert() {
        let alert = UIAlertController(
            title: "Disable Notifications",
            message: "To disable notifications, you need to turn them off in your device Settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { [weak self] _ in
            self?.openSystemSettings()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
