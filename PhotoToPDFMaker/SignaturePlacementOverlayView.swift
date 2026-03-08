//
//  SignaturePlacementOverlayView.swift
//  PhotoToPDFMaker
//

import UIKit

protocol SignaturePlacementDelegate: AnyObject {
    func didApplySignature(rect: CGRect)
    func didCancelPlacement()
}

class SignaturePlacementOverlayView: UIView {
    
    weak var delegate: SignaturePlacementDelegate?
    
    private let signatureImageView = UIImageView()
    private let applyButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    private var initialCenter: CGPoint = .zero
    private var initialBounds: CGRect = .zero
    private var isApplying = false // Prevent double-tap

    init(signatureImage: UIImage?, bounds: CGRect) {
        super.init(frame: bounds)
        setupUI(signatureImage: signatureImage)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(signatureImage: UIImage?) {
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        isUserInteractionEnabled = true
        
        signatureImageView.image = signatureImage
        signatureImageView.contentMode = .scaleAspectFit
        signatureImageView.isUserInteractionEnabled = true
        
        // Add visible border and background so users can see the draggable area
        signatureImageView.layer.borderColor = UIColor.systemBlue.cgColor
        signatureImageView.layer.borderWidth = 3
        signatureImageView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        signatureImageView.layer.cornerRadius = 8
        
        // Default size based on image aspect ratio
        let defaultWidth: CGFloat = 250
        let aspect = (signatureImage?.size.width ?? 1) / (signatureImage?.size.height ?? 1)
        let defaultHeight = defaultWidth / aspect
        signatureImageView.frame = CGRect(
            x: bounds.midX - defaultWidth/2,
            y: bounds.midY - defaultHeight/2,
            width: defaultWidth,
            height: defaultHeight
        )
        addSubview(signatureImageView)
        
        // Add gesture recognizers
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        signatureImageView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        signatureImageView.addGestureRecognizer(pinchGesture)
        
        // Allow both gestures to work simultaneously
        panGesture.delegate = self
        pinchGesture.delegate = self
        
        print("✅ Signature image view setup complete")
        print("   Frame: \(signatureImageView.frame)")
        print("   User interaction enabled: \(signatureImageView.isUserInteractionEnabled)")
        
        // Add Apply/Cancel buttons at the bottom
        let bottomView = UIView()
        bottomView.backgroundColor = .systemBackground
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomView)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(cancelButton)
        
        applyButton.setTitle("Apply Signature", for: .normal)
        applyButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        applyButton.backgroundColor = .systemBlue
        applyButton.setTitleColor(.white, for: .normal)
        applyButton.layer.cornerRadius = 12
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(applyButton)
        
        NSLayoutConstraint.activate([
            bottomView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomView.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomView.heightAnchor.constraint(equalToConstant: 120),
            
            cancelButton.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 20),
            cancelButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor, constant: -20),
            
            applyButton.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -20),
            applyButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor, constant: -20),
            applyButton.widthAnchor.constraint(equalToConstant: 180),
            applyButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let translation = gesture.translation(in: self)
        
        if gesture.state == .began {
            initialCenter = view.center
            print("🖐️ Started dragging signature")
        } else if gesture.state == .changed {
            view.center = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
        } else if gesture.state == .ended {
            print("✅ Finished dragging - new position: \(view.center)")
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        if gesture.state == .began {
            initialBounds = view.bounds
            print("🤏 Started pinching signature")
        } else if gesture.state == .changed {
            let scale = gesture.scale
            view.bounds = CGRect(x: 0, y: 0, width: initialBounds.width * scale, height: initialBounds.height * scale)
        } else if gesture.state == .ended {
            print("✅ Finished pinching - new size: \(view.bounds.size)")
        }
    }
    
    @objc private func cancelTapped() {
        print("❌ Signature placement cancelled")
        delegate?.didCancelPlacement()
        removeFromSuperview()
    }
    
    @objc private func applyTapped() {
        // Prevent double-tapping
        guard !isApplying else {
            print("⚠️ Already applying signature, ignoring duplicate tap")
            return
        }
        
        isApplying = true
        applyButton.isEnabled = false
        cancelButton.isEnabled = false
        
        print("✅ Applying signature at frame: \(signatureImageView.frame)")
        delegate?.didApplySignature(rect: signatureImageView.frame)
        removeFromSuperview()
    }
}
// MARK: - UIGestureRecognizerDelegate
extension SignaturePlacementOverlayView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow pan and pinch to work at the same time
        return true
    }
}

