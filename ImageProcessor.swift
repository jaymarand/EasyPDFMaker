//
//  ImageProcessor.swift
//  PhotoToPDFMaker
//

import UIKit
import Vision

class ImageProcessor {
    
    /// Returns the original image without any processing
    /// Perspective correction disabled to avoid skewing issues
    static func enhanceDocument(image: UIImage, applyPerspectiveCorrection: Bool = false, completion: @escaping (UIImage?) -> Void) {
        // Always return original image - perspective correction is disabled
        completion(image)
    }
    
    /// Applies perspective transformation to correct document perspective
    private static func perspectiveCorrectedImage(from cgImage: CGImage, rectangle: VNRectangleObservation) -> UIImage? {
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        // Convert normalized coordinates to image coordinates
        let topLeft = convert(point: rectangle.topLeft, imageSize: imageSize)
        let topRight = convert(point: rectangle.topRight, imageSize: imageSize)
        let bottomLeft = convert(point: rectangle.bottomLeft, imageSize: imageSize)
        let bottomRight = convert(point: rectangle.bottomRight, imageSize: imageSize)
        

        
        // Create perspective transform
        var perspectiveTransform = matrix_float3x3()
        perspectiveTransform.columns.0 = simd_float3(Float(topLeft.x), Float(topLeft.y), 1.0)
        perspectiveTransform.columns.1 = simd_float3(Float(topRight.x), Float(topRight.y), 1.0)
        perspectiveTransform.columns.2 = simd_float3(Float(bottomLeft.x), Float(bottomLeft.y), 1.0)
        
        // Apply perspective correction using Core Image
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIPerspectiveCorrection")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
        filter.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")
        filter.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
        filter.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        let ciContext = CIContext()
        guard let correctedCGImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: correctedCGImage)
    }
    
    /// Converts normalized Vision coordinates to image coordinates
    private static func convert(point: CGPoint, imageSize: CGSize) -> CGPoint {
        return CGPoint(
            x: point.x * imageSize.width,
            y: (1 - point.y) * imageSize.height // Flip Y coordinate
        )
    }
    
    /// Calculates distance between two points
    private static func distance(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
}
