//
//  TextDisplayViewController.swift
//  PhotoToPDFMaker
//

import UIKit

class TextDisplayViewController: UIViewController {
    
    var displayText: String = ""
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.dataDetectorTypes = [.link]
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        textView.attributedText = formatMarkdownText(displayText)
    }
    
    private func formatMarkdownText(_ markdown: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        // Split by lines
        let lines = markdown.components(separatedBy: .newlines)
        
        for line in lines {
            var processedLine = line
            
            // Handle different heading levels
            if processedLine.hasPrefix("# ") {
                // H1 - Main title
                processedLine = String(processedLine.dropFirst(2))
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                paragraphStyle.paragraphSpacingBefore = 0
                paragraphStyle.paragraphSpacing = 12
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 26),
                    .foregroundColor: UIColor.label,
                    .paragraphStyle: paragraphStyle
                ]
                attributedString.append(NSAttributedString(string: processedLine + "\n", attributes: attributes))
            } else if processedLine.hasPrefix("## ") {
                // H2 - Section title
                processedLine = String(processedLine.dropFirst(3))
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                paragraphStyle.paragraphSpacingBefore = 16
                paragraphStyle.paragraphSpacing = 8
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 20),
                    .foregroundColor: UIColor.label,
                    .paragraphStyle: paragraphStyle
                ]
                attributedString.append(NSAttributedString(string: processedLine + "\n", attributes: attributes))
            } else if processedLine.hasPrefix("### ") {
                // H3 - Subsection title
                processedLine = String(processedLine.dropFirst(4))
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .left
                paragraphStyle.paragraphSpacingBefore = 12
                paragraphStyle.paragraphSpacing = 6
                
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 17),
                    .foregroundColor: UIColor.label,
                    .paragraphStyle: paragraphStyle
                ]
                attributedString.append(NSAttributedString(string: processedLine + "\n", attributes: attributes))
            } else if processedLine.trimmingCharacters(in: .whitespaces).isEmpty {
                // Empty line - preserve spacing
                attributedString.append(NSAttributedString(string: "\n"))
            } else if processedLine.hasPrefix("- ") {
                // Bullet point
                processedLine = String(processedLine.dropFirst(2))
                let formattedLine = formatInlineBold(processedLine, fontSize: 15, isSecondary: false)
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.firstLineHeadIndent = 0
                paragraphStyle.headIndent = 20
                paragraphStyle.lineSpacing = 3
                
                let bullet = NSMutableAttributedString(string: "• ", attributes: [
                    .font: UIFont.systemFont(ofSize: 15),
                    .foregroundColor: UIColor.label
                ])
                bullet.append(formattedLine)
                bullet.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: bullet.length))
                attributedString.append(bullet)
                attributedString.append(NSAttributedString(string: "\n"))
            } else {
                // Regular paragraph text - handle inline bold
                let formattedLine = formatInlineBold(processedLine, fontSize: 15, isSecondary: false)
                attributedString.append(formattedLine)
                attributedString.append(NSAttributedString(string: "\n"))
            }
        }
        
        // Set default paragraph style for better readability
        let defaultParagraphStyle = NSMutableParagraphStyle()
        defaultParagraphStyle.lineSpacing = 3
        defaultParagraphStyle.paragraphSpacing = 6
        
        let fullRange = NSRange(location: 0, length: attributedString.length)
        attributedString.addAttribute(.paragraphStyle, value: defaultParagraphStyle, range: fullRange)
        
        return attributedString
    }
    
    private func formatInlineBold(_ text: String, fontSize: CGFloat, isSecondary: Bool) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let regularFont = UIFont.systemFont(ofSize: fontSize)
        let boldFont = UIFont.boldSystemFont(ofSize: fontSize)
        let color: UIColor = isSecondary ? .secondaryLabel : .label
        
        var remainingText = text
        
        while let boldStart = remainingText.range(of: "**") {
            // Add text before the bold marker
            let beforeBold = String(remainingText[..<boldStart.lowerBound])
            if !beforeBold.isEmpty {
                result.append(NSAttributedString(string: beforeBold, attributes: [
                    .font: regularFont,
                    .foregroundColor: color
                ]))
            }
            
            // Find the closing **
            remainingText = String(remainingText[boldStart.upperBound...])
            if let boldEnd = remainingText.range(of: "**") {
                // Add bold text
                let boldText = String(remainingText[..<boldEnd.lowerBound])
                result.append(NSAttributedString(string: boldText, attributes: [
                    .font: boldFont,
                    .foregroundColor: color
                ]))
                remainingText = String(remainingText[boldEnd.upperBound...])
            } else {
                // No closing **, treat as regular text
                result.append(NSAttributedString(string: "**" + remainingText, attributes: [
                    .font: regularFont,
                    .foregroundColor: color
                ]))
                remainingText = ""
                break
            }
        }
        
        // Add any remaining text
        if !remainingText.isEmpty {
            result.append(NSAttributedString(string: remainingText, attributes: [
                .font: regularFont,
                .foregroundColor: color
            ]))
        }
        
        return result
    }
}
