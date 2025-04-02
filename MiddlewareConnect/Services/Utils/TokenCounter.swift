/**
 * @fileoverview Token counting utility for LLM context management
 * @module TokenCounter
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * 
 * Exports:
 * - TokenCounter
 * - TokenDistribution
 * 
 * Notes:
 * - Provides token counting functionality for various LLM providers
 * - Helps manage context window limits for different models
 * - Offers visualization data for context window usage
 */

import Foundation
import Combine

/// Token Distribution for visualization
public struct TokenDistribution {
    /// The different sections of content
    public var sections: [Section]
    
    /// Total tokens across all sections
    public var totalTokens: Int {
        sections.reduce(0) { $0 + $1.tokenCount }
    }
    
    /// Maximum token limit
    public var maxTokens: Int
    
    /// Percentage of context window used
    public var usagePercentage: Double {
        Double(totalTokens) / Double(maxTokens)
    }
    
    /// A section of content with token information
    public struct Section {
        /// Name of the section for display
        public var name: String
        
        /// Token count for this section
        public var tokenCount: Int
        
        /// Percentage of total tokens this section represents
        public var percentage: Double = 0
        
        /// Color for visualization (hex code)
        public var color: String
        
        /// Initialize a new section
        public init(name: String, tokenCount: Int, color: String) {
            self.name = name
            self.tokenCount = tokenCount
            self.color = color
        }
    }
    
    /// Initialize a new token distribution
    /// - Parameters:
    ///   - sections: The sections of content
    ///   - maxTokens: Maximum token limit
    public init(sections: [Section], maxTokens: Int) {
        self.sections = sections
        self.maxTokens = maxTokens
        
        // Calculate percentages
        let total = totalTokens
        
        // Update section percentages
        for i in 0..<self.sections.count {
            let percentage = total > 0 ? Double(self.sections[i].tokenCount) / Double(total) : 0
            self.sections[i].percentage = percentage
        }
    }
}

/// Service for counting tokens in text for LLM models
public class TokenCounter {
    // MARK: - Properties
    
    /// Shared instance
    public static let shared = TokenCounter()
    
    // MARK: - Methods
    
    /// Count tokens for text with specific model
    /// - Parameters:
    ///   - text: Text to count tokens for
    ///   - model: The LLM model to use for counting
    /// - Returns: Approximate token count
    public func countTokens(text: String, model: LLMModel) -> Int {
        // Delegate to provider-specific counter
        switch model.provider.lowercased() {
        case "anthropic":
            return countAnthropicTokens(text)
        case "openai":
            return countOpenAITokens(text)
        default:
            return countGenericTokens(text)
        }
    }
    
    /// Count tokens for a conversation
    /// - Parameters:
    ///   - messages: Array of conversation messages
    ///   - model: The LLM model to use for counting
    /// - Returns: Approximate token count
    public func countConversationTokens(messages: [ConversationMessage], model: LLMModel) -> Int {
        // Count tokens for each message and add overhead
        var total = 0
        
        for message in messages {
            total += countTokens(text: message.content, model: model)
            
            // Add overhead for message metadata (role, etc.)
            total += 4 // Approximate overhead per message
        }
        
        // Add model-specific overhead for the entire conversation
        switch model.provider.lowercased() {
        case "anthropic":
            total += 12 // Anthropic conversation overhead
        case "openai":
            total += 8 // OpenAI conversation overhead
        default:
            total += 10 // Generic overhead
        }
        
        return total
    }
    
    /// Get token distribution for visualization
    /// - Parameters:
    ///   - conversation: The conversation
    ///   - systemPrompt: Optional system prompt
    ///   - model: The LLM model
    /// - Returns: Token distribution for visualization
    public func getTokenDistribution(conversation: [ConversationMessage], systemPrompt: String?, model: LLMModel) -> TokenDistribution {
        var sections: [TokenDistribution.Section] = []
        
        // System prompt section
        if let systemPrompt = systemPrompt, !systemPrompt.isEmpty {
            let tokens = countTokens(text: systemPrompt, model: model)
            sections.append(TokenDistribution.Section(
                name: "System Prompt",
                tokenCount: tokens,
                color: "#4A6FA5" // Blue
            ))
        }
        
        // Message sections
        var userTokens = 0
        var assistantTokens = 0
        
        for message in conversation {
            let tokens = countTokens(text: message.content, model: model)
            
            if message.role == "user" {
                userTokens += tokens
            } else if message.role == "assistant" {
                assistantTokens += tokens
            }
        }
        
        // Add user messages section
        if userTokens > 0 {
            sections.append(TokenDistribution.Section(
                name: "User Messages",
                tokenCount: userTokens,
                color: "#6BBF59" // Green
            ))
        }
        
        // Add assistant messages section
        if assistantTokens > 0 {
            sections.append(TokenDistribution.Section(
                name: "Assistant Responses",
                tokenCount: assistantTokens,
                color: "#B55A5A" // Red
            ))
        }
        
        // Add overhead
        let overheadTokens = 25 // Approximate conversation format overhead
        sections.append(TokenDistribution.Section(
            name: "Overhead",
            tokenCount: overheadTokens,
            color: "#CCCCCC" // Gray
        ))
        
        // Create distribution
        return TokenDistribution(sections: sections, maxTokens: model.maxContextLength)
    }
    
    /// Calculate cost estimate for token usage
    /// - Parameters:
    ///   - inputTokens: Number of input tokens
    ///   - outputTokens: Number of output tokens
    ///   - model: The LLM model
    /// - Returns: Estimated cost in USD
    public func calculateCost(inputTokens: Int, outputTokens: Int, model: LLMModel) -> Double {
        // These rates are approximate and should be updated regularly
        switch model.id {
        case "claude3-opus":
            return Double(inputTokens) * 0.000015 + Double(outputTokens) * 0.000075
        case "claude3-sonnet":
            return Double(inputTokens) * 0.000003 + Double(outputTokens) * 0.000015
        case "claude3-haiku":
            return Double(inputTokens) * 0.000000725 + Double(outputTokens) * 0.00000362
        case "gpt-4":
            return Double(inputTokens) * 0.00003 + Double(outputTokens) * 0.00006
        case "gpt-3.5-turbo":
            return Double(inputTokens) * 0.0000015 + Double(outputTokens) * 0.000002
        default:
            // Generic rate for unknown models
            return Double(inputTokens) * 0.000005 + Double(outputTokens) * 0.00001
        }
    }
    
    // MARK: - Private Methods
    
    /// Count tokens for Anthropic models
    /// - Parameter text: Text to count tokens for
    /// - Returns: Approximate token count
    private func countAnthropicTokens(_ text: String) -> Int {
        // Simple estimation for Anthropic's tokenizer
        // In a real implementation, this would use Anthropic's tokenizer library
        
        // Approximately 4 characters per token for English text
        let characterCount = text.count
        let whitespaceCount = text.components(separatedBy: .whitespacesAndNewlines).count - 1
        
        // Formula based on empirical testing with Claude models
        return max(1, characterCount / 4 + whitespaceCount / 2)
    }
    
    /// Count tokens for OpenAI models
    /// - Parameter text: Text to count tokens for
    /// - Returns: Approximate token count
    private func countOpenAITokens(_ text: String) -> Int {
        // Simple estimation for OpenAI's tokenizer
        // In a real implementation, this would use OpenAI's tiktoken library
        
        // Approximately 4 characters per token for English text
        let characterCount = text.count
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).count
        
        // Formula based on empirical testing with GPT models
        return max(1, (characterCount / 4) + (wordCount / 4))
    }
    
    /// Generic token counter for unknown models
    /// - Parameter text: Text to count tokens for
    /// - Returns: Approximate token count
    private func countGenericTokens(_ text: String) -> Int {
        // Very simple approximation
        // Approximately 4 characters per token for English text
        return max(1, text.count / 4)
    }
}
