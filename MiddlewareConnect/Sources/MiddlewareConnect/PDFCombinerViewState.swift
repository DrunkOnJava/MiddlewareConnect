/**
@fileoverview View state container for PDF Combiner
@module PDFCombiner/ViewModels
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- Foundation
- PDFKit
- Combine
Exports:
- PDFCombinerViewState
Notes:
- Implements the View State Container Pattern from architectural framework
- Centralizes state management for PDF Combiner view
- Provides explicit interfaces for state transitions
/

import Foundation
import PDFKit
import Combine

/// View state container for PDF Combiner
final class PDFCombinerViewState: ObservableObject {
    // MARK: - Published Properties
    
    /// URL of the selected PDFs
    @Published private(set) var selectedPDFURLs: [URL] = []
    
    /// URL of the combined PDF
    @Published private(set) var combinedPDFURL: URL? = nil
    
    /// Processing status
    @Published private(set) var isProcessing: Bool = false
    
    /// Error message
    @Published private(set) var errorMessage: String? = nil
    
    /// PDF service dependency
    private let pdfService: PDFService
    
    // MARK: - Initialization
    
    /// Initialize with the PDF service
    init(pdfService: PDFService = PDFService()) {
        self.pdfService = pdfService
    }
    
    // MARK: - Public Methods
    
    /// Set the selected PDF URLs
    func setSelectedPDFURLs(_ urls: [URL]) {
        self.selectedPDFURLs = urls
    }
    
    /// Add a PDF URL to the selected PDFs
    func addPDFURL(_ url: URL) -> Bool {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "File not found: \(url.path)"
            return false
        }
        
        // Check if file is a PDF
        guard url.pathExtension.lowercased() == "pdf" else {
            errorMessage = "Invalid file type: expected pdf, got \(url.pathExtension)"
            return false
        }
        
        // Check if the URL is already in the list
        if selectedPDFURLs.contains(url) {
            return false
        }
        
        // Add the URL
        selectedPDFURLs.append(url)
        return true
    }
    
    /// Remove a PDF URL from the selected PDFs
    func removePDFURL(_ url: URL) {
        selectedPDFURLs.removeAll { $0 == url }
        
        // Clear combined PDF if we've removed a file
        combinedPDFURL = nil
    }
    
    /// Remove a PDF URL from the selected PDFs by index
    func removePDFURL(at index: Int) {
        guard index < selectedPDFURLs.count else { return }
        selectedPDFURLs.remove(at: index)
        
        // Clear combined PDF if we've removed a file
        combinedPDFURL = nil
    }
    
    /// Clear all selected PDFs
    func clearSelectedPDFs() {
        selectedPDFURLs.removeAll()
        combinedPDFURL = nil
        errorMessage = nil
    }
    
    /// Combine the selected PDFs
    func combineSelectedPDFs(completion: (() -> Void)? = nil) {
        guard selectedPDFURLs.count >= 2 else {
            errorMessage = "At least two PDFs are required for combining"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        // Use background thread for processing
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let combinedURL = try self.pdfService.combineDocuments(urls: self.selectedPDFURLs)
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.combinedPDFURL = combinedURL
                    self.isProcessing = false
                    
                    // Clear memory after operation completes
                    MemoryManager.shared.clearMemoryCaches()
                    
                    // Call completion handler
                    completion?()
                }
            } catch {
                // Handle error on main thread
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to combine PDFs: \(error.localizedDescription)"
                    self.isProcessing = false
                    
                    // Call completion handler
                    completion?()
                }
            }
        }
    }
    
    /// Check if combining the PDFs might cause memory issues
    func mightCauseMemoryIssues() -> Bool {
        return checkMemoryRequirements(forURLs: selectedPDFURLs)
    }
    
    /// Check memory requirements for PDF operations
    func checkMemoryRequirements(forURLs urls: [URL]) -> Bool {
        // Calculate total size of files
        var totalSize: Int64 = 0
        
        for url in urls {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                totalSize += fileSize
            } catch {
                // If we can't get the size, assume it's large
                totalSize += 10_000_000 // 10 MB estimate
            }
        }
        
        // If total size is more than 100 MB, warn about potential memory issues
        return totalSize > 100_000_000
    }
}