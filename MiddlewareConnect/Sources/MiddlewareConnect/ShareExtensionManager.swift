import Foundation
#if canImport(UIKit)
#if canImport(UIKit)
import UIKit
#endif
#endif
import UniformTypeIdentifiers

/// Manager for handling share extension functionality
class ShareExtensionManager {
    // MARK: - Singleton
    
    /// Shared instance
    static let shared = ShareExtensionManager()
    
    // MARK: - Properties
    
    /// The app group identifier for sharing data between the main app and extensions
    private let appGroupIdentifier = "group.com.yourcompany.llmbuddy"
    
    /// The URL for the shared container
    private var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    /// The URL for the shared data file
    private var sharedDataURL: URL? {
        sharedContainerURL?.appendingPathComponent("SharedExtensionData.json")
    }
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer to enforce singleton pattern
    }
    
    // MARK: - Public Methods
    
    /// Checks if there is shared content from the extension
    /// - Returns: True if there is shared content, false otherwise
    func hasSharedContent() -> Bool {
        guard let sharedDataURL = sharedDataURL else { return false }
        return FileManager.default.fileExists(atPath: sharedDataURL.path)
    }
    
    /// Gets the shared content from the extension
    /// - Returns: The shared content, or nil if there is none
    func getSharedContent() -> SharedContent? {
        guard let sharedDataURL = sharedDataURL,
              FileManager.default.fileExists(atPath: sharedDataURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: sharedDataURL)
            let decoder = JSONDecoder()
            let sharedContent = try decoder.decode(SharedContent.self, from: data)
            
            // Clear the shared content after reading it
            try FileManager.default.removeItem(at: sharedDataURL)
            
            return sharedContent
        } catch {
            print("Error reading shared content: \(error)")
            return nil
        }
    }
    
    /// Saves shared content from the extension
    /// - Parameter content: The content to save
    /// - Returns: True if the content was saved successfully, false otherwise
    func saveSharedContent(_ content: SharedContent) -> Bool {
        guard let sharedDataURL = sharedDataURL else { return false }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(content)
            try data.write(to: sharedDataURL)
            return true
        } catch {
            print("Error saving shared content: \(error)")
            return false
        }
    }
    
    /// Gets the URL for a shared file
    /// - Parameter filename: The name of the file
    /// - Returns: The URL for the file
    func getSharedFileURL(filename: String) -> URL? {
        sharedContainerURL?.appendingPathComponent(filename)
    }
    
    /// Saves a file to the shared container
    /// - Parameters:
    ///   - url: The URL of the file to save
    ///   - filename: The name to save the file as
    /// - Returns: The URL of the saved file, or nil if the file could not be saved
    func saveSharedFile(from url: URL, as filename: String) -> URL? {
        guard let destinationURL = getSharedFileURL(filename: filename) else { return nil }
        
        do {
            // If the file already exists, remove it
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Copy the file
            try FileManager.default.copyItem(at: url, to: destinationURL)
            return destinationURL
        } catch {
            print("Error saving shared file: \(error)")
            return nil
        }
    }
    
    /// Removes a file from the shared container
    /// - Parameter filename: The name of the file to remove
    /// - Returns: True if the file was removed successfully, false otherwise
    func removeSharedFile(filename: String) -> Bool {
        guard let fileURL = getSharedFileURL(filename: filename),
              FileManager.default.fileExists(atPath: fileURL.path) else {
            return false
        }
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            print("Error removing shared file: \(error)")
            return false
        }
    }
    
    /// Gets the suggested tool for the shared content
    /// - Parameter content: The shared content
    /// - Returns: The suggested tool
    func suggestedTool(for content: SharedContent) -> SuggestedTool {
        switch content.contentType {
        case .text:
            if content.text?.contains("```") == true || content.text?.contains("#") == true {
                return .markdownConverter
            } else {
                return .textChunker
            }
        case .url:
            return .documentSummarizer
        case .image:
            return .imageSplitter
        case .pdf:
            return .pdfSplitter
        case .csv:
            return .csvFormatter
        }
    }
}

// MARK: - Models

/// The type of content shared through the extension
enum SharedContentType: String, Codable {
    case text
    case url
    case image
    case pdf
    case csv
}

/// The suggested tool for the shared content
enum SuggestedTool: String, Codable {
    case textChunker
    case textCleaner
    case markdownConverter
    case documentSummarizer
    case pdfCombiner
    case pdfSplitter
    case csvFormatter
    case imageSplitter
    case tokenCostCalculator
    case contextWindowVisualizer
}

/// Content shared through the extension
struct SharedContent: Codable {
    /// The type of content
    let contentType: SharedContentType
    
    /// The text content (if applicable)
    let text: String?
    
    /// The URL content (if applicable)
    let url: URL?
    
    /// The filename for file content (if applicable)
    let filename: String?
    
    /// The UTType identifier for file content (if applicable)
    let typeIdentifier: String?
    
    /// Creates a new instance with text content
    /// - Parameter text: The text content
    /// - Returns: A new instance with text content
    static func withText(_ text: String) -> SharedContent {
        SharedContent(
            contentType: .text,
            text: text,
            url: nil,
            filename: nil,
            typeIdentifier: nil
        )
    }
    
    /// Creates a new instance with URL content
    /// - Parameter url: The URL content
    /// - Returns: A new instance with URL content
    static func withURL(_ url: URL) -> SharedContent {
        SharedContent(
            contentType: .url,
            text: nil,
            url: url,
            filename: nil,
            typeIdentifier: nil
        )
    }
    
    /// Creates a new instance with file content
    /// - Parameters:
    ///   - url: The URL of the file
    ///   - filename: The filename
    ///   - typeIdentifier: The UTType identifier
    /// - Returns: A new instance with file content
    static func withFile(url: URL, filename: String, typeIdentifier: String) -> SharedContent {
        let contentType: SharedContentType
        
        if typeIdentifier.contains("pdf") {
            contentType = .pdf
        } else if typeIdentifier.contains("image") {
            contentType = .image
        } else if typeIdentifier.contains("csv") || typeIdentifier.contains("comma-separated-values") {
            contentType = .csv
        } else {
            contentType = .text
        }
        
        return SharedContent(
            contentType: contentType,
            text: nil,
            url: url,
            filename: filename,
            typeIdentifier: typeIdentifier
        )
    }
}

// MARK: - Share Extension View Controller

/// View controller for the share extension
class ShareExtensionViewController: UIViewController {
    // MARK: - Properties
    
    /// The content items from the extension context
    private var contentItems: [NSExtensionItem] = []
    
    /// The completion handler for the extension
    private var completionHandler: (() -> Void)?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setupUI()
        
        // Process the shared content
        processSharedContent()
    }
    
    // MARK: - Private Methods
    
    /// Sets up the UI
    private func setupUI() {
        // Set up the view
        view.backgroundColor = .systemBackground
        
        // Add a loading indicator
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Add a label
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Processing..."
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16)
        ])
    }
    
    /// Processes the shared content
    private func processSharedContent() {
        // Get the extension context
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            completeExtension()
            return
        }
        
        // Store the content items
        contentItems = inputItems
        
        // Process each item
        let group = DispatchGroup()
        
        for item in contentItems {
            guard let attachments = item.attachments else { continue }
            
            for attachment in attachments {
                group.enter()
                
                // Process the attachment
                processAttachment(attachment) { _ in
                    group.leave()
                }
            }
        }
        
        // When all attachments have been processed
        group.notify(queue: .main) { [weak self] in
            self?.completeExtension()
        }
    }
    
    /// Processes an attachment
    /// - Parameters:
    ///   - attachment: The attachment to process
    ///   - completion: The completion handler
    private func processAttachment(_ attachment: NSItemProvider, completion: @escaping (Bool) -> Void) {
        // Check for text
        if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] (item, error) in
                guard let text = item as? String else {
                    completion(false)
                    return
                }
                
                // Save the text
                let sharedContent = SharedContent.withText(text)
                let success = ShareExtensionManager.shared.saveSharedContent(sharedContent)
                completion(success)
            }
            return
        }
        
        // Check for URL
        if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
                guard let url = item as? URL else {
                    completion(false)
                    return
                }
                
                // Save the URL
                let sharedContent = SharedContent.withURL(url)
                let success = ShareExtensionManager.shared.saveSharedContent(sharedContent)
                completion(success)
            }
            return
        }
        
        // Check for files
        let supportedTypes = [
            UTType.pdf.identifier,
            UTType.image.identifier,
            UTType.jpeg.identifier,
            UTType.png.identifier,
            UTType.commaSeparatedText.identifier
        ]
        
        for typeIdentifier in supportedTypes {
            if attachment.hasItemConformingToTypeIdentifier(typeIdentifier) {
                attachment.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] (item, error) in
                    guard let url = item as? URL else {
                        completion(false)
                        return
                    }
                    
                    // Generate a unique filename
                    let filename = "\(UUID().uuidString).\(url.pathExtension)"
                    
                    // Save the file
                    if let savedURL = ShareExtensionManager.shared.saveSharedFile(from: url, as: filename) {
                        let sharedContent = SharedContent.withFile(
                            url: savedURL,
                            filename: filename,
                            typeIdentifier: typeIdentifier
                        )
                        let success = ShareExtensionManager.shared.saveSharedContent(sharedContent)
                        completion(success)
                    } else {
                        completion(false)
                    }
                }
                return
            }
        }
        
        // If no supported type was found
        completion(false)
    }
    
    /// Completes the extension
    private func completeExtension() {
        // Complete the extension
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        
        // Call the completion handler
        completionHandler?()
    }
}
