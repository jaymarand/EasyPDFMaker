//
//  ImportCoordinator.swift
//  PhotoToPDFMaker
//

import UIKit
import PhotosUI
import UniformTypeIdentifiers

protocol ImportCoordinatorDelegate: AnyObject {
    func importCoordinatorDidFinishWithImages(_ images: [UIImage])
    func importCoordinatorDidFinishWithPDF(_ url: URL)
    func importCoordinatorDidCancel()
}

class ImportCoordinator: NSObject, PHPickerViewControllerDelegate, UIDocumentPickerDelegate {
    
    weak var delegate: ImportCoordinatorDelegate?
    private weak var presentingViewController: UIViewController?
    
    init(presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
    }
    
    func startImageImport() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0 // unlimited
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        presentingViewController?.present(picker, animated: true)
    }
    
    func startFileImport() {
        // Allow both PDFs and images from Files app, iCloud Drive, Downloads, etc.
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .png, .jpeg, .heic, .image])
        picker.delegate = self
        picker.allowsMultipleSelection = true // Allow selecting multiple files
        picker.shouldShowFileExtensions = true
        presentingViewController?.present(picker, animated: true)
    }
    
    // MARK: - PHPickerViewControllerDelegate
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        if results.isEmpty {
            delegate?.importCoordinatorDidCancel()
            return
        }
        
        var images: [UIImage?] = Array(repeating: nil, count: results.count)
        let group = DispatchGroup()
        
        for (index, result) in results.enumerated() {
            group.enter()
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    images[index] = image
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            let validImages = images.compactMap { $0 }
            if validImages.isEmpty {
                self.delegate?.importCoordinatorDidCancel()
            } else {
                self.delegate?.importCoordinatorDidFinishWithImages(validImages)
            }
        }
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard !urls.isEmpty else {
            delegate?.importCoordinatorDidCancel()
            return
        }
        
        // Separate PDFs from images
        var pdfURLs: [URL] = []
        var imageURLs: [URL] = []
        
        for url in urls {
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else { continue }
            defer { url.stopAccessingSecurityScopedResource() }
            
            let fileExtension = url.pathExtension.lowercased()
            
            if fileExtension == "pdf" {
                pdfURLs.append(url)
            } else if ["jpg", "jpeg", "png", "heic", "heif"].contains(fileExtension) {
                imageURLs.append(url)
            }
        }
        
        // Process PDFs first (if any)
        if let firstPDF = pdfURLs.first {
            delegate?.importCoordinatorDidFinishWithPDF(firstPDF)
            return
        }
        
        // Process images if no PDFs
        if !imageURLs.isEmpty {
            loadImages(from: imageURLs)
            return
        }
        
        delegate?.importCoordinatorDidCancel()
    }
    
    private func loadImages(from urls: [URL]) {
        print("🔵 ImportCoordinator: Loading images from \(urls.count) URLs")
        var images: [UIImage] = []
        
        for url in urls {
            guard url.startAccessingSecurityScopedResource() else {
                print("⚠️ Could not access: \(url.lastPathComponent)")
                continue
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                print("✅ Loaded image: \(url.lastPathComponent)")
                images.append(image)
            }
        }
        
        print("🔵 ImportCoordinator: Loaded \(images.count) images total")
        
        if images.isEmpty {
            print("🔵 ImportCoordinator: No images - calling didCancel")
            delegate?.importCoordinatorDidCancel()
        } else {
            print("🔵 ImportCoordinator: Calling didFinishWithImages with \(images.count) images")
            delegate?.importCoordinatorDidFinishWithImages(images)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        delegate?.importCoordinatorDidCancel()
    }
}
