//
//  OnboardingViewController.swift
//  PhotoToPDFMaker
//

import UIKit

class OnboardingViewController: UIViewController, UIScrollViewDelegate {
    
    private let scrollView = UIScrollView()
    private let pageControl = UIPageControl()
    private let continueButton = UIButton(type: .system)
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(title: "Scan documents in seconds", body: "Capture single or multi-page documents and convert them into clean PDFs instantly.", imageName: "doc.viewfinder"),
        OnboardingPage(title: "Automatic edge detection", body: "Smart cropping and perspective correction for professional results.", imageName: "crop"),
        OnboardingPage(title: "Edit and sign any document", body: "Add your signature quickly and keep work moving.", imageName: "signature"),
        OnboardingPage(title: "Share and extract text instantly", body: "Export anywhere and copy text using built-in OCR recognition.", imageName: "text.viewfinder")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        pageControl.numberOfPages = pages.count
        pageControl.currentPageIndicatorTintColor = .systemBlue
        pageControl.pageIndicatorTintColor = .systemGray4
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)
        
        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        continueButton.backgroundColor = .systemBlue
        continueButton.setTitleColor(.white, for: .normal)
        continueButton.layer.cornerRadius = 12
        continueButton.isHidden = true
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            pageControl.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -20),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        setupPages()
    }
    
    private func setupPages() {
        var previousView: UIView? = nil
        
        for (index, page) in pages.enumerated() {
            let pageView = OnboardingPageView(page: page)
            pageView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(pageView)
            
            NSLayoutConstraint.activate([
                pageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
                pageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                pageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                pageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
            ])
            
            if let previous = previousView {
                pageView.leadingAnchor.constraint(equalTo: previous.trailingAnchor).isActive = true
            } else {
                pageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor).isActive = true
            }
            
            if index == pages.count - 1 {
                pageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
            }
            
            previousView = pageView
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x / view.frame.width)
        pageControl.currentPage = Int(pageIndex)
        
        let isLastPage = pageControl.currentPage == pages.count - 1
        continueButton.isHidden = !isLastPage
    }
    
    @objc private func continueTapped() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        
        // Get the window and set the root view controller directly
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let mainTabBar = MainTabBarController()
            window.rootViewController = mainTabBar
            
            // Add a smooth transition animation
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {}, completion: nil)
        }
    }
}
