//
//  SignatureViewController.swift
//  PhotoToPDFMaker
//

import UIKit

protocol SignatureDelegate: AnyObject {
    func signatureDidFinish(with signature: UIImage)
    func signatureDidCancel()
}

class SignatureViewController: UIViewController {
    
    weak var delegate: SignatureDelegate?
    var isCreatingSignature = false // Set to true when called from Settings
    
    private let canvasView = SignatureCanvasView()
    private let thicknessSlider = UISlider()
    private let thicknessLabel = UILabel()
    private let clearButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Set initial thickness
        canvasView.lineWidth = 3.0
        thicknessSlider.value = 3.0
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = isCreatingSignature ? "Create Signature" : "Sign Document"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Cancel button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        
        // Canvas view (transparent background)
        canvasView.backgroundColor = .clear // Transparent!
        canvasView.layer.cornerRadius = 12
        canvasView.layer.borderWidth = 2
        canvasView.layer.borderColor = UIColor.systemGray4.cgColor
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)
        
        // Instructions
        let instructionLabel = UILabel()
        instructionLabel.text = "Sign above"
        instructionLabel.font = .systemFont(ofSize: 15, weight: .regular)
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.textAlignment = .center
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        // Thickness label
        thicknessLabel.text = "Line Thickness"
        thicknessLabel.font = .systemFont(ofSize: 15, weight: .medium)
        thicknessLabel.textColor = .label
        thicknessLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(thicknessLabel)
        
        // Thickness slider
        thicknessSlider.minimumValue = 1.0
        thicknessSlider.maximumValue = 8.0
        thicknessSlider.value = 3.0
        thicknessSlider.addTarget(self, action: #selector(thicknessChanged), for: .valueChanged)
        thicknessSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(thicknessSlider)
        
        // Button stack
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        clearButton.setTitle("Clear", for: .normal)
        clearButton.backgroundColor = .secondarySystemBackground
        clearButton.layer.cornerRadius = 12
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        doneButton.backgroundColor = .systemBlue
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.layer.cornerRadius = 12
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        
        buttonStack.addArrangedSubview(clearButton)
        buttonStack.addArrangedSubview(doneButton)
        view.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cancelButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            canvasView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            canvasView.heightAnchor.constraint(equalToConstant: 200),
            
            instructionLabel.topAnchor.constraint(equalTo: canvasView.bottomAnchor, constant: 12),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            thicknessLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 24),
            thicknessLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            
            thicknessSlider.topAnchor.constraint(equalTo: thicknessLabel.bottomAnchor, constant: 8),
            thicknessSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            thicknessSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            buttonStack.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func thicknessChanged() {
        canvasView.lineWidth = CGFloat(thicknessSlider.value)
    }
    
    @objc private func clearTapped() {
        canvasView.clear()
    }
    
    @objc private func doneTapped() {
        guard !canvasView.isEmpty else {
            let alert = UIAlertController(title: "No Signature", message: "Please draw your signature before continuing.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let signature = canvasView.getSignature()
        
        // If creating signature from settings, save it
        if isCreatingSignature {
            SignatureStore.shared.saveSignature(signature)
            dismiss(animated: true) {
                // Show success message
                if let presentingVC = self.presentingViewController {
                    let alert = UIAlertController(title: "Signature Saved", message: "Your signature has been saved and will be used for signing documents.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    presentingVC.present(alert, animated: true)
                }
            }
        } else {
            dismiss(animated: true) {
                self.delegate?.signatureDidFinish(with: signature)
            }
        }
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true) {
            self.delegate?.signatureDidCancel()
        }
    }
}

// MARK: - SignatureCanvasView

class SignatureCanvasView: UIView {
    
    private var path = UIBezierPath()
    private var previousPoint: CGPoint?
    var isEmpty = true
    var lineWidth: CGFloat = 3.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestureRecognizers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let currentPoint = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            path.move(to: currentPoint)
            previousPoint = currentPoint
            isEmpty = false
            
        case .changed:
            if previousPoint != nil {
                path.addLine(to: currentPoint)
                setNeedsDisplay()
            }
            previousPoint = currentPoint
            
        case .ended, .cancelled:
            previousPoint = nil
            
        default:
            break
        }
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.black.setStroke()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }
    
    func clear() {
        path = UIBezierPath()
        isEmpty = true
        setNeedsDisplay()
    }
    
    func getSignature() -> UIImage {
        // Create image with TRULY transparent background using explicit format
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false // Ensure transparency
        
        let renderer = UIGraphicsImageRenderer(size: bounds.size, format: format)
        let image = renderer.image { context in
            // Clear the background to transparent
            context.cgContext.clear(CGRect(origin: .zero, size: bounds.size))
            
            // Draw only the signature path (no background)
            UIColor.black.setStroke()
            path.lineWidth = lineWidth
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
        }
        return image
    }
}
