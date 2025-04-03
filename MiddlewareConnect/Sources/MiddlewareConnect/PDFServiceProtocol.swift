/**
@fileoverview Protocol for PDF processing service
@module PDFServiceProtocol
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- Foundation
- PDFKit
- Combine
Exports:
- PDFServiceProtocol
Notes:
- Implements the Type-Safe View Protocols pattern from architectural framework
- Defines explicit contract for PDF service operations
/

import Foundation
import PDFKit
import Combine

/// Protocol for PDF processing service
protocol PDFServiceProtocol {
    /// Publisher for PDF processing progress
    var progress: AnyPublisher<Double, Never> { get }
    
    /// Publisher for PDF processing status
    var status: AnyPublisher<PDFProcessingStatus, Error> { get }
    
    /// Combine multiple PDFs into a single PDF
    /// - Parameter urls: Array of PDF file URLs
    /// - Returns: URL of the combined PDF
    /// - Throws: PDFError if combining fails
    func combinePDFs(urls: [URL]) throws -> URL
    
    /// Combine multiple PDFs into a single PDF (alias for combinePDFs for better naming consistency)
    /// - Parameter urls: Array of PDF file URLs
    /// - Returns: URL of the combined PDF
    /// - Throws: PDFError if combining fails
    func combineDocuments(urls: [URL]) throws -> URL
    
    /// Extract text from a PDF using OCR if needed
    /// - Parameters:
    ///   - url: URL of the PDF file
    ///   - useOCR: Whether to use OCR for scanned documents
    ///   - completion: Callback with the extracted text
    func extractText(from url: URL, useOCR: Bool, completion: @escaping (Result<String, Error>) -> Void)
    
    /// Extract specific pages from a PDF
    /// - Parameters:
    ///   - url: URL of the PDF file
    ///   - pageRanges: Ranges of pages to extract
    /// - Returns: URL of the new PDF with extracted pages
    /// - Throws: PDFError if extraction fails
    func extractPages(from url: URL, pageRanges: [ClosedRange<Int>]) throws -> URL
    
    /// Add annotations to a PDF
    /// - Parameters:
    ///   - url: URL of the PDF file
    ///   - annotations: Array of annotations to add
    /// - Returns: URL of the annotated PDF
    /// - Throws: PDFError if annotation fails
    func addAnnotations(to url: URL, annotations: [PDFAnnotation]) throws -> URL
    
    /// Split a PDF into multiple PDFs
    /// - Parameters:
    ///   - url: URL of the PDF file
    ///   - strategy: Splitting strategy
    /// - Returns: Array of URLs of the split PDFs
    /// - Throws: PDFError if splitting fails
    func splitPDF(url: URL, strategy: PDFSplitStrategy) throws -> [URL]
    
    /// Clean up temporary files
    func cleanupTempFiles()
    
    /// Auxiliary function to get information about a PDF
    /// - Parameter url: URL of the PDF file
    /// - Returns: Information about the PDF
    /// - Throws: PDFError if information cannot be retrieved
    func getPDFInfo(url: URL) throws -> PDFInfo
}

/// Information about a PDF
struct PDFInfo {
    /// Number of pages in the PDF
    let pageCount: Int
    
    /// File size in bytes
    let fileSize: Int64
    
    /// Formatted file size
    var fileSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    /// Creator of the PDF
    let creator: String?
    
    /// Author of the PDF
    let author: String?
    
    /// Title of the PDF
    let title: String?
}

// Extension to make existing PDFService conform to PDFServiceProtocol
extension PDFService: PDFServiceProtocol {
    /// Get information about a PDF
    /// - Parameter url: URL of the PDF file
    /// - Returns: Information about the PDF
    /// - Throws: PDFError if information cannot be retrieved
    func getPDFInfo(url: URL) throws -> PDFInfo {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PDFError.fileNotFound(path: url.path)
        }
        
        // Check if file is a PDF
        guard url.pathExtension.lowercased() == "pdf" else {
            throw PDFError.invalidFileType(expected: "pdf", actual: url.pathExtension)
        }
        
        // Load the PDF
        guard let pdf = PDFDocument(url: url) else {
            throw PDFError.couldNotOpenPDF(path: url.path)
        }
        
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Get metadata
        let info = pdf.documentAttributes ?? [:]
        let creator = info[PDFDocumentAttribute.creatorAttribute] as? String
        let author = info[PDFDocumentAttribute.authorAttribute] as? String
        let title = info[PDFDocumentAttribute.titleAttribute] as? String
        
        return PDFInfo(
            pageCount: pdf.pageCount,
            fileSize: fileSize,
            creator: creator,
            author: author,
            title: title
        )
    }
}
