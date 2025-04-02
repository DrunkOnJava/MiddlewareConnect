import Foundation
import Intents
import IntentsUI
import UIKit
import PDFKit
import UserNotifications

/// Manager for handling Shortcuts integration
class ShortcutsManager {
    // MARK: - Singleton
    
    /// Shared instance
    static let shared = ShortcutsManager()
    
    // MARK: - Properties
    
    /// The available shortcut types
    enum ShortcutType: String, CaseIterable {
        case textChunker = "TextChunker"
        case textCleaner = "TextCleaner"
        case markdownConverter = "MarkdownConverter"
        case documentSummarizer = "DocumentSummarizer"
        case pdfCombiner = "PDFCombiner"
        case pdfSplitter = "PDFSplitter"
        case csvFormatter = "CSVFormatter"
        case imageSplitter = "ImageSplitter"
        case tokenCostCalculator = "TokenCostCalculator"
        
        /// The display name for the shortcut
        var displayName: String {
            switch self {
            case .textChunker:
                return "Text Chunker"
            case .textCleaner:
                return "Text Cleaner"
            case .markdownConverter:
                return "Markdown Converter"
            case .documentSummarizer:
                return "Document Summarizer"
            case .pdfCombiner:
                return "PDF Combiner"
            case .pdfSplitter:
                return "PDF Splitter"
            case .csvFormatter:
                return "CSV Formatter"
            case .imageSplitter:
                return "Image Splitter"
            case .tokenCostCalculator:
                return "Token Cost Calculator"
            }
        }
        
        /// The description for the shortcut
        var description: String {
            switch self {
            case .textChunker:
                return "Split text into chunks for LLMs"
            case .textCleaner:
                return "Clean and format text"
            case .markdownConverter:
                return "Convert text to/from Markdown"
            case .documentSummarizer:
                return "Summarize a document"
            case .pdfCombiner:
                return "Combine multiple PDFs"
            case .pdfSplitter:
                return "Split a PDF into multiple files"
            case .csvFormatter:
                return "Format and clean CSV data"
            case .imageSplitter:
                return "Split an image into multiple parts"
            case .tokenCostCalculator:
                return "Calculate token usage and cost"
            }
        }
        
        /// The icon name for the shortcut
        var iconName: String {
            switch self {
            case .textChunker:
                return "text.insert"
            case .textCleaner:
                return "text.badge.checkmark"
            case .markdownConverter:
                return "arrow.2.squarepath"
            case .documentSummarizer:
                return "doc.text.magnifyingglass"
            case .pdfCombiner:
                return "doc.on.doc"
            case .pdfSplitter:
                return "doc.on.doc.fill"
            case .csvFormatter:
                return "tablecells"
            case .imageSplitter:
                return "photo.on.rectangle"
            case .tokenCostCalculator:
                return "dollarsign.circle"
            }
        }
        
        /// The parameters for the shortcut
        var parameters: [ShortcutParameter] {
            switch self {
            case .textChunker:
                return [
                    ShortcutParameter(
                        identifier: "text",
                        type: .string,
                        displayName: "Text",
                        description: "The text to chunk"
                    ),
                    ShortcutParameter(
                        identifier: "chunkSize",
                        type: .integer,
                        displayName: "Chunk Size",
                        description: "The size of each chunk in characters"
                    ),
                    ShortcutParameter(
                        identifier: "overlap",
                        type: .integer,
                        displayName: "Overlap",
                        description: "The overlap between chunks in characters"
                    )
                ]
            case .textCleaner:
                return [
                    ShortcutParameter(
                        identifier: "text",
                        type: .string,
                        displayName: "Text",
                        description: "The text to clean"
                    ),
                    ShortcutParameter(
                        identifier: "removeExtraSpaces",
                        type: .boolean,
                        displayName: "Remove Extra Spaces",
                        description: "Whether to remove extra spaces"
                    ),
                    ShortcutParameter(
                        identifier: "removeExtraNewlines",
                        type: .boolean,
                        displayName: "Remove Extra Newlines",
                        description: "Whether to remove extra newlines"
                    ),
                    ShortcutParameter(
                        identifier: "normalizeQuotes",
                        type: .boolean,
                        displayName: "Normalize Quotes",
                        description: "Whether to normalize quotes"
                    )
                ]
            case .markdownConverter:
                return [
                    ShortcutParameter(
                        identifier: "text",
                        type: .string,
                        displayName: "Text",
                        description: "The text to convert"
                    ),
                    ShortcutParameter(
                        identifier: "conversionType",
                        type: .string,
                        displayName: "Conversion Type",
                        description: "The type of conversion to perform (markdown-to-html, html-to-markdown, etc.)"
                    )
                ]
            case .documentSummarizer:
                return [
                    ShortcutParameter(
                        identifier: "fileURL",
                        type: .file,
                        displayName: "File",
                        description: "The document to summarize"
                    ),
                    ShortcutParameter(
                        identifier: "summaryLength",
                        type: .string,
                        displayName: "Summary Length",
                        description: "The length of the summary (short, medium, long)"
                    )
                ]
            case .pdfCombiner:
                return [
                    ShortcutParameter(
                        identifier: "fileURLs",
                        type: .fileArray,
                        displayName: "Files",
                        description: "The PDFs to combine"
                    )
                ]
            case .pdfSplitter:
                return [
                    ShortcutParameter(
                        identifier: "fileURL",
                        type: .file,
                        displayName: "File",
                        description: "The PDF to split"
                    ),
                    ShortcutParameter(
                        identifier: "splitType",
                        type: .string,
                        displayName: "Split Type",
                        description: "The type of split to perform (range, pages)"
                    ),
                    ShortcutParameter(
                        identifier: "pages",
                        type: .string,
                        displayName: "Pages",
                        description: "The pages to extract (e.g., '1-3,5,7-9')"
                    )
                ]
            case .csvFormatter:
                return [
                    ShortcutParameter(
                        identifier: "fileURL",
                        type: .file,
                        displayName: "File",
                        description: "The CSV file to format"
                    ),
                    ShortcutParameter(
                        identifier: "delimiter",
                        type: .string,
                        displayName: "Delimiter",
                        description: "The delimiter to use (comma, tab, semicolon)"
                    ),
                    ShortcutParameter(
                        identifier: "hasHeader",
                        type: .boolean,
                        displayName: "Has Header",
                        description: "Whether the CSV has a header row"
                    )
                ]
            case .imageSplitter:
                return [
                    ShortcutParameter(
                        identifier: "fileURL",
                        type: .file,
                        displayName: "File",
                        description: "The image to split"
                    ),
                    ShortcutParameter(
                        identifier: "splitType",
                        type: .string,
                        displayName: "Split Type",
                        description: "The type of split to perform (grid, horizontal, vertical)"
                    ),
                    ShortcutParameter(
                        identifier: "rows",
                        type: .integer,
                        displayName: "Rows",
                        description: "The number of rows (for grid split)"
                    ),
                    ShortcutParameter(
                        identifier: "columns",
                        type: .integer,
                        displayName: "Columns",
                        description: "The number of columns (for grid split)"
                    )
                ]
            case .tokenCostCalculator:
                return [
                    ShortcutParameter(
                        identifier: "text",
                        type: .string,
                        displayName: "Text",
                        description: "The text to calculate tokens for"
                    ),
                    ShortcutParameter(
                        identifier: "model",
                        type: .string,
                        displayName: "Model",
                        description: "The LLM model to use for calculation"
                    )
                ]
            }
        }
    }
    
    /// The parameter type for a shortcut
    enum ShortcutParameterType {
        case string
        case integer
        case boolean
        case file
        case fileArray
    }
    
    /// A parameter for a shortcut
    struct ShortcutParameter {
        /// The identifier for the parameter
        let identifier: String
        
        /// The type of the parameter
        let type: ShortcutParameterType
        
        /// The display name for the parameter
        let displayName: String
        
        /// The description for the parameter
        let description: String
    }
    
    // MARK: - Registered handlers
    
    /// Dictionary of shortcut handlers, keyed by shortcut type
    private var handlers: [ShortcutType: ShortcutHandler] = [:]
    
    // MARK: - Initialization
    
    private init() {
        registerDefaultHandlers()
    }
    
    /// Registers the default shortcut handlers
    private func registerDefaultHandlers() {
        // Register text processing handlers
        registerHandler(TextChunkerShortcutHandler())
        registerHandler(TextCleanerShortcutHandler())
        registerHandler(MarkdownConverterShortcutHandler())
        registerHandler(DocumentSummarizerShortcutHandler())
        
        // Register PDF handlers
        registerHandler(PDFCombinerShortcutHandler())
        registerHandler(PDFSplitterShortcutHandler())
        
        // Register data formatting handlers
        registerHandler(CSVFormatterShortcutHandler())
        registerHandler(ImageSplitterShortcutHandler())
        
        // Register LLM analysis handlers
        registerHandler(TokenCostCalculatorShortcutHandler())
    }
    
    /// Registers a shortcut handler
    /// - Parameter handler: The handler to register
    func registerHandler(_ handler: ShortcutHandler) {
        handlers[handler.shortcutType] = handler
    }
    
    // MARK: - Public Methods
    
    /// Donates a shortcut to the system
    /// - Parameters:
    ///   - type: The type of shortcut
    ///   - parameters: The parameters for the shortcut
    func donateShortcut(type: ShortcutType, parameters: [String: Any]) {
        // Create the intent
        let intent = createIntent(for: type, with: parameters)
        
        // Create the interaction
        let interaction = INInteraction(intent: intent, response: nil)
        
        // Donate the interaction
        interaction.donate { error in
            if let error = error {
                print("Error donating shortcut: \(error)")
            }
        }
    }
    
    /// Creates an intent for a shortcut
    /// - Parameters:
    ///   - type: The type of shortcut
    ///   - parameters: The parameters for the shortcut
    /// - Returns: The intent
    func createIntent(for type: ShortcutType, with parameters: [String: Any]) -> INIntent {
        // Create the intent
        let intent = INIntent()
        
        // Set the identifier
        intent.identifier = "com.yourcompany.llmbuddy.\(type.rawValue)"
        
        // Set the display name
        intent.setImage(INImage(named: type.iconName), forParameterNamed: "shortcut")
        
        // Set the parameters
        for parameter in type.parameters {
            switch parameter.type {
            case .string:
                if let value = parameters[parameter.identifier] as? String {
                    intent.setValue(value, forKey: parameter.identifier)
                }
            case .integer:
                if let value = parameters[parameter.identifier] as? Int {
                    intent.setValue(value, forKey: parameter.identifier)
                }
            case .boolean:
                if let value = parameters[parameter.identifier] as? Bool {
                    intent.setValue(value, forKey: parameter.identifier)
                }
            case .file:
                if let value = parameters[parameter.identifier] as? URL {
                    intent.setValue(value, forKey: parameter.identifier)
                }
            case .fileArray:
                if let value = parameters[parameter.identifier] as? [URL] {
                    intent.setValue(value, forKey: parameter.identifier)
                }
            }
        }
        
        return intent
    }
    
    /// Handles a shortcut
    /// - Parameters:
    ///   - intent: The intent
    ///   - completion: The completion handler
    func handleShortcut(intent: INIntent, completion: @escaping (Bool, Error?) -> Void) {
        // Get the shortcut type
        guard let typeString = intent.identifier?.components(separatedBy: ".").last,
              let type = ShortcutType(rawValue: typeString) else {
            completion(false, nil)
            return
        }
        
        // Get the parameters
        var parameters: [String: Any] = [:]
        
        for parameter in type.parameters {
            if let value = intent.value(forKey: parameter.identifier) {
                parameters[parameter.identifier] = value
            }
        }
        
        // Get the handler for this shortcut type
        guard let handler = handlers[type] else {
            let error = NSError(domain: "com.llmbuddy.shortcuts", code: 1000, userInfo: [NSLocalizedDescriptionKey: "No handler registered for shortcut type: \(type.rawValue)"])
            completion(false, error)
            return
        }
        
        // Handle the shortcut
        handler.handle(parameters: parameters, completion: completion)
    }
}

// MARK: - Shortcuts View Controller

/// View controller for adding shortcuts
class ShortcutsViewController: UIViewController, INUIAddVoiceShortcutViewControllerDelegate, INUIAddVoiceShortcutButtonDelegate {
    // MARK: - Properties
    
    /// The shortcut type
    private let shortcutType: ShortcutsManager.ShortcutType
    
    /// The parameters for the shortcut
    private let parameters: [String: Any]
    
    // MARK: - Initialization
    
    init(shortcutType: ShortcutsManager.ShortcutType, parameters: [String: Any]) {
        self.shortcutType = shortcutType
        self.parameters = parameters
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setupUI()
    }
    
    // MARK: - Private Methods
    
    /// Sets up the UI
    private func setupUI() {
        // Set up the view
        view.backgroundColor = .systemBackground
        
        // Add a title
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Add Shortcut"
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        titleLabel.textAlignment = .center
        
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // Add a description
        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = "Add a shortcut for \(shortcutType.displayName)"
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .body)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // Add a button to add the shortcut
        let addButton = INUIAddVoiceShortcutButton(style: .automatic)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.delegate = self
        
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 40),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    // MARK: - INUIAddVoiceShortcutButtonDelegate
    
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        // Create the intent
        let intent = ShortcutsManager.shared.createIntent(for: shortcutType, with: parameters)
        
        // Create the shortcut
        let shortcut = INShortcut(intent: intent)
        
        // Set the delegate
        addVoiceShortcutViewController.delegate = self
        
        // Present the view controller
        addVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(addVoiceShortcutViewController, animated: true)
    }
    
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        // Set the delegate
        editVoiceShortcutViewController.delegate = self
        
        // Present the view controller
        editVoiceShortcutViewController.modalPresentationStyle = .formSheet
        present(editVoiceShortcutViewController, animated: true)
    }
    
    // MARK: - INUIAddVoiceShortcutViewControllerDelegate
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        // Dismiss the view controller
        controller.dismiss(animated: true)
        
        // Check for errors
        if let error = error {
            print("Error adding shortcut: \(error)")
        }
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        // Dismiss the view controller
        controller.dismiss(animated: true)
    }
    
    // MARK: - INUIEditVoiceShortcutViewControllerDelegate
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
        // Dismiss the view controller
        controller.dismiss(animated: true)
        
        // Check for errors
        if let error = error {
            print("Error updating shortcut: \(error)")
        }
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        // Dismiss the view controller
        controller.dismiss(animated: true)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        // Dismiss the view controller
        controller.dismiss(animated: true)
    }
}