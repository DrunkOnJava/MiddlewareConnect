/**
 * @fileoverview LLM Service Provider - Main integration point for LLM services
 * @module LLMServiceProvider
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * - Combine
 * 
 * Exports:
 * - LLMServiceProvider
 * 
 * Notes:
 * - Coordinates all LLM-related functionality
 * - Manages context, tokens, and Claude API interactions
 * - Primary integration point for app components
 */

import Foundation
import Combine
import PDFKit

/// Main service provider for LLM operations
public class LLMServiceProvider: ObservableObject {
    // MARK: - Properties
    
    /// Shared instance
    public static let shared = LLMServiceProvider()
    
    /// The anthropic service for API calls
    private let anthropicService: AnthropicService
    
    /// The token counter
    private let tokenCounter: TokenCounter
    
    /// The text chunker
    private let textChunker: TextChunker
    
    /// The context window
    private let contextWindow: ContextWindow
    
    /// The document analyzer
    private let documentAnalyzer: DocumentAnalyzer
    
    /// The current Claude model
    @Published public var currentModel: Claude3Model = .sonnet
    
    /// The system prompt
    @Published public var systemPrompt: String = SystemPrompts.assistant
    
    /// Processing status
    @Published public var status: ProcessingStatus = .idle
    
    /// Processing progress
    @Published public var progress: Double = 0
    
    /// Error message
    @Published public var errorMessage: String?
    
    /// Message history
    @Published public var messageHistory: [Message] = []
    
    /// Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        self.anthropicService = AnthropicService()
        self.tokenCounter = TokenCounter.shared
        self.textChunker = TextChunker(maxChunkSize: 4000)
        self.contextWindow = ContextWindow(
            modelName: Claude3Model.sonnet.rawValue,
            reservedTokens: 4000
        )
        self.documentAnalyzer = DocumentAnalyzer()
        
        // Set up subscribers
        setupSubscribers()
    }
    
    /// Sets up subscribers for various services
    private func setupSubscribers() {
        // Subscribe to API call status
        anthropicService.apiCallStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callStatus in
                switch callStatus {
                case .inProgress:
                    self?.status = .processing
                    self?.progress = 0.5
                case .completed:
                    self?.status = .idle
                    self?.progress = 1.0
                case .failed(let error):
                    self?.status = .error
                    self?.errorMessage = error.localizedDescription
                    self?.progress = 0
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to context window changes
        contextWindow.contextChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Sends a message to Claude
    /// - Parameters:
    ///   - message: The message to send
    ///   - completion: Callback with the response
    public func sendMessage(_ message: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Update status
        DispatchQueue.main.async {
            self.status = .processing
            self.progress = 0.1
            self.errorMessage = nil
        }
        
        // Add user message to history
        let userMessage = Message(role: .user, content: message, timestamp: Date())
        
        DispatchQueue.main.async {
            self.messageHistory.append(userMessage)
        }
        
        // Add message to context window
        do {
            try contextWindow.addItem("user: \(message)", type: "message", priority: 2)
        } catch {
            print("Failed to add message to context window: \(error.localizedDescription)")
        }
        
        // Create the full prompt with context
        let contextPrompt = contextWindow.generateStructuredContext()
        
        // Update progress
        DispatchQueue.main.async {
            self.progress = 0.3
        }
        
        // Send the message to Claude
        anthropicService.generateText(
            prompt: message,
            model: currentModel,
            systemPrompt: systemPrompt
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let responseText):
                // Add assistant message to history
                let assistantMessage = Message(role: .assistant, content: responseText, timestamp: Date())
                
                DispatchQueue.main.async {
                    self.messageHistory.append(assistantMessage)
                    self.status = .idle
                    self.progress = 1.0
                }
                
                // Add response to context window
                do {
                    try self.contextWindow.addItem("assistant: \(responseText)", type: "message", priority: 2)
                } catch {
                    print("Failed to add response to context window: \(error.localizedDescription)")
                }
                
                completion(.success(responseText))
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.status = .error
                    self.errorMessage = error.localizedDescription
                    self.progress = 0
                }
                
                completion(.failure(error))
            }
        }
    }
    
    /// Summarizes a document
    /// - Parameters:
    ///   - pdfURL: The PDF URL
    ///   - length: Desired summary length
    ///   - completion: Callback with the summary
    public func summarizeDocument(
        at pdfURL: URL,
        length: SummaryLength = .moderate,
        completion: @escaping (Result<DocumentSummary, Error>) -> Void
    ) {
        // Update status
        DispatchQueue.main.async {
            self.status = .processing
            self.progress = 0.1
            self.errorMessage = nil
        }
        
        // Use the document analyzer to summarize
        Task {
            do {
                let summary = try await documentAnalyzer.summarizeDocument(
                    at: pdfURL,
                    length: length,
                    model: currentModel
                )
                
                // Add summary to context window
                try contextWindow.addItem(
                    "Document Summary (\(pdfURL.lastPathComponent)):\n\(summary.summaryText)",
                    type: "summary",
                    priority: 3
                )
                
                DispatchQueue.main.async {
                    self.status = .idle
                    self.progress = 1.0
                    completion(.success(summary))
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .error
                    self.errorMessage = error.localizedDescription
                    self.progress = 0
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Extracts entities from a document
    /// - Parameters:
    ///   - pdfURL: The PDF URL
    ///   - completion: Callback with the entities
    public func extractEntities(
        from pdfURL: URL,
        completion: @escaping (Result<[ExtractedEntity], Error>) -> Void
    ) {
        // Update status
        DispatchQueue.main.async {
            self.status = .processing
            self.progress = 0.1
            self.errorMessage = nil
        }
        
        // Use the document analyzer to extract entities
        Task {
            do {
                let entities = try await documentAnalyzer.extractEntities(
                    from: pdfURL,
                    model: currentModel
                )
                
                DispatchQueue.main.async {
                    self.status = .idle
                    self.progress = 1.0
                    completion(.success(entities))
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .error
                    self.errorMessage = error.localizedDescription
                    self.progress = 0
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Compares two documents
    /// - Parameters:
    ///   - pdfURL1: The first PDF URL
    ///   - pdfURL2: The second PDF URL
    ///   - completion: Callback with the comparison
    public func compareDocuments(
        pdfURL1: URL,
        pdfURL2: URL,
        completion: @escaping (Result<DocumentComparison, Error>) -> Void
    ) {
        // Update status
        DispatchQueue.main.async {
            self.status = .processing
            self.progress = 0.1
            self.errorMessage = nil
        }
        
        // Use the document analyzer to compare documents
        Task {
            do {
                let comparison = try await documentAnalyzer.compareDocuments(
                    url1: pdfURL1,
                    url2: pdfURL2,
                    model: currentModel
                )
                
                DispatchQueue.main.async {
                    self.status = .idle
                    self.progress = 1.0
                    completion(.success(comparison))
                }
            } catch {
                DispatchQueue.main.async {
                    self.status = .error
                    self.errorMessage = error.localizedDescription
                    self.progress = 0
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Adds a document to the context
    /// - Parameters:
    ///   - pdfURL: The PDF URL
    ///   - completion: Callback with the result
    public func addDocumentToContext(
        pdfURL: URL,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        // Update status
        DispatchQueue.main.async {
            self.status = .processing
            self.progress = 0.1
            self.errorMessage = nil
        }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: pdfURL.path) else {
            DispatchQueue.main.async {
                self.status = .error
                self.errorMessage = "File not found"
                self.progress = 0
                completion(.failure(NSError(domain: "com.middlewareconnect.llm", code: -1, userInfo: [NSLocalizedDescriptionKey: "File not found"])))
            }
            return
        }
        
        // Load the PDF
        guard let pdf = PDFKit.PDFDocument(url: pdfURL) else {
            DispatchQueue.main.async {
                self.status = .error
                self.errorMessage = "Invalid PDF"
                self.progress = 0
                completion(.failure(NSError(domain: "com.middlewareconnect.llm", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid PDF"])))
            }
            return
        }
        
        // Extract text
        let pdfService = PDFService.shared
        pdfService.extractText(from: pdfURL) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let text):
                DispatchQueue.main.async {
                    self.progress = 0.5
                }
                
                // Count tokens
                let tokenCount = self.tokenCounter.countTokens(text)
                
                // Check if the document is too large
                if tokenCount > 10000 {
                    // Chunk the document
                    do {
                        let chunks = try self.textChunker.chunkText(text, strategy: .paragraph)
                        
                        // Use the first chunk
                        if let firstChunk = chunks.first {
                            let documentTitle = pdf.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? pdfURL.lastPathComponent
                            
                            // Add to context window
                            do {
                                let availableSize = try self.contextWindow.addItem(
                                    "Document (\(documentTitle)):\n\(firstChunk)",
                                    type: "document",
                                    priority: 3
                                )
                                
                                DispatchQueue.main.async {
                                    self.status = .idle
                                    self.progress = 1.0
                                    completion(.success(availableSize))
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    self.status = .error
                                    self.errorMessage = error.localizedDescription
                                    self.progress = 0
                                    completion(.failure(error))
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.status = .error
                                self.errorMessage = "Failed to chunk document"
                                self.progress = 0
                                completion(.failure(NSError(domain: "com.middlewareconnect.llm", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to chunk document"])))
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.status = .error
                            self.errorMessage = error.localizedDescription
                            self.progress = 0
                            completion(.failure(error))
                        }
                    }
                } else {
                    // Document is small enough to add directly
                    let documentTitle = pdf.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String ?? pdfURL.lastPathComponent
                    
                    // Add to context window
                    do {
                        let availableSize = try self.contextWindow.addItem(
                            "Document (\(documentTitle)):\n\(text)",
                            type: "document",
                            priority: 3
                        )
                        
                        DispatchQueue.main.async {
                            self.status = .idle
                            self.progress = 1.0
                            completion(.success(availableSize))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.status = .error
                            self.errorMessage = error.localizedDescription
                            self.progress = 0
                            completion(.failure(error))
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self.status = .error
                    self.errorMessage = error.localizedDescription
                    self.progress = 0
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Clears the context window
    public func clearContext() {
        contextWindow.clear()
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    /// Gets the available context size
    /// - Returns: The available context size in tokens
    public func getAvailableContextSize() -> Int {
        return contextWindow.getAvailableContextSize()
    }
    
    /// Gets the token count for a text
    /// - Parameter text: The text to count tokens for
    /// - Returns: The token count
    public func countTokens(_ text: String) -> Int {
        return tokenCounter.countTokens(text)
    }
    
    /// Changes the current model
    /// - Parameter model: The new model
    public func changeModel(_ model: Claude3Model) {
        currentModel = model
        
        // Update the context window size
        contextWindow.reservedTokens = model == .opus ? 8000 : 4000
        
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    /// Validates the API key
    /// - Parameter completion: Callback with the result
    public func validateAPIKey(completion: @escaping (Result<Bool, Error>) -> Void) {
        anthropicService.validateAPIKey(completion: completion)
    }
}

/// Processing status
public enum ProcessingStatus {
    case idle
    case processing
    case error
}

/// Message role
public enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

/// Message model
public struct Message: Identifiable, Codable {
    public let id = UUID()
    public let role: MessageRole
    public let content: String
    public let timestamp: Date
    
    public init(role: MessageRole, content: String, timestamp: Date = Date()) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
