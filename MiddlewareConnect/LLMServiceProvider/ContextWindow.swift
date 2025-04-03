import Foundation

/// Manages token context for Large Language Model interactions
///
/// Provides sophisticated token tracking and context window optimization to ensure 
/// efficient and precise communication with language models.
public struct ContextWindow {
    /// Strategies for counting tokens in text
    public enum TokenCountStrategy {
        /// OpenAI's token counting method
        case openAI
        
        /// Anthropic's token counting approach
        case anthropic
        
        /// Custom token counting strategy
        case custom((String) -> Int)
    }
    
    /// Configuration parameters for the context window
    public struct Configuration {
        /// Maximum number of tokens allowed in the context
        public let maxTokens: Int
        
        /// Number of tokens reserved for system prompts and response generation
        public let reservedTokens: Int
        
        /// Strategy used for counting tokens
        public let tokenCountStrategy: TokenCountStrategy
        
        /// Initialize a context window configuration
        /// - Parameters:
        ///   - maxTokens: Total token limit for the context
        ///   - reservedTokens: Tokens set aside for system operations
        ///   - tokenCountStrategy: Method for token calculation
        public init(
            maxTokens: Int,
            reservedTokens: Int = 500,
            tokenCountStrategy: TokenCountStrategy = .anthropic
        ) {
            self.maxTokens = maxTokens
            self.reservedTokens = reservedTokens
            self.tokenCountStrategy = tokenCountStrategy
        }
    }
    
    /// Represents potential errors in context window management
    public enum ContextWindowError: Error {
        /// Indicates that adding a message would exceed the context window
        case contextWindowExceeded
        
        /// Signals an invalid token counting strategy
        case invalidTokenCountStrategy
    }
    
    /// Defines the role of a message in the conversation
    public enum MessageRole {
        /// System-level instructions or context
        case system
        
        /// User-generated message
        case user
        
        /// AI-generated response
        case assistant
    }
    
    /// Current configuration for the context window
    private let configuration: Configuration
    
    /// Tracks the current number of tokens used
    private var currentTokenUsage: Int = 0
    
    /// Maintains a history of messages with their token counts
    private var messageHistory: [(message: String, role: MessageRole, tokens: Int)] = []
    
    /// Initialize a context window with a specific configuration
    /// - Parameter configuration: Detailed settings for token management
    public init(configuration: Configuration) {
        self.configuration = configuration
    }
    
    /// Count tokens in a given text using the configured strategy
    /// - Parameter text: Text to analyze for token count
    /// - Returns: Number of tokens in the text
    /// - Throws: Errors related to token counting strategy
    public func countTokens(_ text: String) throws -> Int {
        switch configuration.tokenCountStrategy {
        case .openAI:
            return countOpenAITokens(text)
        case .anthropic:
            return countAnthropicTokens(text)
        case .custom(let customStrategy):
            return customStrategy(text)
        }
    }
    
    /// Add a message to the context window
    /// - Parameters:
    ///   - message: Text of the message
    ///   - role: Role of the message sender
    /// - Throws: Errors if the message exceeds context window limits
    public mutating func addMessage(_ message: String, role: MessageRole) throws {
        let messageTokens = try countTokens(message)
        
        // Validate token usage against context window
        guard currentTokenUsage + messageTokens <= configuration.maxTokens - configuration.reservedTokens else {
            throw ContextWindowError.contextWindowExceeded
        }
        
        // Update message history and token usage
        messageHistory.append((message, role, messageTokens))
        currentTokenUsage += messageTokens
    }
    
    /// Retrieve the current message history
    /// - Returns: Array of messages with their roles and token counts
    public func getMessageHistory() -> [(message: String, role: MessageRole, tokens: Int)] {
        return messageHistory
    }
    
    /// Reset the context window, clearing message history
    public mutating func reset() {
        messageHistory.removeAll()
        currentTokenUsage = 0
    }
    
    /// Optimize context by removing oldest messages to make room for new content
    /// - Parameter requiredTokens: Number of tokens needed for new content
    public mutating func optimize(forRequiredTokens requiredTokens: Int) {
        // Remove oldest messages until enough space is available
        while currentTokenUsage + requiredTokens > configuration.maxTokens - configuration.reservedTokens && !messageHistory.isEmpty {
            let oldestMessage = messageHistory.removeFirst()
            currentTokenUsage -= oldestMessage.tokens
        }
    }
    
    // MARK: - Internal Token Counting Methods
    
    /// Count tokens using OpenAI's method
    /// - Parameter text: Text to count tokens for
    /// - Returns: Number of tokens
    private func countOpenAITokens(_ text: String) -> Int {
        // Placeholder implementation - replace with actual OpenAI token counting logic
        return text.components(separatedBy: .whitespacesAndNewlines).count
    }
    
    /// Count tokens using Anthropic's method
    /// - Parameter text: Text to count tokens for
    /// - Returns: Number of tokens
    private func countAnthropicTokens(_ text: String) -> Int {
        // Placeholder implementation - replace with actual Anthropic token counting logic
        return text.utf8.count / 4 // Rough estimate
    }
}
