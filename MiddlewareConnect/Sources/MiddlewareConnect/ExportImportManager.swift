import Foundation
#if canImport(UIKit)
#if canImport(UIKit)
import UIKit
#endif
#endif
import PDFKit
import ZIPFoundation

/// Manager for handling export and import operations
class ExportImportManager {
    // MARK: - Singleton
    
    /// Shared instance
    static let shared = ExportImportManager()
    
    // MARK: - Properties
    
    /// The file manager
    private let fileManager = FileManager.shared
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer to enforce singleton pattern
    }
    
    // MARK: - Export Operations
    
    /// Exports a text file
    /// - Parameters:
    ///   - text: The text to export
    ///   - fileName: The name of the file
    ///   - format: The format of the file
    /// - Returns: The URL of the exported file, or nil if the file could not be exported
    func exportText(_ text: String, as fileName: String, format: TextFileFormat) -> URL? {
        // Create the file name with the appropriate extension
        let fileNameWithExtension = fileName.hasSuffix(".\(format.rawValue)") ? fileName : "\(fileName).\(format.rawValue)"
        
        // Convert the text to data
        guard let data = text.data(using: .utf8) else {
            return nil
        }
        
        // Save the file
        return fileManager.saveFile(data: data, fileName: fileNameWithExtension, in: .exports)
    }
    
    /// Exports a PDF file
    /// - Parameters:
    ///   - pdfDocument: The PDF document to export
    ///   - fileName: The name of the file
    /// - Returns: The URL of the exported file, or nil if the file could not be exported
    func exportPDF(_ pdfDocument: PDFDocument, as fileName: String) -> URL? {
        // Create the file name with the appropriate extension
        let fileNameWithExtension = fileName.hasSuffix(".pdf") ? fileName : "\(fileName).pdf"
        
        // Create a temporary URL
        let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileNameWithExtension)
        
        // Save the PDF to the temporary URL
        if pdfDocument.write(to: temporaryURL) {
            // Import the file to the exports directory
            return fileManager.importFile(from: temporaryURL, to: .exports)
        }
        
        return nil
    }
    
    /// Exports a CSV file
    /// - Parameters:
    ///   - csvString: The CSV string to export
    ///   - fileName: The name of the file
    /// - Returns: The URL of the exported file, or nil if the file could not be exported
    func exportCSV(_ csvString: String, as fileName: String) -> URL? {
        // Create the file name with the appropriate extension
        let fileNameWithExtension = fileName.hasSuffix(".csv") ? fileName : "\(fileName).csv"
        
        // Convert the CSV string to data
        guard let data = csvString.data(using: .utf8) else {
            return nil
        }
        
        // Save the file
        return fileManager.saveFile(data: data, fileName: fileNameWithExtension, in: .exports)
    }
    
    /// Exports an image
    /// - Parameters:
    ///   - image: The image to export
    ///   - fileName: The name of the file
    ///   - format: The format of the image
    /// - Returns: The URL of the exported file, or nil if the file could not be exported
    func exportImage(_ image: UIImage, as fileName: String, format: ImageFileFormat) -> URL? {
        // Create the file name with the appropriate extension
        let fileNameWithExtension = fileName.hasSuffix(".\(format.rawValue)") ? fileName : "\(fileName).\(format.rawValue)"
        
        // Convert the image to data
        var imageData: Data?
        
        switch format {
        case .png:
            imageData = image.pngData()
        case .jpeg:
            imageData = image.jpegData(compressionQuality: 0.8)
        }
        
        guard let data = imageData else {
            return nil
        }
        
        // Save the file
        return fileManager.saveFile(data: data, fileName: fileNameWithExtension, in: .exports)
    }
    
    /// Exports multiple files as a ZIP archive
    /// - Parameters:
    ///   - fileURLs: The URLs of the files to export
    ///   - fileName: The name of the ZIP file
    /// - Returns: The URL of the exported ZIP file, or nil if the file could not be exported
    func exportFilesAsZIP(_ fileURLs: [URL], as fileName: String) -> URL? {
        // Create the file name with the appropriate extension
        let fileNameWithExtension = fileName.hasSuffix(".zip") ? fileName : "\(fileName).zip"
        
        // Create a temporary URL for the ZIP file
        let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileNameWithExtension)
        
        // Remove the ZIP file if it already exists
        if Foundation.FileManager.default.fileExists(atPath: temporaryURL.path) {
            do {
                try Foundation.FileManager.default.removeItem(at: temporaryURL)
            } catch {
                print("Error removing existing ZIP file: \(error)")
                return nil
            }
        }
        
        // Create the ZIP file
        guard let archive = Archive(url: temporaryURL, accessMode: .create) else {
            return nil
        }
        
        // Add each file to the ZIP archive
        for fileURL in fileURLs {
            do {
                try archive.addEntry(with: fileURL.lastPathComponent, fileURL: fileURL)
            } catch {
                print("Error adding file to ZIP archive: \(error)")
                return nil
            }
        }
        
        // Import the ZIP file to the exports directory
        return fileManager.importFile(from: temporaryURL, to: .exports)
    }
    
    /// Shares a file
    /// - Parameter fileURL: The URL of the file to share
    /// - Returns: A UIActivityViewController for sharing the file
    func shareFile(at fileURL: URL) -> UIActivityViewController? {
        guard Foundation.FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        return activityViewController
    }
    
    // MARK: - Import Operations
    
    /// Imports a text file
    /// - Parameter fileURL: The URL of the file to import
    /// - Returns: The text content of the file, or nil if the file could not be imported
    func importTextFile(from fileURL: URL) -> String? {
        do {
            let data = try Data(contentsOf: fileURL)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error importing text file: \(error)")
            return nil
        }
    }
    
    /// Imports a PDF file
    /// - Parameter fileURL: The URL of the file to import
    /// - Returns: The PDF document, or nil if the file could not be imported
    func importPDFFile(from fileURL: URL) -> PDFDocument? {
        return PDFDocument(url: fileURL)
    }
    
    /// Imports a CSV file
    /// - Parameter fileURL: The URL of the file to import
    /// - Returns: The CSV content as a string, or nil if the file could not be imported
    func importCSVFile(from fileURL: URL) -> String? {
        do {
            let data = try Data(contentsOf: fileURL)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error importing CSV file: \(error)")
            return nil
        }
    }
    
    /// Imports an image file
    /// - Parameter fileURL: The URL of the file to import
    /// - Returns: The image, or nil if the file could not be imported
    func importImageFile(from fileURL: URL) -> UIImage? {
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    /// Imports a ZIP file
    /// - Parameter fileURL: The URL of the file to import
    /// - Returns: The URLs of the extracted files, or nil if the file could not be imported
    func importZIPFile(from fileURL: URL) -> [URL]? {
        // Create a temporary directory for extraction
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        
        do {
            // Create the temporary directory
            try Foundation.FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            
            // Open the ZIP archive
            guard let archive = Archive(url: fileURL, accessMode: .read) else {
                return nil
            }
            
            var extractedFileURLs: [URL] = []
            
            // Extract each entry in the archive
            for entry in archive {
                let entryURL = temporaryDirectoryURL.appendingPathComponent(entry.path)
                
                do {
                    // Create the directory structure if needed
                    if entry.path.contains("/") {
                        let directoryURL = entryURL.deletingLastPathComponent()
                        try Foundation.FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                    }
                    
                    // Extract the entry
                    _ = try archive.extract(entry, to: entryURL)
                    
                    // Add the extracted file URL to the list
                    extractedFileURLs.append(entryURL)
                } catch {
                    print("Error extracting entry \(entry.path): \(error)")
                }
            }
            
            return extractedFileURLs
        } catch {
            print("Error creating temporary directory: \(error)")
            return nil
        }
    }
    
    /// Determines the type of a file
    /// - Parameter fileURL: The URL of the file
    /// - Returns: The file type
    func determineFileType(for fileURL: URL) -> FileType {
        let fileExtension = fileURL.pathExtension.lowercased()
        
        switch fileExtension {
        case "txt":
            return .text(.txt)
        case "md":
            return .text(.markdown)
        case "pdf":
            return .pdf
        case "csv":
            return .csv
        case "jpg", "jpeg":
            return .image(.jpeg)
        case "png":
            return .image(.png)
        case "zip":
            return .zip
        default:
            return .unknown
        }
    }
    
    /// Imports a file and saves it to the appropriate directory
    /// - Parameter fileURL: The URL of the file to import
    /// - Returns: The URL of the imported file, or nil if the file could not be imported
    func importFile(from fileURL: URL) -> URL? {
        let fileType = determineFileType(for: fileURL)
        
        // Determine the directory based on the file type
        let directory: DirectoryType
        
        switch fileType {
        case .text:
            directory = .text
        case .pdf:
            directory = .pdf
        case .csv:
            directory = .csv
        case .image:
            directory = .images
        case .zip, .unknown:
            directory = .documents
        }
        
        // Import the file
        return fileManager.importFile(from: fileURL, to: directory)
    }
    
    /// Imports multiple files and saves them to the appropriate directories
    /// - Parameter fileURLs: The URLs of the files to import
    /// - Returns: The URLs of the imported files
    func importFiles(from fileURLs: [URL]) -> [URL] {
        var importedFileURLs: [URL] = []
        
        for fileURL in fileURLs {
            if let importedFileURL = importFile(from: fileURL) {
                importedFileURLs.append(importedFileURL)
            }
        }
        
        return importedFileURLs
    }
    
    /// Processes a batch of files
    /// - Parameters:
    ///   - fileURLs: The URLs of the files to process
    ///   - processor: The processor function
    /// - Returns: The URLs of the processed files
    func processBatch<T>(files fileURLs: [URL], processor: (URL) -> T?) -> [T] {
        var processedFiles: [T] = []
        
        for fileURL in fileURLs {
            if let processedFile = processor(fileURL) {
                processedFiles.append(processedFile)
            }
        }
        
        return processedFiles
    }
}

// MARK: - File Types

/// The type of a file
enum FileType {
    /// A text file
    case text(TextFileFormat)
    
    /// A PDF file
    case pdf
    
    /// A CSV file
    case csv
    
    /// An image file
    case image(ImageFileFormat)
    
    /// A ZIP file
    case zip
    
    /// An unknown file type
    case unknown
}

/// The format of a text file
enum TextFileFormat: String {
    /// A plain text file
    case txt
    
    /// A Markdown file
    case markdown = "md"
}

/// The format of an image file
enum ImageFileFormat: String {
    /// A PNG image
    case png
    
    /// A JPEG image
    case jpeg = "jpg"
}
