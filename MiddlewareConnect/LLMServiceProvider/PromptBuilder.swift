import Foundation

/// A sophisticated utility for constructing and managing prompts with advanced composition capabilities
///
/// The PromptBuilder provides a flexible, type-safe mechanism for crafting contextually rich 
/// and strategically structured prompts for language model interactions.
public struct PromptBuilder {
    /// Represents different types of prompt components
    public enum PromptComponent {
        /// System-level instructions that define overall context and behavior
        case system(String)
        
        /// User-generated content or query
        case user(String)
        
        /// Previous assistant response
        case assistant(String)
        
        /// Contextual information or background knowledge
        case context(String)
        
        /// Example interactions to guide model behavior
        case example(input: String, output: String)
    }
    
    /// Defines special token handling and formatting strategies
    public enum TokenStrategy {
        /// Standard token handling
        case standard
        
        /// Aggressive token optimization
        case compressed
        
        /// Preserve formatting and whitespace
        case preserveFormatting
        
        /// Custom token handling strategy
        case custom((String) -> String)
    }
    
    /// Represents the overall composition and intent of the prompt
    public struct PromptIntent {
        /// Primary objective of the prompt
        public let objective: String
        
        /// Specific constraints or guidelines
        public let constraints: [String]
        
        /// Desired output format
        public let outputFormat: String?
        
        /// Creates a structured prompt intent
        /// - Parameters:
        ///   - objective: Primary goal of the interaction
        ///   - constraints: Additional guidelines
        ///   - outputFormat: Desired response structure
        public init(
            objective: String,
            constraints: [String] = [],
            outputFormat: String? = nil
        ) {
            self.objective = objective
            self.constraints = constraints
            self.outputFormat = outputFormat
        }
    }
    
    /// Internal storage for prompt components
    private var components: [PromptComponent] = []
    
    /// Configuration for prompt generation
    private var configuration: Configuration
    
    /// Prompt-level intent and context
    private var intent: PromptIntent?
    
    /// Configuration parameters for prompt building
    public struct Configuration {
        /// Maximum number of tokens
        public let maxTokens: Int
        
        /// Token handling strategy
        public let tokenStrategy: TokenStrategy
        
        /// Whether to include metadata
        public let includeMetadata: Bool
        
        /// Default configuration with sensible defaults
        public static let `default` = Configuration(
            maxTokens: 4096,
            tokenStrategy: .standard,
            includeMetadata: true
        )
        
        /// Custom configuration initializer
        /// - Parameters:
        ///   - maxTokens: Maximum token limit
        ///   - tokenStrategy: Token handling approach
        ///   - includeMetadata: Include additional context metadata
        public init(
            maxTokens: Int = 4096,
            tokenStrategy: TokenStrategy = .standard,
            includeMetadata: Bool = true
        ) {
            self.maxTokens = maxTokens
            self.tokenStrategy = tokenStrategy
            self.includeMetadata = includeMetadata
        }
    }
    
    /// Initializes a new PromptBuilder
    /// - Parameter configuration: Custom configuration options
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }
    
    /// Adds a component to the prompt
    /// - Parameter component: Prompt component to add
    /// - Returns: Updated PromptBuilder
    @discardableResult
    public mutating func add(_ component: PromptComponent) -> Self {
        components.append(component)
        return self
    }
    
    /// Sets the overall intent for the prompt
    /// - Parameter intent: Prompt intent definition
    /// - Returns: Updated PromptBuilder
    @discardableResult
    public mutating func setIntent(_ intent: PromptIntent) -> Self {
        self.intent = intent
        return self
    }
    
    /// Constructs the final prompt string
    /// - Returns: Fully composed prompt
    /// - Throws: Errors related to prompt composition
    public func build() throws -> String {
        var promptComponents: [String] = []
        
        // Add intent-level system instructions
        if let intent = intent {
            var systemInstructions = [intent.objective]
            systemInstructions.append(contentsOf: intent.constraints)
            
            if let outputFormat = intent.outputFormat {
                systemInstructions.append("Output Format: \(outputFormat)")
            }
            
            promptComponents.append(systemInstructions.joined(separator: "\n"))
        }
        
        // Process and add components
        for component in components {
            switch component {
            case .system(let instruction):
                promptComponents.append("SYSTEM: \(instruction)")
            case .user(let message):
                promptComponents.append("USER: \(message)")
            case .assistant(let response):
                promptComponents.append("ASSISTANT: \(response)")
            case .context(let context):
                promptComponents.append("CONTEXT: \(context)")
            case .example(let input, let output):
                promptComponents.append("EXAMPLE:")
                promptComponents.append("INPUT: \(input)")
                promptComponents.append("OUTPUT: \(output)")
            }
        }
        
        // Apply token strategy
        let finalPrompt = applyTokenStrategy(promptComponents.joined(separator: "\n\n"))
        
        // Validate token count
        guard try validateTokenCount(finalPrompt) else {
            throw PromptBuilderError.tokenLimitExceeded
        }
        
        return finalPrompt
    }
    
    /// Applies the configured token handling strategy
    /// - Parameter prompt: Original prompt string
    /// - Returns: Processed prompt
    private func applyTokenStrategy(_ prompt: String) -> String {
        switch configuration.tokenStrategy {
        case .standard:
            return prompt
        case .compressed:
            return compressPrompt(prompt)
        case .preserveFormatting:
            return prompt
        case .custom(let customStrategy):
            return customStrategy(prompt)
        }
    }
    
    /// Compresses the prompt to reduce token usage
    /// - Parameter prompt: Original prompt string
    /// - Returns: Compressed prompt
    private func compressPrompt(_ prompt: String) -> String {
        // Implement sophisticated compression techniques
        // Remove unnecessary whitespace, reduce redundancy
        return prompt.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    /// Validates the token count of the final prompt
    /// - Parameter prompt: Constructed prompt
    /// - Returns: Boolean indicating if token count is within limits
    private func validateTokenCount(_ prompt: String) throws -> Bool {
        // Placeholder token counting (replace with actual implementation)
        let estimatedTokens = prompt.components(separatedBy: .whitespacesAndNewlines).count
        return estimatedTokens <= configuration.maxTokens
    }
    
    /// Predefined error types for prompt building
    public enum PromptBuilderError: Error {
        /// Indicates that the prompt exceeds token limits
        case tokenLimitExceeded
        
        /// Signals an invalid prompt composition
        case invalidComposition
    }
}

// MARK: - Convenience Initializers
public extension PromptBuilder {
    /// Quickly create a prompt with a simple user message
    /// - Parameter message: User's input message
    /// - Returns: Configured PromptBuilder
    static func simple(message: String) -> PromptBuilder {
        var builder = PromptBuilder()
        builder.add(.user(message))
        return builder
    }
    
    /// Create a prompt with a specific intent
    /// - Parameters:
    ///   - objective: Primary goal of the prompt
    ///   - message: User's input message
    /// - Returns: Configured PromptBuilder
    static func purposeful(
        objective: String,
        message: String
    ) -> PromptBuilder {
        var builder = PromptBuilder()
        builder.setIntent(PromptIntent(objective: objective))
        builder.add(.user(message))
        return builder
    }
}

// MARK: - Codable Support
extension PromptBuilder.PromptComponent: Codable {}
extension PromptBuilder.TokenStrategy: Codable {}
extension PromptBuilder.PromptIntent: Codable {}
extension PromptBuilder.Configuration: Codable {}
