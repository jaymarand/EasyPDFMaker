//
//  SignatureEditableOverlayView.swift
//  PhotoToPDFMaker
//

import UIKit

protocol SignatureEditableDelegate: AnyObject {
    func didConfirmSignaturePlacement(rect: CGRect, in view: UIView)
    func didCancelSignaturePlacement()
}

class SignatureEditableOverlayView: UIView {
    
    weak var delegate: SignatureEditableDelegate?
    
    private let signatureImageView = UIImageView()
    private let containerView = UIView()
    private let topLeftHandle = UIView()
    private let topRightHandle = UIView()
    private let bottomLeftHandle = UIView()
    private let bottomRightHandle = UIView()
    private let doneButton = UIButton(type: .system)
    
    private var currentHandle: UIView?
    private var startBounds: CGRect = .zero
    private var startPoint: CGPoint = .zero
    private var isApplying = false // Prevent double-tap
    
    init(signatureImage: UIImage, initialRect: CGRect) {
        super.init(frame: .zero)
        setupUI(signatureImage: signatureImage, initialRect: initialRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(signatureImage: UIImage, initialRect: CGRect) {
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        // Container view for signature + handles
        containerView.frame = initialRect
        addSubview(containerView)
        
        // Signature image view
        signatureImageView.image = signatureImage
        signatureImageView.contentMode = .scaleAspectFit
        signatureImageView.frame = containerView.bounds
        signatureImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(signatureImageView)
        
        // Border
        containerView.layer.borderColor = UIColor.systemBlue.cgColor
        containerView.layer.borderWidth = 2
        
        // Add pan gesture to move
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        containerView.addGestureRecognizer(panGesture)
        
        // Add resize handles
        let handleSize: CGFloat = 20  // Reduced from 30 to 20
        setupHandle(topLeftHandle, size: handleSize)
        setupHandle(topRightHandle, size: handleSize)
        setupHandle(bottomLeftHandle, size: handleSize)
        setupHandle(bottomRightHandle, size: handleSize)
        
        // Done button
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        doneButton.backgroundColor = .systemBlue
        doneButton.setTitleColor(.white, for: .normal)
        doneButton.layer.cornerRadius = 12
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(doneButton)
        
        NSLayoutConstraint.activate([
            doneButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -20),
            doneButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            doneButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            doneButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        updateHandlePositions()
    }
    
    private func setupHandle(_ handle: UIView, size: CGFloat) {
        handle.backgroundColor = .white
        handle.layer.borderColor = UIColor.systemBlue.cgColor
        handle.layer.borderWidth = 3  // Thicker border for visibility
        handle.layer.cornerRadius = size / 2
        handle.frame.size = CGSize(width: size, height: size)
        
        // Add shadow for better visibility
        handle.layer.shadowColor = UIColor.black.cgColor
        handle.layer.shadowOffset = CGSize(width: 0, height: 2)
        handle.layer.shadowOpacity = 0.3
        handle.layer.shadowRadius = 4
        
        // Make handles more visible
        handle.isUserInteractionEnabled = true
        handle.clipsToBounds = false  // Allow shadow to show
        
        addSubview(handle)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleResize))
        handle.addGestureRecognizer(panGesture)
        
        print("✅ Created handle with size: \(size)")
    }
    
    private func updateHandlePositions() {
        let frame = containerView.frame
        let handleSize = topLeftHandle.frame.width
        let offset = handleSize / 2
        
        topLeftHandle.center = CGPoint(x: frame.minX - offset, y: frame.minY - offset)
        topRightHandle.center = CGPoint(x: frame.maxX + offset, y: frame.minY - offset)
        bottomLeftHandle.center = CGPoint(x: frame.minX - offset, y: frame.maxY + offset)
        bottomRightHandle.center = CGPoint(x: frame.maxX + offset, y: frame.maxY + offset)
        
        print("📍 Updated handle positions:")
        print("   Container frame: \(frame)")
        print("   TopLeft: \(topLeftHandle.center)")
        print("   TopRight: \(topRightHandle.center)")
        print("   BottomLeft: \(bottomLeftHandle.center)")
        print("   BottomRight: \(bottomRightHandle.center)")
        
        // Bring handles to front so they're always visible
        bringSubviewToFront(topLeftHandle)
        bringSubviewToFront(topRightHandle)
        bringSubviewToFront(bottomLeftHandle)
        bringSubviewToFront(bottomRightHandle)
        bringSubviewToFront(doneButton)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        if gesture.state == .began {
            startBounds = containerView.frame
        }
        
        var newFrame = startBounds
        newFrame.origin.x += translation.x
        newFrame.origin.y += translation.y
        
        containerView.frame = newFrame
        updateHandlePositions()
    }
    
    @objc private func handleResize(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        
        if gesture.state == .began {
            currentHandle = gesture.view
            startBounds = containerView.frame
            startPoint = location
        }
        
        guard let handle = currentHandle else { return }
        
        var newFrame = containerView.frame
        let minSize: CGFloat = 80
        
        // Resize based on which handle is being dragged
        if handle == bottomRightHandle {
            newFrame.size.width = max(minSize, startBounds.width + (location.x - startPoint.x))
            newFrame.size.height = max(minSize, startBounds.height + (location.y - startPoint.y))
        } else if handle == topLeftHandle {
            let deltaX = location.x - startPoint.x
            let deltaY = location.y - startPoint.y
            newFrame.origin.x = startBounds.origin.x + deltaX
            newFrame.origin.y = startBounds.origin.y + deltaY
            newFrame.size.width = max(minSize, startBounds.width - deltaX)
            newFrame.size.height = max(minSize, startBounds.height - deltaY)
        } else if handle == topRightHandle {
            let deltaY = location.y - startPoint.y
            newFrame.origin.y = startBounds.origin.y + deltaY
            newFrame.size.width = max(minSize, startBounds.width + (location.x - startPoint.x))
            newFrame.size.height = max(minSize, startBounds.height - deltaY)
        } else if handle == bottomLeftHandle {
            let deltaX = location.x - startPoint.x
            newFrame.origin.x = startBounds.origin.x + deltaX
            newFrame.size.width = max(minSize, startBounds.width - deltaX)
            newFrame.size.height = max(minSize, startBounds.height + (location.y - startPoint.y))
        }
        
        containerView.frame = newFrame
        updateHandlePositions()
        
        if gesture.state == .ended {
            currentHandle = nil
        }
    }
    
    @objc private func doneTapped() {
        // Prevent double-tapping
        guard !isApplying else {
            print("⚠️ SignatureEditableOverlay: Already applying signature, ignoring duplicate tap")
            return
        }
        
        isApplying = true
        doneButton.isEnabled = false
        
        print("✅ SignatureEditableOverlay: Done tapped - applying signature at: \(containerView.frame)")
        print("   Delegate is set: \(delegate != nil)")
        delegate?.didConfirmSignaturePlacement(rect: containerView.frame, in: self)
        
        print("🗑️ SignatureEditableOverlay: Removing overlay from superview")
        removeFromSuperview()
    }
}
