import Foundation
#if canImport(UIKit)
#if canImport(UIKit)
import UIKit
#endif
#endif

/// Manager for handling file operations
class FileManager {
    // MARK: - Singleton
    
    /// Shared instance
    static let shared = FileManager()
    
    // MARK: - Properties
    
    /// The system file manager
    private let fileManager = Foundation.FileManager.default
    
    /// The documents directory URL
    private let documentsDirectory: URL
    
    /// The temporary directory URL
    private let temporaryDirectory: URL
    
    /// The cache directory URL
    private let cacheDirectory: URL
    
    /// The application support directory URL
    private let applicationSupportDirectory: URL
    
    // MARK: - Initialization
    
    private init() {
        // Get the documents directory
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Get the temporary directory
        temporaryDirectory = fileManager.temporaryDirectory
        
        // Get the cache directory
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        // Get the application support directory
        applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        // Create the necessary directories
        createDirectories()
    }
    
    // MARK: - Directory Management
    
    /// Creates the necessary directories
    private func createDirectories() {
        // Create the application support directory if it doesn't exist
        if !fileManager.fileExists(atPath: applicationSupportDirectory.path) {
            do {
                try fileManager.createDirectory(at: applicationSupportDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating application support directory: \(error)")
            }
        }
        
        // Create the documents subdirectories
        let subdirectories = ["Text", "PDF", "CSV", "Images", "Exports"]
        
        for subdirectory in subdirectories {
            let directoryURL = documentsDirectory.appendingPathComponent(subdirectory)
            
            if !fileManager.fileExists(atPath: directoryURL.path) {
                do {
                    try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Error creating directory \(subdirectory): \(error)")
                }
            }
        }
    }
    
    /// Gets the URL for a directory
    /// - Parameter directory: The directory type
    /// - Returns: The URL for the directory
    func getDirectoryURL(for directory: DirectoryType) -> URL {
        switch directory {
        case .documents:
            return documentsDirectory
        case .temporary:
            return temporaryDirectory
        case .cache:
            return cacheDirectory
        case .applicationSupport:
            return applicationSupportDirectory
        case .text:
            return documentsDirectory.appendingPathComponent("Text")
        case .pdf:
            return documentsDirectory.appendingPathComponent("PDF")
        case .csv:
            return documentsDirectory.appendingPathComponent("CSV")
        case .images:
            return documentsDirectory.appendingPathComponent("Images")
        case .exports:
            return documentsDirectory.appendingPathComponent("Exports")
        }
    }
    
    // MARK: - File Operations
    
    /// Saves data to a file
    /// - Parameters:
    ///   - data: The data to save
    ///   - fileName: The name of the file
    ///   - directory: The directory to save the file in
    /// - Returns: The URL of the saved file, or nil if the file could not be saved
    func saveFile(data: Data, fileName: String, in directory: DirectoryType) -> URL? {
        let fileURL = getDirectoryURL(for: directory).appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving file: \(error)")
            return nil
        }
    }
    
    /// Reads data from a file
    /// - Parameters:
    ///   - fileName: The name of the file
    ///   - directory: The directory to read the file from
    /// - Returns: The data from the file, or nil if the file could not be read
    func readFile(fileName: String, from directory: DirectoryType) -> Data? {
        let fileURL = getDirectoryURL(for: directory).appendingPathComponent(fileName)
        
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            print("Error reading file: \(error)")
            return nil
        }
    }
    
    /// Deletes a file
    /// - Parameters:
    ///   - fileName: The name of the file
    ///   - directory: The directory to delete the file from
    /// - Returns: True if the file was deleted successfully, false otherwise
    func deleteFile(fileName: String, from directory: DirectoryType) -> Bool {
        let fileURL = getDirectoryURL(for: directory).appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: fileURL)
            return true
        } catch {
            print("Error deleting file: \(error)")
            return false
        }
    }
    
    /// Copies a file
    /// - Parameters:
    ///   - sourceFileName: The name of the source file
    ///   - sourceDirectory: The directory of the source file
    ///   - destinationFileName: The name of the destination file
    ///   - destinationDirectory: The directory of the destination file
    /// - Returns: The URL of the copied file, or nil if the file could not be copied
    func copyFile(sourceFileName: String, from sourceDirectory: DirectoryType, to destinationFileName: String, in destinationDirectory: DirectoryType) -> URL? {
        let sourceURL = getDirectoryURL(for: sourceDirectory).appendingPathComponent(sourceFileName)
        let destinationURL = getDirectoryURL(for: destinationDirectory).appendingPathComponent(destinationFileName)
        
        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Error copying file: \(error)")
            return nil
        }
    }
    
    /// Moves a file
    /// - Parameters:
    ///   - sourceFileName: The name of the source file
    ///   - sourceDirectory: The directory of the source file
    ///   - destinationFileName: The name of the destination file
    ///   - destinationDirectory: The directory of the destination file
    /// - Returns: The URL of the moved file, or nil if the file could not be moved
    func moveFile(sourceFileName: String, from sourceDirectory: DirectoryType, to destinationFileName: String, in destinationDirectory: DirectoryType) -> URL? {
        let sourceURL = getDirectoryURL(for: sourceDirectory).appendingPathComponent(sourceFileName)
        let destinationURL = getDirectoryURL(for: destinationDirectory).appendingPathComponent(destinationFileName)
        
        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Error moving file: \(error)")
            return nil
        }
    }
    
    /// Renames a file
    /// - Parameters:
    ///   - fileName: The name of the file
    ///   - directory: The directory of the file
    ///   - newFileName: The new name of the file
    /// - Returns: The URL of the renamed file, or nil if the file could not be renamed
    func renameFile(fileName: String, in directory: DirectoryType, to newFileName: String) -> URL? {
        let fileURL = getDirectoryURL(for: directory).appendingPathComponent(fileName)
        let newFileURL = getDirectoryURL(for: directory).appendingPathComponent(newFileName)
        
        do {
            try fileManager.moveItem(at: fileURL, to: newFileURL)
            return newFileURL
        } catch {
            print("Error renaming file: \(error)")
            return nil
        }
    }
    
    /// Checks if a file exists
    /// - Parameters:
    ///   - fileName: The name of the file
    ///   - directory: The directory of the file
    /// - Returns: True if the file exists, false otherwise
    func fileExists(fileName: String, in directory: DirectoryType) -> Bool {
        let fileURL = getDirectoryURL(for: directory).appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Gets the attributes of a file
    /// - Parameters:
    ///   - fileName: The name of the file
    ///   - directory: The directory of the file
    /// - Returns: The attributes of the file, or nil if the attributes could not be retrieved
    func getFileAttributes(fileName: String, in directory: DirectoryType) -> FileAttributes? {
        let fileURL = getDirectoryURL(for: directory).appendingPathComponent(fileName)
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            
            guard let size = attributes[.size] as? Int64,
                  let creationDate = attributes[.creationDate] as? Date,
                  let modificationDate = attributes[.modificationDate] as? Date else {
                return nil
            }
            
            return FileAttributes(
                size: size,
                creationDate: creationDate,
                modificationDate: modificationDate
            )
        } catch {
            print("Error getting file attributes: \(error)")
            return nil
        }
    }
    
    /// Lists the files in a directory
    /// - Parameter directory: The directory to list the files from
    /// - Returns: The files in the directory, or nil if the files could not be listed
    func listFiles(in directory: DirectoryType) -> [FileInfo]? {
        let directoryURL = getDirectoryURL(for: directory)
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.nameKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey], options: .skipsHiddenFiles)
            
            return fileURLs.compactMap { fileURL in
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.nameKey, .fileSizeKey, .creationDateKey, .contentModificationDateKey])
                    
                    guard let name = resourceValues.name,
                          let size = resourceValues.fileSize,
                          let creationDate = resourceValues.creationDate,
                          let modificationDate = resourceValues.contentModificationDate else {
                        return nil
                    }
                    
                    return FileInfo(
                        name: name,
                        url: fileURL,
                        size: Int64(size),
                        creationDate: creationDate,
                        modificationDate: modificationDate
                    )
                } catch {
                    print("Error getting resource values: \(error)")
                    return nil
                }
            }
        } catch {
            print("Error listing files: \(error)")
            return nil
        }
    }
    
    /// Creates a thumbnail for a file
    /// - Parameters:
    ///   - fileName: The name of the file
    ///   - directory: The directory of the file
    ///   - size: The size of the thumbnail
    /// - Returns: The thumbnail image, or nil if the thumbnail could not be created
    func createThumbnail(for fileName: String, in directory: DirectoryType, size: CGSize) -> UIImage? {
        let fileURL = getDirectoryURL(for: directory).appendingPathComponent(fileName)
        let fileExtension = fileURL.pathExtension.lowercased()
        
        // Create a thumbnail based on the file type
        switch fileExtension {
        case "pdf":
            return createPDFThumbnail(for: fileURL, size: size)
        case "jpg", "jpeg", "png", "gif":
            return createImageThumbnail(for: fileURL, size: size)
        case "csv":
            return createGenericThumbnail(for: "doc.text.fill", size: size)
        case "txt", "md":
            return createGenericThumbnail(for: "doc.plaintext.fill", size: size)
        default:
            return createGenericThumbnail(for: "doc.fill", size: size)
        }
    }
    
    /// Creates a thumbnail for a PDF file
    /// - Parameters:
    ///   - fileURL: The URL of the PDF file
    ///   - size: The size of the thumbnail
    /// - Returns: The thumbnail image, or nil if the thumbnail could not be created
    private func createPDFThumbnail(for fileURL: URL, size: CGSize) -> UIImage? {
        guard let pdfDocument = CGPDFDocument(fileURL as CFURL) else {
            return createGenericThumbnail(for: "doc.text.fill", size: size)
        }
        
        guard let page = pdfDocument.page(at: 1) else {
            return createGenericThumbnail(for: "doc.text.fill", size: size)
        }
        
        let pageRect = page.getBoxRect(.mediaBox)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            context.cgContext.translateBy(x: 0, y: size.height)
            context.cgContext.scaleBy(x: 1, y: -1)
            
            let scale = min(size.width / pageRect.width, size.height / pageRect.height)
            context.cgContext.scaleBy(x: scale, y: scale)
            
            context.cgContext.drawPDFPage(page)
        }
        
        return image
    }
    
    /// Creates a thumbnail for an image file
    /// - Parameters:
    ///   - fileURL: The URL of the image file
    ///   - size: The size of the thumbnail
    /// - Returns: The thumbnail image, or nil if the thumbnail could not be created
    private func createImageThumbnail(for fileURL: URL, size: CGSize) -> UIImage? {
        guard let image = UIImage(contentsOfFile: fileURL.path) else {
            return createGenericThumbnail(for: "photo.fill", size: size)
        }
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            UIColor.white.setFill()
            context.fill(rect)
            
            let aspectRatio = image.size.width / image.size.height
            var drawRect = rect
            
            if aspectRatio > 1 {
                // Landscape image
                drawRect.size.height = drawRect.size.width / aspectRatio
                drawRect.origin.y = (size.height - drawRect.size.height) / 2
            } else {
                // Portrait image
                drawRect.size.width = drawRect.size.height * aspectRatio
                drawRect.origin.x = (size.width - drawRect.size.width) / 2
            }
            
            image.draw(in: drawRect)
        }
    }
    
    /// Creates a generic thumbnail with a system icon
    /// - Parameters:
    ///   - systemName: The name of the system icon
    ///   - size: The size of the thumbnail
    /// - Returns: The thumbnail image
    private func createGenericThumbnail(for systemName: String, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            UIColor.white.setFill()
            context.fill(rect)
            
            if let iconImage = UIImage(systemName: systemName) {
                let iconSize = min(size.width, size.height) * 0.6
                let iconRect = CGRect(
                    x: (size.width - iconSize) / 2,
                    y: (size.height - iconSize) / 2,
                    width: iconSize,
                    height: iconSize
                )
                
                iconImage.withTintColor(.systemBlue).draw(in: iconRect)
            }
        }
    }
    
    // MARK: - Import/Export
    
    /// Imports a file from a URL
    /// - Parameters:
    ///   - sourceURL: The URL of the file to import
    ///   - directory: The directory to import the file to
    /// - Returns: The URL of the imported file, or nil if the file could not be imported
    func importFile(from sourceURL: URL, to directory: DirectoryType) -> URL? {
        let fileName = sourceURL.lastPathComponent
        let destinationURL = getDirectoryURL(for: directory).appendingPathComponent(fileName)
        
        do {
            // If the file already exists, remove it
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // Copy the file
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Error importing file: \(error)")
            return nil
        }
    }
    
    /// Exports a file to a URL
    /// - Parameters:
    ///   - fileName: The name of the file to export
    ///   - directory: The directory of the file to export
    ///   - destinationURL: The URL to export the file to
    /// - Returns: True if the file was exported successfully, false otherwise
    func exportFile(fileName: String, from directory: DirectoryType, to destinationURL: URL) -> Bool {
        let sourceURL = getDirectoryURL(for: directory).appendingPathComponent(fileName)
        
        do {
            // If the file already exists, remove it
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            // Copy the file
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return true
        } catch {
            print("Error exporting file: \(error)")
            return false
        }
    }
    
    /// Shares a file
    /// - Parameters:
    ///   - fileName: The name of the file to share
    ///   - directory: The directory of the file to share
    /// - Returns: A UIActivityViewController for sharing the file
    func shareFile(fileName: String, from directory: DirectoryType) -> UIActivityViewController? {
        let fileURL = getDirectoryURL(for: directory).appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        return activityViewController
    }
}

// MARK: - Directory Type

/// The type of directory
enum DirectoryType {
    /// The documents directory
    case documents
    
    /// The temporary directory
    case temporary
    
    /// The cache directory
    case cache
    
    /// The application support directory
    case applicationSupport
    
    /// The text directory
    case text
    
    /// The PDF directory
    case pdf
    
    /// The CSV directory
    case csv
    
    /// The images directory
    case images
    
    /// The exports directory
    case exports
}

// MARK: - File Attributes

/// Attributes of a file
struct FileAttributes {
    /// The size of the file in bytes
    let size: Int64
    
    /// The date the file was created
    let creationDate: Date
    
    /// The date the file was last modified
    let modificationDate: Date
    
    /// The formatted size of the file
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - File Info

/// Information about a file
struct FileInfo {
    /// The name of the file
    let name: String
    
    /// The URL of the file
    let url: URL
    
    /// The size of the file in bytes
    let size: Int64
    
    /// The date the file was created
    let creationDate: Date
    
    /// The date the file was last modified
    let modificationDate: Date
    
    /// The formatted size of the file
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    /// The file extension
    var fileExtension: String {
        url.pathExtension
    }
}
