//
//  PDFSigner.swift
//  PhotoToPDFMaker
//

import UIKit
import PDFKit

class PDFSigner {
    private static var signCallCount = 0
    private static var currentSessionID: String = UUID().uuidString
    
    /// Signs a PDF document by rendering the page and overlaying the signature
    /// Returns a dummy annotation for tracking (signatures are flattened into the page)
    @discardableResult
    static func signDocument(_ document: PDFDocument, with signature: UIImage, in rect: CGRect, on pageIndex: Int) -> PDFAnnotation? {
        signCallCount += 1
        let callID = UUID().uuidString.prefix(8)
        
        print("🔢🔢🔢 PDFSigner: Call #\(signCallCount) [ID: \(callID)] - Session: \(currentSessionID)")
        print("   📄 Document: \(document)")
        print("   📑 Page index: \(pageIndex)")
        print("   📍 Signature rect: \(rect)")
        print("   🆔 Call stack:")
        Thread.callStackSymbols.prefix(5).forEach { print("      \($0)") }
        
        guard let page = document.page(at: pageIndex) else {
            print("❌ [\(callID)] Invalid page index \(pageIndex)")
            return nil
        }
        
        let pageBounds = page.bounds(for: .mediaBox)
        print("   📄 [\(callID)] Page bounds: \(pageBounds)")
        print("   📏 [\(callID)] Signature image size: \(signature.size)")
        
        // Clamp signature rect to page bounds
        var signatureRect = rect
        signatureRect.origin.x = max(0, min(signatureRect.origin.x, pageBounds.width - signatureRect.width))
        signatureRect.origin.y = max(0, min(signatureRect.origin.y, pageBounds.height - signatureRect.height))
        
        if signatureRect != rect {
            print("   ⚠️ [\(callID)] Clamped signature rect to: \(signatureRect)")
        }
        
        // Create a new PDF page with the signature burned in
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageBounds, nil)
        UIGraphicsBeginPDFPage()
        
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndPDFContext()
            print("❌ [\(callID)] Could not get graphics context")
            return nil
        }
        
        // STEP 1: Draw the original PDF page
        context.saveGState()
        context.translateBy(x: 0, y: pageBounds.height)
        context.scaleBy(x: 1.0, y: -1.0)
        page.draw(with: .mediaBox, to: context)
        context.restoreGState()
        
        print("   ✅ [\(callID)] Drew original page content")
        
        // STEP 2: Draw the signature on top (in UIKit coordinate space)
        signature.draw(in: signatureRect)
        print("   ✅ [\(callID)] Drew signature at \(signatureRect)")
        
        UIGraphicsEndPDFContext()
        
        // Create new PDF page from the rendered data
        guard let newPDFDocument = PDFDocument(data: pdfData as Data),
              let newPage = newPDFDocument.page(at: 0) else {
            print("❌ [\(callID)] Could not create new PDF page")
            return nil
        }
        
        // Replace the old page with the new signed page
        document.removePage(at: pageIndex)
        document.insert(newPage, at: pageIndex)
        
        print("✅✅✅ [\(callID)] Successfully signed page \(pageIndex) - Total calls in session: \(signCallCount)")
        
        // Return a dummy annotation for undo tracking
        return PDFAnnotation(bounds: signatureRect, forType: .stamp, withProperties: nil)
    }
    
    /// Removes a signature (placeholder - signatures are flattened and cannot be removed)
    static func removeAnnotation(_ annotation: PDFAnnotation, from document: PDFDocument, on pageIndex: Int) {
        print("⚠️ PDFSigner: Cannot remove flattened signature - use undo to restore original page")
    }
    
    /// Reset the call counter (for debugging)
    static func resetCallCount() {
        signCallCount = 0
        print("🔄 PDFSigner: Call count reset")
    }
}

