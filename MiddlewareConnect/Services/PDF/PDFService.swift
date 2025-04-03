/**
 * @fileoverview PDF processing service
 * @module PDFService
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * - PDFKit
 * - Vision (for OCR)
 * 
 * Exports:
 * - PDFService
 * 
 * Notes:
 * - Main service for PDF processing functionality
 * - Handles PDF manipulation, OCR, and annotations
 * - Extended by PDFService+Shared for caching and memory management
 */

import Foundation
import PDFKit
import Vision
import VisionKit
import Combine

/// PDF processing service for handling document operations
class PDFService {
    // MARK: - Properties
    
    /// Publisher for PDF processing progress
    private let progressSubject = CurrentValueSubject<Double, Never>(0)
    var progress: AnyPublisher<Double, Never> {
        return progressSubject.eraseToAnyPublisher()
    }
    
    /// Publisher for PDF processing status
    private let statusSubject = PassthroughSubject<PDFProcessingStatus, Error>()
    var status: AnyPublisher<PDFProcessingStatus, Error> {
        return statusSubject.eraseToAnyPublisher()
    }
    
    /// Default folder for temporary files
    private let tempFolder: URL = {
        let tempDirectory = FileManager.default.temporaryDirectory
        let pdfDirectory = tempDirectory.appendingPathComponent("PDFService", isDirectory: true)
        
        // Create the directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: pdfDirectory.path) {
            try? FileManager.default.createDirectory(at: pdfDirectory, withIntermediateDirectories: true)
        }
        
        return pdfDirectory
    }()
    
    // MARK: - Initialization
    
    init() {
        // Clean up any temporary files
        cleanupTempFiles()
    }
    
    // MARK: - Public Methods
    
    /// Combine multiple PDFs into a single PDF
    /// - Parameter urls: Array of PDF file URLs
    /// - Returns: URL of the combined PDF
    /// - Throws: PDFError if combining fails
    func combinePDFs(urls: [URL]) throws -> URL {
        return try combineDocuments(urls: urls)
    }
    
    /// Combine multiple PDFs into a single PDF (alias for combinePDFs for better naming consistency)
    /// - Parameter urls: Array of PDF file URLs
    /// - Returns: URL of the combined PDF
    /// - Throws: PDFError if combining fails
    func combineDocuments(urls: [URL]) throws -> URL {
        // Check if there are PDFs to combine
        guard !urls.isEmpty else {
            throw PDFError.noPDFsToProcess
        }
        
        // Create a new PDF document
        let combinedPDF = PDFDocument()
        
        // Update progress
        progressSubject.send(0.1)
        statusSubject.send(.processing(message: "Initializing..."))
        
        // Combine PDFs
        for (index, url) in urls.enumerated() {
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
            
            // Add pages from this PDF to the combined PDF
            for pageIndex in 0..<pdf.pageCount {
                if let page = pdf.page(at: pageIndex) {
                    combinedPDF.insert(page, at: combinedPDF.pageCount)
                }
            }
            
            // Update progress
            let progress = 0.1 + 0.8 * Double(index + 1) / Double(urls.count)
            progressSubject.send(progress)
            statusSubject.send(.processing(message: "Processing PDF \(index + 1) of \(urls.count)..."))
        }
        
        // Create a temporary file URL for the combined PDF
        let outputURL = tempFolder.appendingPathComponent("combined_\(UUID().uuidString).pdf")
        
        // Save the combined PDF
        if combinedPDF.write(to: outputURL) {
            progressSubject.send(1.0)
            statusSubject.send(.completed(message: "PDF combination complete"))
            return outputURL
        } else {
            throw PDFError.couldNotSavePDF
        }
    }
    
    /// Extract text from a PDF using OCR if needed
    /// - Parameters:
    ///   - url: URL of the PDF file
    ///   - useOCR: Whether to use OCR for scanned documents
    ///   - completion: Callback with the extracted text
    func extractText(from url: URL, useOCR: Bool = true, completion: @escaping (Result<String, Error>) -> Void) {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            completion(.failure(PDFError.fileNotFound(path: url.path)))
            return
        }
        
        // Check if file is a PDF
        guard url.pathExtension.lowercased() == "pdf" else {
            completion(.failure(PDFError.invalidFileType(expected: "pdf", actual: url.pathExtension)))
            return
        }
        
        // Load the PDF
        guard let pdf = PDFDocument(url: url) else {
            completion(.failure(PDFError.couldNotOpenPDF(path: url.path)))
            return
        }
        
        // Update progress
        progressSubject.send(0.1)
        statusSubject.send(.processing(message: "Initializing text extraction..."))
        
        // Extract text
        var extractedText = ""
        let totalPages = pdf.pageCount
        
        // Create a dispatch group to wait for all OCR operations
        let group = DispatchGroup()
        var ocrError: Error?
        
        // Process each page
        for pageIndex in 0..<totalPages {
            guard let page = pdf.page(at: pageIndex) else { continue }
            
            // Try to extract text directly
            if let pageText = page.string, !pageText.isEmpty {
                extractedText += pageText + "\n\n"
            } else if useOCR {
                // If no text is found, the page might be scanned or an image - use OCR
                group.enter()
                
                // Get page as image
                let pageImage = page.thumbnail(of: CGSize(width: 1024, height: 1024), for: .mediaBox)
                // Perform OCR on the image (no need to check for nil since thumbnail returns a direct UIImage)
                // Perform OCR
                performOCR(on: pageImage) { result in
                    switch result {
                    case .success(let text):
                        extractedText += text + "\n\n"
                    case .failure(let error):
                        ocrError = error
                    }
                    
                    group.leave()
                }
            }
            
            // Update progress
            let progress = 0.1 + 0.8 * Double(pageIndex + 1) / Double(totalPages)
            progressSubject.send(progress)
            statusSubject.send(.processing(message: "Extracting text from page \(pageIndex + 1) of \(totalPages)..."))
        }
        
        // Wait for all OCR operations to complete
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            if let error = ocrError {
                completion(.failure(error))
                return
            }
            
            self.progressSubject.send(1.0)
            self.statusSubject.send(.completed(message: "Text extraction complete"))
            completion(.success(extractedText))
        }
    }
    
    /// Extract specific pages from a PDF
    /// - Parameters:
    ///   - url: URL of the PDF file
    ///   - pageRanges: Ranges of pages to extract
    /// - Returns: URL of the new PDF with extracted pages
    /// - Throws: PDFError if extraction fails
    func extractPages(from url: URL, pageRanges: [ClosedRange<Int>]) throws -> URL {
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
        
        // Update progress
        progressSubject.send(0.1)
        statusSubject.send(.processing(message: "Initializing page extraction..."))
        
        // Create a new PDF document
        let extractedPDF = PDFDocument()
        
        // Process each page range
        for (index, range) in pageRanges.enumerated() {
            // Adjust range to be zero-based
            let adjustedRange = (range.lowerBound - 1)...(range.upperBound - 1)
            
            // Extract pages in the range
            for pageIndex in adjustedRange {
                // Check if page index is valid
                guard pageIndex >= 0 && pageIndex < pdf.pageCount else {
                    continue
                }
                
                // Extract page
                if let page = pdf.page(at: pageIndex) {
                    extractedPDF.insert(page, at: extractedPDF.pageCount)
                }
            }
            
            // Update progress
            let progress = 0.1 + 0.8 * Double(index + 1) / Double(pageRanges.count)
            self.progressSubject.send(progress)
            self.statusSubject.send(.processing(message: "Processing range \(index + 1) of \(pageRanges.count)..."))
        }
        
        // Check if any pages were extracted
        guard extractedPDF.pageCount > 0 else {
            throw PDFError.noValidPages
        }
        
        // Create a temporary file URL for the extracted PDF
        let outputURL = tempFolder.appendingPathComponent("extracted_\(UUID().uuidString).pdf")
        
        // Save the extracted PDF
        if extractedPDF.write(to: outputURL) {
            progressSubject.send(1.0)
            statusSubject.send(.completed(message: "Page extraction complete"))
            return outputURL
        } else {
            throw PDFError.couldNotSavePDF
        }
    }
    
    /// Add annotations to a PDF
    /// - Parameters:
    ///   - url: URL of the PDF file
    ///   - annotations: Array of annotations to add
    /// - Returns: URL of the annotated PDF
    /// - Throws: PDFError if annotation fails
    func addAnnotations(to url: URL, annotations: [PDFAnnotation]) throws -> URL {
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
        
        // Update progress
        progressSubject.send(0.1)
        statusSubject.send(.processing(message: "Initializing annotation..."))
        
        // Add annotations
        for (index, annotation) in annotations.enumerated() {
            // Get the page for this annotation
            guard let page = pdf.page(at: annotation.pageIndex) else {
                continue
            }
            
            // Add the annotation to the page
            page.addAnnotation(annotation.pdfAnnotation)
            
            // Update progress
            let progress = 0.1 + 0.8 * Double(index + 1) / Double(annotations.count)
            progressSubject.send(progress)
            statusSubject.send(.processing(message: "Adding annotation \(index + 1) of \(annotations.count)..."))
        }
        
        // Create a temporary file URL for the annotated PDF
        let outputURL = tempFolder.appendingPathComponent("annotated_\(UUID().uuidString).pdf")
        
        // Save the annotated PDF
        if pdf.write(to: outputURL) {
            progressSubject.send(1.0)
            statusSubject.send(.completed(message: "Annotation complete"))
            return outputURL
        } else {
            throw PDFError.couldNotSavePDF
        }
    }
    
    /// Split a PDF into multiple PDFs
    /// - Parameters:
    ///   - url: URL of the PDF file
    ///   - strategy: Splitting strategy
    /// - Returns: Array of URLs of the split PDFs
    /// - Throws: PDFError if splitting fails
    func splitPDF(url: URL, strategy: PDFSplitStrategy) throws -> [URL] {
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
        
        // Update progress
        progressSubject.send(0.1)
        statusSubject.send(.processing(message: "Initializing PDF splitting..."))
        
        // Split the PDF based on the strategy
        var outputURLs: [URL] = []
        
        switch strategy {
        case .byPage:
            // Create a separate PDF for each page
            for pageIndex in 0..<pdf.pageCount {
                // Create a new PDF for this page
                let singlePagePDF = PDFDocument()
                
                // Add the page
                if let page = pdf.page(at: pageIndex) {
                    singlePagePDF.insert(page, at: 0)
                    
                    // Save the page
                    let outputURL = tempFolder.appendingPathComponent("split_page\(pageIndex + 1)_\(UUID().uuidString).pdf")
                    
                    if singlePagePDF.write(to: outputURL) {
                        outputURLs.append(outputURL)
                    }
                }
                
                // Update progress
                let progress = 0.1 + 0.8 * Double(pageIndex + 1) / Double(pdf.pageCount)
                progressSubject.send(progress)
                statusSubject.send(.processing(message: "Processing page \(pageIndex + 1) of \(pdf.pageCount)..."))
            }
            
        case .byChunks(let chunkSize):
            // Create a PDF for each chunk of pages
            let chunks = (pdf.pageCount + chunkSize - 1) / chunkSize // Ceiling division
            
            for chunkIndex in 0..<chunks {
                // Create a new PDF for this chunk
                let chunkPDF = PDFDocument()
                
                // Start and end page indices for this chunk
                let startPage = chunkIndex * chunkSize
                let endPage = min(startPage + chunkSize - 1, pdf.pageCount - 1)
                
                // Add pages to the chunk
                for pageIndex in startPage...endPage {
                    if let page = pdf.page(at: pageIndex) {
                        chunkPDF.insert(page, at: chunkPDF.pageCount)
                    }
                }
                
                // Save the chunk
                let outputURL = tempFolder.appendingPathComponent("split_chunk\(chunkIndex + 1)_\(UUID().uuidString).pdf")
                
                if chunkPDF.write(to: outputURL) {
                    outputURLs.append(outputURL)
                }
                
                // Update progress
                let progress = 0.1 + 0.8 * Double(chunkIndex + 1) / Double(chunks)
                progressSubject.send(progress)
                statusSubject.send(.processing(message: "Processing chunk \(chunkIndex + 1) of \(chunks)..."))
            }
            
        case .byCustomRanges(let ranges):
            // Create a PDF for each custom range
            for (rangeIndex, range) in ranges.enumerated() {
                // Create a new PDF for this range
                let rangePDF = PDFDocument()
                
                // Adjust range to be zero-based
                let adjustedRange = (range.lowerBound - 1)...(range.upperBound - 1)
                
                // Add pages in the range
                for pageIndex in adjustedRange {
                    // Check if page index is valid
                    guard pageIndex >= 0 && pageIndex < pdf.pageCount else {
                        continue
                    }
                    
                    // Add page
                    if let page = pdf.page(at: pageIndex) {
                        rangePDF.insert(page, at: rangePDF.pageCount)
                    }
                }
                
                // Save the range
                let outputURL = tempFolder.appendingPathComponent("split_range\(rangeIndex + 1)_\(UUID().uuidString).pdf")
                
                if rangePDF.write(to: outputURL) {
                    outputURLs.append(outputURL)
                }
                
                // Update progress
                let progress = 0.1 + 0.8 * Double(rangeIndex + 1) / Double(ranges.count)
                progressSubject.send(progress)
                statusSubject.send(.processing(message: "Processing range \(rangeIndex + 1) of \(ranges.count)..."))
            }
        }
        
        // Check if any PDFs were created
        guard !outputURLs.isEmpty else {
            throw PDFError.splitFailed
        }
        
        progressSubject.send(1.0)
        statusSubject.send(.completed(message: "PDF splitting complete"))
        return outputURLs
    }
    
    /// Clean up temporary files
    func cleanupTempFiles() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: tempFolder,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Error cleaning up temporary files: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Perform OCR on an image
    /// - Parameters:
    ///   - image: Image to perform OCR on
    ///   - completion: Callback with the extracted text
    private func performOCR(on image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        // Create a Vision request
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(PDFError.ocrFailed))
                return
            }
            
            // Extract recognized text
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            completion(.success(recognizedText))
        }
        
        // Configure the request
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Create a request handler
        guard let cgImage = image.cgImage else {
            completion(.failure(PDFError.invalidImage))
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Perform the request
        do {
            try requestHandler.perform([request])
        } catch {
            completion(.failure(error))
        }
    }
}

// MARK: - PDF Annotation

/// Custom annotation for a PDF
struct PDFAnnotation {
    /// Page index (0-based)
    let pageIndex: Int
    
    /// PDFKit annotation
    let pdfAnnotation: PDFKit.PDFAnnotation
    
    /// Create a highlight annotation
    /// - Parameters:
    ///   - text: Text to highlight
    ///   - pageIndex: Page index (0-based)
    ///   - color: Highlight color
    /// - Returns: PDFAnnotation
    static func highlight(text: String, pageIndex: Int, color: UIColor = .yellow) -> PDFAnnotation {
        let highlight = PDFKit.PDFAnnotation(
            bounds: CGRect(x: 0, y: 0, width: 100, height: 100),
            forType: .highlight,
            withProperties: nil
        )
        
        highlight.color = color
        
        return PDFAnnotation(pageIndex: pageIndex, pdfAnnotation: highlight)
    }
    
    /// Create a text annotation
    /// - Parameters:
    ///   - contents: Annotation contents
    ///   - pageIndex: Page index (0-based)
    ///   - rect: Rectangle for the annotation
    /// - Returns: PDFAnnotation
    static func text(contents: String, pageIndex: Int, rect: CGRect) -> PDFAnnotation {
        let text = PDFKit.PDFAnnotation(
            bounds: rect,
            forType: .text,
            withProperties: nil
        )
        
        text.contents = contents
        
        return PDFAnnotation(pageIndex: pageIndex, pdfAnnotation: text)
    }
    
    /// Create a link annotation
    /// - Parameters:
    ///   - url: URL to link to
    ///   - pageIndex: Page index (0-based)
    ///   - rect: Rectangle for the annotation
    /// - Returns: PDFAnnotation
    static func link(url: URL, pageIndex: Int, rect: CGRect) -> PDFAnnotation {
        let link = PDFKit.PDFAnnotation(
            bounds: rect,
            forType: .link,
            withProperties: nil
        )
        
        link.action = PDFActionURL(url: url)
        
        return PDFAnnotation(pageIndex: pageIndex, pdfAnnotation: link)
    }
}

// MARK: - PDF Split Strategies

/// Strategy for splitting a PDF
enum PDFSplitStrategy {
    /// Split by individual pages
    case byPage
    
    /// Split by chunks of pages
    case byChunks(chunkSize: Int)
    
    /// Split by custom page ranges
    case byCustomRanges(ranges: [ClosedRange<Int>])
}

// MARK: - PDF Processing Status

/// Status of PDF processing
enum PDFProcessingStatus {
    /// Processing is in progress
    case processing(message: String)
    
    /// Processing is complete
    case completed(message: String)
}

// MARK: - PDF Errors

/// Errors that can occur during PDF processing
enum PDFError: Error, LocalizedError {
    /// File not found
    case fileNotFound(path: String)
    
    /// Invalid file type
    case invalidFileType(expected: String, actual: String)
    
    /// Could not open PDF
    case couldNotOpenPDF(path: String)
    
    /// Could not save PDF
    case couldNotSavePDF
    
    /// No PDFs to process
    case noPDFsToProcess
    
    /// No valid pages
    case noValidPages
    
    /// OCR failed
    case ocrFailed
    
    /// Invalid image for OCR
    case invalidImage
    
    /// PDF splitting failed
    case splitFailed
    
    /// Error description
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidFileType(let expected, let actual):
            return "Invalid file type: expected \(expected), got \(actual)"
        case .couldNotOpenPDF(let path):
            return "Could not open PDF: \(path)"
        case .couldNotSavePDF:
            return "Could not save PDF"
        case .noPDFsToProcess:
            return "No PDFs to process"
        case .noValidPages:
            return "No valid pages in the PDF"
        case .ocrFailed:
            return "OCR failed"
        case .invalidImage:
            return "Invalid image for OCR"
        case .splitFailed:
            return "PDF splitting failed"
        }
    }
}
