//
//  MainTabBarController.swift
//  PhotoToPDFMaker
//

import UIKit

class MainTabBarController: UITabBarController, ScanCoordinatorDelegate, PageSelectionDelegate {

    private var scanCoordinator: ScanCoordinator?
    private var centerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("MainTabBarController viewDidLoad called")
        
        setupViewControllers()
        setupTabBar()
        setupCenterButton()
        
        print("MainTabBarController setup complete with \(viewControllers?.count ?? 0) tabs")
    }
    
    private func setupViewControllers() {
        // 1. Home
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        
        // 2. Documents/History
        let historyVC = HistoryViewController()
        let historyNav = UINavigationController(rootViewController: historyVC)
        historyNav.tabBarItem = UITabBarItem(title: "History", image: UIImage(systemName: "clock"), selectedImage: UIImage(systemName: "clock.fill"))
        
        // 3. Scan (placeholder - handled by center button)
        let scanPlaceholder = UIViewController()
        scanPlaceholder.tabBarItem = UITabBarItem(title: "", image: nil, tag: 2)
        scanPlaceholder.tabBarItem.isEnabled = false
        
        // 4. Favorites
        let favoritesVC = FavoritesViewController()
        let favoritesNav = UINavigationController(rootViewController: favoritesVC)
        favoritesNav.tabBarItem = UITabBarItem(title: "Favorites", image: UIImage(systemName: "star"), selectedImage: UIImage(systemName: "star.fill"))
        
        // 5. Settings
        let settingsVC = SettingsViewController()
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), selectedImage: UIImage(systemName: "gear"))
        
        viewControllers = [homeNav, historyNav, scanPlaceholder, favoritesNav, settingsNav]
    }
    
    private func setupTabBar() {
        tabBar.tintColor = .systemBlue
        tabBar.backgroundColor = .systemBackground
        tabBar.isTranslucent = false
        
        // Add subtle shadow
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.1
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        tabBar.layer.shadowRadius = 8
    }
    
    private func setupCenterButton() {
        // Create container for the raised button
        centerButton = UIButton(type: .custom)
        centerButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Calculate size - 10% bigger than current (84pt * 1.1 = 92.4pt)
        let buttonSize: CGFloat = 92
        let innerCircleSize: CGFloat = 68  // Proportionally scaled
        let iconSize: CGFloat = 40  // Proportionally scaled
        
        // Create gradient background
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.3).cgColor,
            UIColor.systemBlue.withAlphaComponent(0.1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
        gradientLayer.cornerRadius = buttonSize / 2
        
        // Create inner blue circle
        let innerCircle = UIView()
        innerCircle.backgroundColor = .systemBlue
        innerCircle.layer.cornerRadius = innerCircleSize / 2
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.isUserInteractionEnabled = false
        
        // Add gradient layer to button
        let gradientView = UIView(frame: CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
        gradientView.layer.addSublayer(gradientLayer)
        gradientView.isUserInteractionEnabled = false
        centerButton.addSubview(gradientView)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        
        centerButton.addSubview(innerCircle)
        
        // Camera icon
        let cameraIcon = UIImageView(image: UIImage(systemName: "camera.fill"))
        cameraIcon.tintColor = .white
        cameraIcon.contentMode = .scaleAspectFit
        cameraIcon.translatesAutoresizingMaskIntoConstraints = false
        cameraIcon.isUserInteractionEnabled = false
        innerCircle.addSubview(cameraIcon)
        
        // Add shadow
        centerButton.layer.shadowColor = UIColor.systemBlue.cgColor
        centerButton.layer.shadowOpacity = 0.3
        centerButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        centerButton.layer.shadowRadius = 8
        
        centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
        
        // Add to view hierarchy
        view.addSubview(centerButton)
        
        NSLayoutConstraint.activate([
            centerButton.widthAnchor.constraint(equalToConstant: buttonSize),
            centerButton.heightAnchor.constraint(equalToConstant: buttonSize),
            centerButton.centerXAnchor.constraint(equalTo: tabBar.centerXAnchor),
            centerButton.centerYAnchor.constraint(equalTo: tabBar.topAnchor, constant: -2),  // Lowered by 15% (closer to tab bar)
            
            gradientView.widthAnchor.constraint(equalToConstant: buttonSize),
            gradientView.heightAnchor.constraint(equalToConstant: buttonSize),
            gradientView.centerXAnchor.constraint(equalTo: centerButton.centerXAnchor),
            gradientView.centerYAnchor.constraint(equalTo: centerButton.centerYAnchor),
            
            innerCircle.widthAnchor.constraint(equalToConstant: innerCircleSize),
            innerCircle.heightAnchor.constraint(equalToConstant: innerCircleSize),
            innerCircle.centerXAnchor.constraint(equalTo: centerButton.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: centerButton.centerYAnchor),
            
            cameraIcon.widthAnchor.constraint(equalToConstant: iconSize),
            cameraIcon.heightAnchor.constraint(equalToConstant: iconSize),
            cameraIcon.centerXAnchor.constraint(equalTo: innerCircle.centerXAnchor),
            cameraIcon.centerYAnchor.constraint(equalTo: innerCircle.centerYAnchor)
        ])
    }
    
    @objc private func centerButtonTapped() {
        print("Center scan button tapped")
        
        // Animate button press
        UIView.animate(withDuration: 0.1, animations: {
            self.centerButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.centerButton.transform = .identity
            }
        }
        
        // Start scan coordinator
        scanCoordinator = ScanCoordinator(presentingViewController: self)
        scanCoordinator?.delegate = self
        scanCoordinator?.start()
    }
    
    // MARK: - ScanCoordinatorDelegate
    
    func scanCoordinatorDidFinish(with images: [UIImage]) {
        // Get the currently selected nav controller
        guard let navController = selectedViewController as? UINavigationController else { return }
        
        // If only one image, skip selection
        if images.count == 1 {
            let actionVC = DocumentActionViewController(image: images[0])
            let actionNav = UINavigationController(rootViewController: actionVC)
            actionNav.modalPresentationStyle = .fullScreen
            navController.present(actionNav, animated: true)
        } else {
            // Show page selection for multiple images
            let selectionVC = PageSelectionViewController(images: images)
            selectionVC.delegate = self
            selectionVC.modalPresentationStyle = .fullScreen
            navController.present(selectionVC, animated: true)
        }
    }
    
    func scanCoordinatorDidCancel() {
        print("Scan cancelled")
    }
    
    // MARK: - PageSelectionDelegate
    
    func pageSelectionDidSelect(images: [UIImage]) {
        guard let navController = selectedViewController as? UINavigationController,
              let firstImage = images.first else {
            return
        }
        
        let remainingImages = Array(images.dropFirst())
        let actionVC = DocumentActionViewController(image: firstImage, additionalImages: remainingImages)
        let actionNav = UINavigationController(rootViewController: actionVC)
        actionNav.modalPresentationStyle = .fullScreen
        navController.present(actionNav, animated: true)
    }
    
    func pageSelectionDidCancel() {
        // No-op
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure center button stays on top
        if let centerButton = centerButton {
            view.bringSubviewToFront(centerButton)
        }
    }
}
