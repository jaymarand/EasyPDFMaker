//
//  ScanCoordinator.swift
//  PhotoToPDFMaker
//

import UIKit
import VisionKit
import Vision
import CoreImage

protocol ScanCoordinatorDelegate: AnyObject {
    func scanCoordinatorDidFinish(with images: [UIImage])
    func scanCoordinatorDidCancel()
}

class ScanCoordinator: NSObject, VNDocumentCameraViewControllerDelegate {
    
    weak var delegate: ScanCoordinatorDelegate?
    private weak var presentingViewController: UIViewController?
    
    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }
    
    func start() {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        presentingViewController?.present(scannerViewController, animated: true)
    }
    
    // MARK: - VNDocumentCameraViewControllerDelegate
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        var images: [UIImage] = []
        
        print("📸 ScanCoordinator: Processing \(scan.pageCount) scanned pages")
        
        // Collect all scanned pages and process them
        for i in 0..<scan.pageCount {
            let scannedImage = scan.imageOfPage(at: i)
            
            // Apply document enhancement: edge detection + black & white conversion
            if let processedImage = processScannedDocument(scannedImage) {
                print("✅ Page \(i+1): Processed with edge detection and B&W conversion")
                images.append(processedImage)
            } else {
                print("⚠️ Page \(i+1): Processing failed, using original")
                images.append(scannedImage)
            }
        }
        
        controller.dismiss(animated: true) {
            self.delegate?.scanCoordinatorDidFinish(with: images)
        }
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true) {
            self.delegate?.scanCoordinatorDidCancel()
        }
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true) {
            self.delegate?.scanCoordinatorDidCancel()
        }
    }
    
    // MARK: - Document Processing
    
    private func processScannedDocument(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else {
            print("❌ Could not create CIImage from scanned image")
            return nil
        }
        
        let context = CIContext()
        var processedImage = ciImage
        
        // STEP 1: Convert to black and white FIRST (for speed and better edge detection)
        print("🎨 Converting to black and white...")
        if let bwImage = convertToBlackAndWhite(ciImage) {
            print("✅ Converted to black and white")
            processedImage = bwImage
        } else {
            print("⚠️ B&W conversion failed, continuing with original")
        }
        
        // STEP 2: Detect document edges and apply perspective correction on B&W image
        print("📐 Detecting edges and correcting perspective...")
        if let correctedImage = detectAndCorrectPerspective(processedImage) {
            print("✅ Applied perspective correction")
            processedImage = correctedImage
        } else {
            print("⚠️ No perspective correction applied, using B&W image")
        }
        
        // STEP 3: Clean up edges (crop any remaining borders)
        print("✂️ Cleaning up edges...")
        if let cleanedImage = cleanupEdges(processedImage) {
            print("✅ Edges cleaned")
            processedImage = cleanedImage
        }
        
        // STEP 4: Convert back to UIImage
        guard let cgImage = context.createCGImage(processedImage, from: processedImage.extent) else {
            print("❌ Could not create CGImage from processed image")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func detectAndCorrectPerspective(_ image: CIImage) -> CIImage? {
        // Use Vision to detect document rectangle
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.3
        request.minimumConfidence = 0.6
        
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("⚠️ Rectangle detection failed: \(error)")
            return nil
        }
        
        guard let observation = request.results?.first else {
            print("⚠️ No rectangle detected")
            return nil
        }
        
        print("📐 Rectangle detected with confidence: \(observation.confidence)")
        
        // Apply perspective correction
        return applyPerspectiveCorrection(to: image, using: observation)
    }
    
    private func applyPerspectiveCorrection(to image: CIImage, using rectangle: VNRectangleObservation) -> CIImage? {
        let imageSize = image.extent.size
        
        // Convert normalized coordinates to image coordinates
        let topLeft = convertPoint(rectangle.topLeft, imageSize: imageSize)
        let topRight = convertPoint(rectangle.topRight, imageSize: imageSize)
        let bottomLeft = convertPoint(rectangle.bottomLeft, imageSize: imageSize)
        let bottomRight = convertPoint(rectangle.bottomRight, imageSize: imageSize)
        
        // Apply perspective correction filter
        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            print("❌ Perspective correction filter not available")
            return nil
        }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
        filter.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")
        
        return filter.outputImage
    }
    
    private func convertPoint(_ point: CGPoint, imageSize: CGSize) -> CGPoint {
        return CGPoint(
            x: point.x * imageSize.width,
            y: (1 - point.y) * imageSize.height // Flip Y coordinate
        )
    }
    
    private func convertToBlackAndWhite(_ image: CIImage) -> CIImage? {
        // Create a high-contrast black and white image suitable for documents
        // This is optimized for SPEED as requested
        
        // Fast grayscale conversion
        guard let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono") else {
            print("❌ Grayscale filter not available")
            return nil
        }
        grayscaleFilter.setValue(image, forKey: kCIInputImageKey)
        guard let grayscaleImage = grayscaleFilter.outputImage else {
            return nil
        }
        
        // Increase contrast for sharper text
        guard let contrastFilter = CIFilter(name: "CIColorControls") else {
            return grayscaleImage
        }
        contrastFilter.setValue(grayscaleImage, forKey: kCIInputImageKey)
        contrastFilter.setValue(1.5, forKey: kCIInputContrastKey) // High contrast
        contrastFilter.setValue(0.1, forKey: kCIInputBrightnessKey) // Slight brightness boost
        
        guard let contrastedImage = contrastFilter.outputImage else {
            return grayscaleImage
        }
        
        // Quick exposure adjustment
        guard let exposureFilter = CIFilter(name: "CIExposureAdjust") else {
            return contrastedImage
        }
        exposureFilter.setValue(contrastedImage, forKey: kCIInputImageKey)
        exposureFilter.setValue(0.3, forKey: kCIInputEVKey)
        
        return exposureFilter.outputImage ?? contrastedImage
    }
    
    private func cleanupEdges(_ image: CIImage) -> CIImage? {
        // Crop any white/light borders around the document
        let extent = image.extent
        
        // Apply a slight crop (2% from each edge) to remove scanner artifacts
        let cropAmount = min(extent.width, extent.height) * 0.02
        let croppedRect = extent.insetBy(dx: cropAmount, dy: cropAmount)
        
        // Ensure the rect is valid
        if croppedRect.width > 0 && croppedRect.height > 0 {
            return image.cropped(to: croppedRect)
        }
        
        return image
    }
}
