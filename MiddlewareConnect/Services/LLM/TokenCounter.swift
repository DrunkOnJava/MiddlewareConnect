/**
 * @fileoverview Token Counter for LLM context management
 * @module TokenCounter
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * - NaturalLanguage
 * 
 * Exports:
 * - TokenCounter
 * 
 * Notes:
 * - Estimates token counts for Claude models
 * - Used to manage context window limits
 */

import Foundation
import NaturalLanguage

/// A service for counting tokens in text
public class TokenCounter {
    // MARK: - Properties
    
    /// Shared instance
    public static let shared = TokenCounter()
    
    /// Claude model token limits
    public struct ModelLimits {
        public static let claude3Haiku = 200000
        public static let claude3Sonnet = 200000
        public static let claude3Opus = 200000
        public static let claude35Sonnet = 200000
    }
    
    /// Tokenizer for estimating token counts
    private let tokenizer: NLTokenizer
    
    // MARK: - Initialization
    
    private init() {
        tokenizer = NLTokenizer(unit: .word)
    }
    
    // MARK: - Token Counting
    
    /// Counts the tokens in a text string
    /// - Parameter text: The text to count tokens for
    /// - Returns: The estimated token count
    public func countTokens(_ text: String) -> Int {
        // Claude uses a custom tokenizer (BPE-based), so this is an approximation
        // In practice, we'd use a more accurate model, but this gives a reasonable estimate
        
        tokenizer.string = text
        
        // Count tokens
        var tokenCount = 0
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { _, _ in
            tokenCount += 1
            return true
        }
        
        // Add a factor to account for BPE tokenization differences
        // Claude's tokenizer typically produces more tokens than word-based tokenization
        let adjustedCount = Int(Double(tokenCount) * 1.3)
        
        return adjustedCount
    }
    
    /// Gets the token limit for a specific model
    /// - Parameter modelName: The model name (e.g., "claude-3-opus")
    /// - Returns: The token limit
    public func getTokenLimit(forModel modelName: String) -> Int {
        switch modelName.lowercased() {
        case "claude-3-haiku", "claude-3-haiku-20240307":
            return ModelLimits.claude3Haiku
        case "claude-3-sonnet", "claude-3-sonnet-20240229":
            return ModelLimits.claude3Sonnet
        case "claude-3-opus", "claude-3-opus-20240229":
            return ModelLimits.claude3Opus
        case "claude-3.5-sonnet", "claude-3.5-sonnet-20240229":
            return ModelLimits.claude35Sonnet
        default:
            // Default to the lowest limit if model is unknown
            return ModelLimits.claude3Haiku
        }
    }
    
    /// Estimates the response tokens for a prompt
    /// - Parameter promptTokens: The token count of the prompt
    /// - Returns: An estimated response token count
    public func estimateResponseTokens(promptTokens: Int) -> Int {
        // A common rule of thumb is that responses are about 50% of the prompt length
        // This is a very rough estimate and will vary significantly
        return min(Int(Double(promptTokens) * 0.5), 4000)
    }
    
    /// Calculates the cost of token usage
    /// - Parameters:
    ///   - inputTokens: Number of input tokens
    ///   - outputTokens: Number of output tokens
    ///   - model: The Claude model
    /// - Returns: The estimated cost in USD
    public func calculateCost(inputTokens: Int, outputTokens: Int, model: Claude3Model) -> Double {
        let inputCost = Double(inputTokens) * model.costPerInputToken
        let outputCost = Double(outputTokens) * model.costPerOutputToken
        return inputCost + outputCost
    }
}
