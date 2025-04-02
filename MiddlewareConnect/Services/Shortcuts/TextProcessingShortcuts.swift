import Foundation
import UIKit

/// Handler for text chunking shortcuts
class TextChunkerShortcutHandler: TextProcessingShortcutHandler {
    let shortcutType: ShortcutsManager.ShortcutType = .textChunker
    
    func handle(parameters: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        // Get the parameters
        guard let text = parameters["text"] as? String,
              let chunkSize = parameters["chunkSize"] as? Int,
              let overlap = parameters["overlap"] as? Int else {
            completion(false, nil)
            return
        }
        
        // Implementation using the text chunking algorithm
        let chunks = chunkText(text, chunkSize: chunkSize, overlap: overlap)
        
        // Store the result for later retrieval
        let result = chunks.joined(separator: "\n\n--- CHUNK SEPARATOR ---\n\n")
        storeResult(result)
        
        // Create a notification to inform the user
        showNotification(
            title: "Text Chunking Complete",
            body: "Your text has been split into \(chunks.count) chunks", 
            success: true
        )
        
        completion(true, nil)
    }
    
    /// Text chunking algorithm (simplified version of the one in TextChunkerViewModel)
    private func chunkText(_ text: String, chunkSize: Int, overlap: Int) -> [String] {
        guard !text.isEmpty && chunkSize > 0 else { return [] }
        
        var chunks: [String] = []
        var startIndex = text.startIndex
        
        while startIndex < text.endIndex {
            let endDistance = min(chunkSize, text.distance(from: startIndex, to: text.endIndex))
            let endIndex = text.index(startIndex, offsetBy: endDistance)
            
            let chunk = String(text[startIndex..<endIndex])
            chunks.append(chunk)
            
            if endIndex >= text.endIndex {
                break
            }
            
            // Calculate the next start index with overlap
            let overlapDistance = min(overlap, endDistance)
            startIndex = text.index(endIndex, offsetBy: -overlapDistance)
        }
        
        return chunks
    }
}

/// Handler for text cleaning shortcuts
class TextCleanerShortcutHandler: TextProcessingShortcutHandler {
    let shortcutType: ShortcutsManager.ShortcutType = .textCleaner
    
    func handle(parameters: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        // Get the parameters
        guard let text = parameters["text"] as? String else {
            completion(false, nil)
            return
        }
        
        let removeExtraSpaces = parameters["removeExtraSpaces"] as? Bool ?? true
        let removeExtraNewlines = parameters["removeExtraNewlines"] as? Bool ?? true
        let normalizeQuotes = parameters["normalizeQuotes"] as? Bool ?? true
        
        // Clean the text based on the parameters
        var cleanedText = text
        
        if removeExtraSpaces {
            // Replace multiple spaces with a single space
            cleanedText = cleanedText.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        }
        
        if removeExtraNewlines {
            // Replace multiple newlines with a single newline
            cleanedText = cleanedText.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        }
        
        if normalizeQuotes {
            // Replace curly quotes with straight quotes
            cleanedText = cleanedText.replacingOccurrences(of: """, with: "\"")
            cleanedText = cleanedText.replacingOccurrences(of: """, with: "\"")
            cleanedText = cleanedText.replacingOccurrences(of: "'", with: "'")
            cleanedText = cleanedText.replacingOccurrences(of: "'", with: "'")
        }
        
        // Store the result
        storeResult(cleanedText)
        
        // Create a notification to inform the user
        showNotification(
            title: "Text Cleaning Complete",
            body: "Your text has been cleaned and formatted",
            success: true
        )
        
        completion(true, nil)
    }
}

/// Handler for markdown conversion shortcuts
class MarkdownConverterShortcutHandler: TextProcessingShortcutHandler {
    let shortcutType: ShortcutsManager.ShortcutType = .markdownConverter
    
    /// The Anthropic service for conversion
    private let anthropicService = AnthropicService()
    
    func handle(parameters: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        // Get the parameters
        guard let text = parameters["text"] as? String,
              let conversionType = parameters["conversionType"] as? String else {
            completion(false, nil)
            return
        }
        
        var targetFormat: MarkdownFormat
        
        // Determine the target format based on the conversion type
        switch conversionType.lowercased() {
        case "html", "markdown-to-html":
            targetFormat = .html
        case "plain", "text", "markdown-to-text", "markdown-to-plain":
            targetFormat = .plainText
        case "latex", "markdown-to-latex":
            targetFormat = .latex
        case "rtf", "rich-text", "markdown-to-rtf":
            targetFormat = .rtf
        default:
            targetFormat = .html // Default to HTML if unknown
        }
        
        // Perform the conversion
        anthropicService.convertMarkdown(markdown: text, targetFormat: targetFormat) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let convertedText):
                // Store the result
                self.storeResult(convertedText)
                
                // Create a notification to inform the user
                self.showNotification(
                    title: "Markdown Conversion Complete",
                    body: "Your markdown has been converted to \(targetFormat.rawValue)",
                    success: true
                )
                
                completion(true, nil)
                
            case .failure(let error):
                // Handle error
                self.showNotification(
                    title: "Markdown Conversion Failed",
                    body: "Error: \(error.localizedDescription)",
                    success: false
                )
                
                completion(false, error)
            }
        }
    }
}

/// Handler for document summarization shortcuts
class DocumentSummarizerShortcutHandler: TextProcessingShortcutHandler {
    let shortcutType: ShortcutsManager.ShortcutType = .documentSummarizer
    
    /// The Anthropic service for summarization
    private let anthropicService = AnthropicService()
    
    func handle(parameters: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        // Get the parameters
        guard let fileURL = parameters["fileURL"] as? URL else {
            completion(false, nil)
            return
        }
        
        let summaryLength = parameters["summaryLength"] as? String ?? "medium"
        var summaryLengthEnum: SummaryLength = .moderate
        
        // Convert string to enum
        switch summaryLength.lowercased() {
        case "short", "brief":
            summaryLengthEnum = .brief
        case "medium", "moderate":
            summaryLengthEnum = .moderate
        case "long", "detailed":
            summaryLengthEnum = .detailed
        default:
            summaryLengthEnum = .moderate
        }
        
        // Read the document contents
        do {
            let data = try Data(contentsOf: fileURL)
            
            // Basic handling for TXT and PDF files
            var text = ""
            
            if fileURL.pathExtension.lowercased() == "pdf" {
                // For PDF files, use PDFKit to extract text
                if let pdf = PDFDocument(url: fileURL) {
                    text = extractTextFromPDF(pdf)
                } else {
                    completion(false, NSError(domain: "com.llmbuddy.shortcuts", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to open PDF"]))
                    return
                }
            } else {
                // For text files, convert data to string
                text = String(data: data, encoding: .utf8) ?? ""
            }
            
            if text.isEmpty {
                completion(false, NSError(domain: "com.llmbuddy.shortcuts", code: 1002, userInfo: [NSLocalizedDescriptionKey: "No text found in document"]))
                return
            }
            
            // Summarize the document using the AnthropicService
            anthropicService.summarizeDocument(text: text, length: summaryLengthEnum) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let summary):
                    // Store the result
                    self.storeResult(summary)
                    
                    // Create a notification to inform the user
                    self.showNotification(
                        title: "Document Summarization Complete",
                        body: "Your document has been summarized",
                        success: true
                    )
                    
                    completion(true, nil)
                    
                case .failure(let error):
                    // Handle error
                    self.showNotification(
                        title: "Document Summarization Failed",
                        body: "Error: \(error.localizedDescription)",
                        success: false
                    )
                    
                    completion(false, error)
                }
            }
        } catch {
            completion(false, error)
            return
        }
    }
    
    /// Extract text from PDF document
    /// - Parameter pdf: The PDF document
    /// - Returns: The extracted text
    private func extractTextFromPDF(_ pdf: PDFDocument) -> String {
        var text = ""
        
        for i in 0..<pdf.pageCount {
            guard let page = pdf.page(at: i) else { continue }
            if let pageText = page.string {
                text += pageText + "\n\n"
            }
        }
        
        return text
    }
}