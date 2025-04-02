import Foundation
import PDFKit
import UIKit

/// Base class for PDF shortcut handlers
class BasePDFShortcutHandler: PDFShortcutHandler {
    let pdfService: PDFService = PDFService.shared
    var shortcutType: ShortcutsManager.ShortcutType { fatalError("Subclasses must implement this") }
    
    func handle(parameters: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        fatalError("Subclasses must implement this")
    }
    
    /// Check if operation might cause memory issues and clear memory if needed
    /// - Parameter urls: URLs to the PDF files involved in the operation
    func checkAndClearMemoryIfNeeded(urls: [URL]) {
        if pdfService.mightCauseMemoryIssues(urls: urls) {
            // Clear memory before proceeding
            MemoryManager.shared.clearMemoryCaches()
        }
    }
}

/// Handler for PDF combining shortcuts
class PDFCombinerShortcutHandler: BasePDFShortcutHandler {
    override var shortcutType: ShortcutsManager.ShortcutType { .pdfCombiner }
    
    override func handle(parameters: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        // Get the parameters
        guard let fileURLs = parameters["fileURLs"] as? [URL] else {
            completion(false, nil)
            return
        }
        
        // Create a temporary output path
        let tempDir = FileManager.default.temporaryDirectory
        let outputPath = tempDir.appendingPathComponent("CombinedDocument_\(UUID().uuidString).pdf")
        
        // Check if operation might cause memory issues
        checkAndClearMemoryIfNeeded(urls: fileURLs)
        
        // Perform the operation
        let success = pdfService.combinePDFs(fileURLs, outputPath: outputPath)
        
        if success {
            // Store the result path for later retrieval
            UserDefaults.standard.set(outputPath.path, forKey: "last_shortcut_result_path")
            
            // Create a notification to inform the user
            showNotification(
                title: "PDF Combining Complete",
                body: "\(fileURLs.count) PDF files have been combined",
                success: true
            )
            
            completion(true, nil)
        } else {
            // Handle error
            let error = NSError(domain: "com.llmbuddy.shortcuts", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Failed to combine PDF files"])
            
            showNotification(
                title: "PDF Combining Failed",
                body: "Error: \(error.localizedDescription)",
                success: false
            )
            
            completion(false, error)
        }
    }
}

/// Handler for PDF splitting shortcuts
class PDFSplitterShortcutHandler: BasePDFShortcutHandler {
    override var shortcutType: ShortcutsManager.ShortcutType { .pdfSplitter }
    
    override func handle(parameters: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        // Get the parameters
        guard let fileURL = parameters["fileURL"] as? URL,
              let splitType = parameters["splitType"] as? String,
              let pages = parameters["pages"] as? String else {
            completion(false, nil)
            return
        }
        
        // Create a temporary output directory
        let tempDir = FileManager.default.temporaryDirectory
        let outputDir = tempDir.appendingPathComponent("SplitPDFs_\(UUID().uuidString)")
        
        do {
            // Create the output directory
            try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
            
            // Convert page string to page ranges
            let pageRanges = parsePageRanges(pages)
            
            if pageRanges.isEmpty {
                let error = NSError(domain: "com.llmbuddy.shortcuts", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Invalid page ranges"])
                completion(false, error)
                return
            }
            
            // Check if operation might cause memory issues
            checkAndClearMemoryIfNeeded(urls: [fileURL])
            
            // Perform the operation
            let outputURLs = pdfService.splitPDF(at: fileURL, outputDirectory: outputDir, pageRanges: pageRanges)
            
            if !outputURLs.isEmpty {
                // Store the result paths for later retrieval
                let paths = outputURLs.map { $0.path }
                UserDefaults.standard.set(paths, forKey: "last_shortcut_result_paths")
                
                // Create a notification to inform the user
                showNotification(
                    title: "PDF Splitting Complete",
                    body: "PDF has been split into \(outputURLs.count) files",
                    success: true
                )
                
                completion(true, nil)
            } else {
                // Handle error
                let error = NSError(domain: "com.llmbuddy.shortcuts", code: 1005, userInfo: [NSLocalizedDescriptionKey: "Failed to split PDF file"])
                
                showNotification(
                    title: "PDF Splitting Failed",
                    body: "Error: \(error.localizedDescription)",
                    success: false
                )
                
                completion(false, error)
            }
        } catch {
            // Handle error
            showNotification(
                title: "PDF Splitting Failed",
                body: "Error: \(error.localizedDescription)",
                success: false
            )
            
            completion(false, error)
        }
    }
    
    /// Parse page ranges string into an array of range strings
    /// - Parameter pagesString: String like "1-3,5,7-9"
    /// - Returns: Array of range strings like ["1-3", "5-5", "7-9"]
    private func parsePageRanges(_ pagesString: String) -> [String] {
        var ranges: [String] = []
        
        // Split by comma
        let parts = pagesString.components(separatedBy: ",")
        
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmed.contains("-") {
                // Already a range
                ranges.append(trimmed)
            } else if let page = Int(trimmed) {
                // Single page, convert to a range with itself
                ranges.append("\(page)-\(page)")
            }
        }
        
        return ranges
    }
}