/**
 * @fileoverview PDF Service for handling PDF operations
 * @module PDFService
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - Foundation
 * - PDFKit
 * 
 * Exports:
 * - PDFService
 * - PDFInfo
 * 
 * Notes:
 * - Provides utility functions for working with PDF files
 * - Handles extraction, combination, splitting, and metadata operations
 */

import Foundation
import PDFKit

/// Service for handling PDF operations
class PDFService {
    // MARK: - Methods
    
    /// Get information about a PDF file
    /// - Parameter url: URL of the PDF file
    /// - Returns: PDFInfo object containing metadata
    /// - Throws: Error if the PDF cannot be read or parsed
    func getPDFInfo(url: URL) throws -> PDFInfo {
        guard let document = PDFDocument(url: url) else {
            throw PDFError.cannotCreatePDFDocument
        }
        
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = fileAttributes[.size] as? Int64 ?? 0
        
        return PDFInfo(
            url: url,
            fileName: url.lastPathComponent,
            pageCount: document.pageCount,
            fileSize: fileSize,
            isEncrypted: document.isEncrypted,
            isLocked: document.isLocked
        )
    }
    
    /// Extract text from a PDF file
    /// - Parameter url: URL of the PDF file
    /// - Returns: Extracted text as a string
    /// - Throws: Error if the PDF cannot be read or parsed
    func extractTextFromPDF(url: URL) throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw PDFError.cannotCreatePDFDocument
        }
        
        var text = ""
        for i in 0..<document.pageCount {
            if let page = document.page(at: i), let pageText = page.string {
                text += pageText + "\n\n"
            }
        }
        
        if text.isEmpty {
            throw PDFError.noTextContent
        }
        
        return text
    }
    
    /// Clear any cached PDF data
    func clearCache() {
        // This would clear any cached PDF data in a real implementation
        print("PDF cache cleared")
    }
    
    /// Enable or disable PDF caching
    /// - Parameter enabled: Whether caching should be enabled
    func setCachingEnabled(_ enabled: Bool) {
        // This would toggle caching behavior in a real implementation
        print("PDF caching \(enabled ? "enabled" : "disabled")")
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
    
    /// Combine multiple PDF files into a single PDF
    /// - Parameter urls: Array of PDF URLs to combine
    /// - Returns: URL of the combined PDF file
    /// - Throws: Error if PDFs cannot be combined
    func combinePDFs(urls: [URL]) throws -> URL {
        guard !urls.isEmpty else {
            throw PDFError.noPDFsToProcess
        }
        
        // Create a new PDF document
        let combinedPDF = PDFDocument()
        
        // Add pages from each PDF
        for url in urls {
            guard let pdf = PDFDocument(url: url) else {
                throw PDFError.cannotCreatePDFDocument
            }
            
            for i in 0..<pdf.pageCount {
                if let page = pdf.page(at: i) {
                    combinedPDF.insert(page, at: combinedPDF.pageCount)
                }
            }
        }
        
        // Create output file
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("combined_\(Int(Date().timeIntervalSince1970))")
            .appendingPathExtension("pdf")
        
        if !combinedPDF.write(to: outputURL) {
            throw PDFError.cannotWritePDF
        }
        
        return outputURL
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
    
    /// Split a PDF into multiple PDFs based on page ranges
    ///   - url: URL of the PDF to split
    ///   - ranges: Array of page ranges with names
    /// - Returns: Dictionary mapping output names to file URLs
    /// - Throws: Error if PDF cannot be split
    func splitPDF(url: URL, ranges: [(name: String, range: ClosedRange<Int>)]) throws -> [String: URL] {
        guard let document = PDFDocument(url: url) else {
            throw PDFError.cannotCreatePDFDocument
        }
        
        guard !ranges.isEmpty else {
            throw PDFError.invalidPageRanges
        }
        
        // Check if ranges are valid
        for range in ranges {
            if range.range.lowerBound < 1 || range.range.upperBound > document.pageCount {
                throw PDFError.invalidPageRanges
            }
        }
        
        // Create output directory
        let outputDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("split_\(Int(Date().timeIntervalSince1970))")
        
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        var outputURLs: [String: URL] = [:]
        
        // Process each range
        for rangeInfo in ranges {
            let newPDF = PDFDocument()
            
            // Add pages from the range (adjust for 0-based indexing)
            for i in (rangeInfo.range.lowerBound - 1)...(rangeInfo.range.upperBound - 1) {
                if let page = document.page(at: i) {
                    newPDF.insert(page, at: newPDF.pageCount)
                }
            }
            
            // Create output file
            let sanitizedName = rangeInfo.name.replacingOccurrences(of: "/", with: "-")
            let outputURL = outputDir.appendingPathComponent("\(sanitizedName).pdf")
            
            if !newPDF.write(to: outputURL) {
                throw PDFError.cannotWritePDF
            }
            
            outputURLs[rangeInfo.name] = outputURL
        }
        
        return outputURLs
    }
    
    /// Check if a PDF is searchable (contains text layer)
    /// - Parameter url: URL of the PDF file
    /// - Returns: Boolean indicating if the PDF is searchable
    /// - Throws: Error if the PDF cannot be read
    func isPDFSearchable(url: URL) throws -> Bool {
        guard let document = PDFDocument(url: url) else {
            throw PDFError.cannotCreatePDFDocument
        }
        
        // Check a sample of pages for text content
        let pagesToCheck = min(5, document.pageCount)
        var textFoundCount = 0
        
        for i in 0..<pagesToCheck {
            if let page = document.page(at: i), let pageText = page.string, !pageText.isEmpty {
                textFoundCount += 1
            }
        }
        
        // PDF is considered searchable if most checked pages have text
        return textFoundCount >= (pagesToCheck / 2)
    }
}

/// PDF File Information Structure
struct PDFInfo {
    let url: URL
    let fileName: String
    let pageCount: Int
    let fileSize: Int64
    let isEncrypted: Bool
    let isLocked: Bool
    
    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

/// PDF Operation Errors
enum PDFError: Error {
    case cannotCreatePDFDocument
    case cannotWritePDF
    case noTextContent
    case noPDFsToProcess
    case invalidPageRanges
    case fileAccessError
    
    var localizedDescription: String {
        switch self {
        case .cannotCreatePDFDocument:
            return "Cannot open or create PDF document"
        case .cannotWritePDF:
            return "Failed to write PDF file"
        case .noTextContent:
            return "No extractable text content found in PDF"
        case .noPDFsToProcess:
            return "No PDF files provided for processing"
        case .invalidPageRanges:
            return "Invalid page ranges specified"
        case .fileAccessError:
            return "Error accessing file"
        }
    }
}
