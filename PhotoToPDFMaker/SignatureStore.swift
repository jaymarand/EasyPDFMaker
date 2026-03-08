//
//  SignatureStore.swift
//  PhotoToPDFMaker
//

import UIKit

class SignatureStore {
    static let shared = SignatureStore()
    
    private let fileManager = FileManager.default
    private let signatureURL: URL
    
    private init() {
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        signatureURL = docsDir.appendingPathComponent("saved_signature.png")
    }
    
    func saveSignature(_ image: UIImage) {
        guard let data = image.pngData() else { return }
        try? data.write(to: signatureURL, options: .atomic)
    }
    
    func loadSignature() -> UIImage? {
        guard fileManager.fileExists(atPath: signatureURL.path),
              let data = try? Data(contentsOf: signatureURL) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    func deleteSignature() {
        try? fileManager.removeItem(at: signatureURL)
    }
    
    var hasSignature: Bool {
        return fileManager.fileExists(atPath: signatureURL.path)
    }
}
