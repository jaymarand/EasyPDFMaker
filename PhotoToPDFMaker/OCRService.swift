//
//  OCRService.swift
//  PhotoToPDFMaker
//

import UIKit
import Vision
import PDFKit

class OCRService {
    
    /// Extracts text from an image using Vision framework
    static func extractText(from image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil,
                  let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Combine all recognized text
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            DispatchQueue.main.async {
                completion(recognizedText.isEmpty ? nil : recognizedText)
            }
        }
        
        // Configure for accurate text recognition
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Perform OCR request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    /// Extracts text from PDF document (for existing PDFs)
    static func extractTextFromPDF(_ pdfDocument: PDFDocument, progress: @escaping (Float) -> Void, completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let pageCount = pdfDocument.pageCount
            var extractedText = ""
            
            for i in 0..<pageCount {
                guard let page = pdfDocument.page(at: i) else { continue }
                let mediaBox = page.bounds(for: .mediaBox)
                let renderer = UIGraphicsImageRenderer(size: mediaBox.size)
                let image = renderer.image { ctx in
                    UIColor.white.set()
                    ctx.fill(mediaBox)
                    ctx.cgContext.saveGState()
                    ctx.cgContext.translateBy(x: 0, y: mediaBox.height)
                    ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                    ctx.cgContext.restoreGState()
                }
                
                guard let cgImage = image.cgImage else { continue }
                
                let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                let request = VNRecognizeTextRequest { request, error in
                    guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else { return }
                    let recognizedStrings = observations.compactMap { $0.topCandidates(1).first?.string }
                    let pageText = recognizedStrings.joined(separator: "\n")
                    extractedText += pageText + "\n\n"
                }
                request.recognitionLevel = .accurate
                
                do {
                    try requestHandler.perform([request])
                } catch {
                    print("OCR error: \(error)")
                }
                
                DispatchQueue.main.async {
                    progress(Float(i + 1) / Float(pageCount))
                }
            }
            
            DispatchQueue.main.async {
                completion(extractedText.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
    }
}
