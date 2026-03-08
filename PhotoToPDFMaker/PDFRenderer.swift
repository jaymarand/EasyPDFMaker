//
//  PDFRenderer.swift
//  PhotoToPDFMaker
//

import UIKit
import PDFKit

class PDFRenderer {
    static func createPDF(from images: [UIImage], completion: @escaping (Data?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let pdfData = NSMutableData()
            
            UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, nil)
            
            for image in images {
                let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
                UIGraphicsBeginPDFPageWithInfo(rect, nil)
                image.draw(in: rect)
            }
            
            UIGraphicsEndPDFContext()
            
            DispatchQueue.main.async {
                completion(pdfData as Data)
            }
        }
    }
    
    /// Creates a PDF with text overlaid on the image (searchable PDF)
    static func createSearchablePDF(from image: UIImage, text: String, completion: @escaping (Data?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let pdfData = NSMutableData()
            let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            
            UIGraphicsBeginPDFContextToData(pdfData, rect, nil)
            UIGraphicsBeginPDFPageWithInfo(rect, nil)
            
            // Draw the image first
            image.draw(in: rect)
            
            // Overlay invisible text for searchability
            // The text is rendered very small and transparent
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 1),
                .foregroundColor: UIColor.clear
            ]
            
            let attributedText = NSAttributedString(string: text, attributes: textAttributes)
            attributedText.draw(at: CGPoint(x: 0, y: 0))
            
            UIGraphicsEndPDFContext()
            
            DispatchQueue.main.async {
                completion(pdfData as Data)
            }
        }
    }
}
