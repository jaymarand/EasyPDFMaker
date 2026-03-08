//
//  PDFNormalizer.swift
//  PhotoToPDFMaker
//

import UIKit

class PDFNormalizer {
    static func normalize(image: UIImage, to width: CGFloat = 800) -> UIImage {
        let scale = width / image.size.width
        let height = image.size.height * scale
        let size = CGSize(width: width, height: height)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
