//
//  DocumentItem.swift
//  PhotoToPDFMaker
//

import Foundation

enum DocumentType: Codable, Equatable {
    case pdf
    case text(TextFormat)
    
    var fileExtension: String {
        switch self {
        case .pdf:
            return "pdf"
        case .text(let format):
            return format.rawValue
        }
    }
    
    var iconName: String {
        switch self {
        case .pdf:
            return "doc.fill"
        case .text:
            return "doc.text.fill"
        }
    }
}

enum TextFormat: String, Codable {
    case txt
    case docx
}

struct DocumentItem: Codable, Identifiable {
    let id: String
    var displayName: String
    let createdAt: Date
    let pageCount: Int
    let type: DocumentType
    var filename: String
    var isFavorite: Bool = false
    var isArchived: Bool = false
    
    init(id: String = UUID().uuidString, displayName: String, createdAt: Date = Date(), pageCount: Int = 1, type: DocumentType = .pdf, isFavorite: Bool = false, isArchived: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.createdAt = createdAt
        self.pageCount = pageCount
        self.type = type
        self.filename = "\(id).\(type.fileExtension)"
        self.isFavorite = isFavorite
        self.isArchived = isArchived
    }
    
    /// Formatted display name with timestamp
    static func generateDisplayName(type: DocumentType, date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy h:mma"
        let timestamp = formatter.string(from: date)
        
        switch type {
        case .pdf:
            return "Document \(timestamp)"
        case .text:
            return "Document \(timestamp) - Extracted Text"
        }
    }
}
