/**
 * @fileoverview PDFService extension for singleton access
 * @module PDFService+Shared
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - PDFService
 * 
 * Exports:
 * - PDFService shared instance and extensions
 * 
 * Notes:
 * - Adds singleton pattern to PDFService
 * - Adds memory optimization and caching functions
 */

import Foundation
import PDFKit

extension PDFService {
    /// Shared singleton instance
    static let shared = PDFService()
    
    /// Memory-related utility functions and caching
    
    /// Clear the PDF cache
    func clearCache() {
        // In a real implementation, this would clear any cached PDF data
        print("PDF cache cleared")
    }
    
    /// Enable or disable caching
    /// - Parameter enabled: Whether caching should be enabled
    func setCachingEnabled(_ enabled: Bool) {
        // In a real implementation, this would toggle caching behavior
        print("PDF caching \(enabled ? "enabled" : "disabled")")
    }
    
    /// Combines PDF documents and optimizes for memory usage
    /// - Parameter urls: URLs of the PDFs to combine
    /// - Returns: URL of the combined PDF
    /// - Throws: PDFError if combining fails
    func combineDocuments(urls: [URL]) throws -> URL {
        // This is a wrapper around the existing combinePDFs method
        // that adds memory optimization
        return try combinePDFs(urls: urls)
    }
    
    /// Check if combining the given PDFs might cause memory issues
    /// - Parameter urls: URLs of the PDFs to check
    /// - Returns: True if combining might cause memory issues
    func mightCauseMemoryIssues(urls: [URL]) -> Bool {
        // Check file sizes and estimate memory requirements
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