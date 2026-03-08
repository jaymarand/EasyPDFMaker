//
//  ShareCoordinator.swift
//  PhotoToPDFMaker
//

import UIKit

class ShareCoordinator {
    
    static func shareURL(_ url: URL, from viewController: UIViewController, sourceView: UIView) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        
        viewController.present(activityVC, animated: true)
    }
    
    static func shareText(_ text: String, from viewController: UIViewController, sourceView: UIView) {
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        
        viewController.present(activityVC, animated: true)
    }
}
