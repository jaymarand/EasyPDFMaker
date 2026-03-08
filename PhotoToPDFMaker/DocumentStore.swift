//
//  DocumentStore.swift
//  PhotoToPDFMaker
//

import Foundation

class DocumentStore {
    static let shared = DocumentStore()
    
    private let fileManager = FileManager.default
    private let scansDirectory: URL
    private let indexURL: URL
    
    private var documents: [DocumentItem] = []
    
    private init() {
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        scansDirectory = docsDir.appendingPathComponent("Scans", isDirectory: true)
        indexURL = scansDirectory.appendingPathComponent("index.json")
        
        setupDirectory()
        loadIndex()
    }
    
    private func setupDirectory() {
        if !fileManager.fileExists(atPath: scansDirectory.path) {
            try? fileManager.createDirectory(at: scansDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    private func loadIndex() {
        guard let data = try? Data(contentsOf: indexURL),
              let items = try? JSONDecoder().decode([DocumentItem].self, from: data) else {
            documents = []
            return
        }
        documents = items
    }
    
    private func saveIndex() {
        guard let data = try? JSONEncoder().encode(documents) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
    
    @discardableResult
    func saveNewDocument(pdfData: Data, displayName: String? = nil, pageCount: Int = 1) -> DocumentItem? {
        // Generate date-based name if no custom name provided
        let finalName: String
        if let displayName = displayName, !displayName.isEmpty {
            finalName = displayName
        } else {
            // Use new timestamp format
            finalName = DocumentItem.generateDisplayName(type: .pdf)
        }
        
        let item = DocumentItem(displayName: finalName, pageCount: pageCount, type: .pdf)
        let fileURL = scansDirectory.appendingPathComponent(item.filename)
        
        do {
            try pdfData.write(to: fileURL, options: .atomic)
            documents.insert(item, at: 0)
            saveIndex()
            return item
        } catch {
            print("Failed to save PDF: \(error)")
            return nil
        }
    }
    
    @discardableResult
    func saveTextDocument(textData: Data, format: TextFormat, relatedPDFName: String? = nil) -> DocumentItem? {
        // Generate name that matches related PDF if provided
        let finalName: String
        if let pdfName = relatedPDFName {
            // Extract base name and add "- Extracted Text"
            finalName = "\(pdfName) - Extracted Text"
        } else {
            finalName = DocumentItem.generateDisplayName(type: .text(format))
        }
        
        let item = DocumentItem(displayName: finalName, pageCount: 1, type: .text(format))
        let fileURL = scansDirectory.appendingPathComponent(item.filename)
        
        do {
            try textData.write(to: fileURL, options: .atomic)
            documents.insert(item, at: 0)
            saveIndex()
            return item
        } catch {
            print("Failed to save text document: \(error)")
            return nil
        }
    }
    
    @discardableResult
    func importPDF(from url: URL) -> DocumentItem? {
        // Need coordinate access if it's outside our container
        let requiresSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if requiresSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        guard let data = try? Data(contentsOf: url) else { return nil }
        let filename = url.deletingPathExtension().lastPathComponent
        return saveNewDocument(pdfData: data, displayName: filename, pageCount: 1) // Page count can be evaluated later
    }
    
    func listDocuments() -> [DocumentItem] {
        return documents
    }
    
    
    func rename(id: String, newName: String) {
        if let index = documents.firstIndex(where: { $0.id == id }) {
            documents[index].displayName = newName
            saveIndex()
        }
    }
    
    func delete(id: String) {
        if let index = documents.firstIndex(where: { $0.id == id }) {
            let fileURL = url(for: id)
            try? fileManager.removeItem(at: fileURL)
            documents.remove(at: index)
            saveIndex()
        }
    }
    
    func url(for id: String) -> URL {
        return scansDirectory.appendingPathComponent("\(id).pdf")
    }
    
    func url(for item: DocumentItem) -> URL {
        return scansDirectory.appendingPathComponent(item.filename)
    }
    
    // MARK: - Export Functionality
    
    func exportAllDocuments(completion: @escaping (URL?) -> Void) {
        exportDocuments(ofType: nil, completion: completion)
    }
    
    func exportPDFs(completion: @escaping (URL?) -> Void) {
        exportDocuments(ofType: .pdf, completion: completion)
    }
    
    func exportTextFiles(completion: @escaping (URL?) -> Void) {
        exportDocuments(ofType: .text(.txt), completion: completion) // Will match any text format
    }
    
    private func exportDocuments(ofType type: DocumentType?, completion: @escaping (URL?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Filter documents by type if specified
            let documentsToExport: [DocumentItem]
            if let type = type {
                switch type {
                case .pdf:
                    documentsToExport = self.documents.filter { $0.type == .pdf }
                case .text:
                    documentsToExport = self.documents.filter {
                        if case .text = $0.type { return true }
                        return false
                    }
                }
            } else {
                documentsToExport = self.documents
            }
            
            guard !documentsToExport.isEmpty else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // Create temporary directory for ZIP
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Copy all files to temp directory
            for document in documentsToExport {
                let sourceURL = self.url(for: document)
                let destURL = tempDir.appendingPathComponent(document.displayName).appendingPathExtension(document.type.fileExtension)
                try? FileManager.default.copyItem(at: sourceURL, to: destURL)
            }
            
            // Create ZIP file
            let zipFileName = "Documents Export \(Date().timeIntervalSince1970).zip"
            let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent(zipFileName)
            
            // Remove existing ZIP if present
            try? FileManager.default.removeItem(at: zipURL)
            
            // Create ZIP using FileManager (simple approach)
            // For production, you'd use a proper ZIP library
            // For now, we'll create a simple archive
            if self.createZIP(from: tempDir, to: zipURL) {
                // Clean up temp directory
                try? FileManager.default.removeItem(at: tempDir)
                
                DispatchQueue.main.async {
                    completion(zipURL)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    private func createZIP(from sourceDir: URL, to destZIP: URL) -> Bool {
        // Simple ZIP creation using Foundation
        // Note: For production, use a proper ZIP library like ZIPFoundation
        do {
            let coordinator = NSFileCoordinator()
            var error: NSError?
            var success = false
            
            coordinator.coordinate(readingItemAt: sourceDir, options: .forUploading, error: &error) { zipURL in
                do {
                    try FileManager.default.copyItem(at: zipURL, to: destZIP)
                    success = true
                } catch {
                    print("Failed to create ZIP: \(error)")
                }
            }
            
            return success
        }
    }
    
    func documentCount(ofType type: DocumentType? = nil) -> Int {
        guard let type = type else {
            return documents.count
        }
        
        switch type {
        case .pdf:
            return documents.filter { $0.type == .pdf }.count
        case .text:
            return documents.filter {
                if case .text = $0.type { return true }
                return false
            }.count
        }
    }
    
    // MARK: - Favorite Management
    
    func toggleFavorite(id: String) {
        if let index = documents.firstIndex(where: { $0.id == id }) {
            documents[index].isFavorite.toggle()
            saveIndex()
        }
    }
    
    func listFavoriteDocuments() -> [DocumentItem] {
        return documents.filter { $0.isFavorite && !$0.isArchived }
    }
    
    // MARK: - Archive Management
    
    func toggleArchive(id: String) {
        if let index = documents.firstIndex(where: { $0.id == id }) {
            documents[index].isArchived.toggle()
            saveIndex()
        }
    }
    
    func listArchivedDocuments() -> [DocumentItem] {
        return documents.filter { $0.isArchived }
    }
    
    func listActiveDocuments() -> [DocumentItem] {
        return documents.filter { !$0.isArchived }
    }
}
