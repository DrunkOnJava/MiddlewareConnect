import Foundation
import Combine
import SwiftUI

// Import our model types directly to avoid conflicts
typealias LLMModel = Models.LLMModel
typealias ApiValidationResult = Models.ApiValidationResult
typealias ApiUsageStats = Models.ApiUsageStats

/// Protocol for LLM service provider
public protocol LLMServiceProvider {
    /// Validate the API key
    func validateApiKey(completion: @escaping (ApiValidationResult) -> Void)
    
    /// Generate text using the model
    func generateText(prompt: String, model: LLMModel, completion: @escaping (Result<String, Error>) -> Void)
    
    /// Generate text with a system prompt
    func generateText(prompt: String, systemPrompt: String?, model: LLMModel, completion: @escaping (Result<String, Error>) -> Void)
    
    /// Get a publisher for API call status updates
    var apiCallStatusPublisher: AnyPublisher<APICallStatus, Never> { get }
}

/// Implementation for Anthropic's API service
public class AnthropicServiceProvider: LLMServiceProvider {
    // MARK: - Properties
    
    private let anthropicService = AnthropicService()
    
    // MARK: - Initialization
    
    /// Initialize with an API key
    public init(apiKey: String = "") {
        // The actual API key is managed by KeychainService
    }
    
    // MARK: - LLMServiceProvider Protocol
    
    /// Publisher for API call status
    public var apiCallStatusPublisher: AnyPublisher<APICallStatus, Never> {
        return anthropicService.apiCallStatus
    }
    
    /// Validate the API key
    /// - Parameter completion: A completion handler to call with the validation result
    public func validateApiKey(completion: @escaping (ApiValidationResult) -> Void) {
        anthropicService.validateAPIKey { result in
            switch result {
            case .success(let isValid):
                // Create mock usage stats for now
                // In a production app, you would fetch actual usage data from the API
                let usageStats = ApiUsageStats(
                    totalRequests: Int.random(in: 100...1000),
                    remainingCredits: Int.random(in: 10000...100000),
                    lastUpdated: Date()
                )
                
                completion(ApiValidationResult(valid: isValid, usageStats: usageStats))
                
            case .failure(let error):
                // Return invalid result with error
                completion(ApiValidationResult(
                    valid: false,
                    usageStats: nil,
                    error: error.localizedDescription
                ))
            }
        }
    }
    
    /// Generate text using the model
    /// - Parameters:
    ///   - prompt: The prompt to generate text from
    ///   - model: The model to use for generation
    ///   - completion: A completion handler to call with the result
    public func generateText(prompt: String, model: LLMModel, completion: @escaping (Result<String, Error>) -> Void) {
        generateText(prompt: prompt, systemPrompt: nil, model: model, completion: completion)
    }
    
    /// Generate text with a system prompt
    /// - Parameters:
    ///   - prompt: The prompt to generate text from
    ///   - systemPrompt: Optional system prompt to guide the model's response
    ///   - model: The model to use for generation
    ///   - completion: A completion handler to call with the result
    public func generateText(prompt: String, systemPrompt: String?, model: LLMModel, completion: @escaping (Result<String, Error>) -> Void) {
        // Convert LLMModel to Claude3Model
        let claudeModel = mapToClaudeModel(model)
        
        // Call the Anthropic API
        anthropicService.generateText(
            prompt: prompt,
            model: claudeModel,
            systemPrompt: systemPrompt
        ) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Maps the generic LLMModel to the specific Claude3Model
    /// - Parameter model: The generic LLMModel
    /// - Returns: The corresponding Claude3Model
    private func mapToClaudeModel(_ model: LLMModel) -> Claude3Model {
        // Map model ID to Claude3Model
        switch model.id.lowercased() {
        case "claude3-opus", "claude-3-opus":
            return .opus
        case "claude3-sonnet", "claude-3-sonnet":
            return .sonnet
        case "claude3-haiku", "claude-3-haiku":
            return .haiku
        default:
            // Default to Sonnet for unknown models
            return .sonnet
        }
    }
}

/// Factory for creating LLM service providers
public class LLMServiceFactory {
    /// Create an LLM service provider for the specified provider
    /// - Parameter provider: The provider name
    /// - Returns: An LLM service provider
    public static func createService(for provider: String) -> LLMServiceProvider {
        switch provider.lowercased() {
        case "anthropic":
            return AnthropicServiceProvider()
        default:
            // Default to Anthropic for now
            return AnthropicServiceProvider()
        }
    }
}

// MARK: - LLMModel Extensions

extension LLMModel {
    /// Convert to a Claude3Model if this is a Claude model
    var asClaudeModel: Claude3Model? {
        switch self.id.lowercased() {
        case "claude3-opus", "claude-3-opus":
            return .opus
        case "claude3-sonnet", "claude-3-sonnet":
            return .sonnet
        case "claude3-haiku", "claude-3-haiku":
            return .haiku
        default:
            return nil
        }
    }
    
    /// Whether this is a Claude model
    var isClaudeModel: Bool {
        return self.provider.lowercased() == "anthropic"
    }
    
    /// Claude 3 Opus model
    public static let claude3Opus = LLMModel(
        id: "claude3-opus",
        name: "Claude 3 Opus",
        maxContextLength: 200000,
        provider: "anthropic"
    )
    
    /// Claude 3 Sonnet model
    public static let claude3Sonnet = LLMModel(
        id: "claude3-sonnet",
        name: "Claude 3 Sonnet",
        maxContextLength: 200000,
        provider: "anthropic"
    )
    
    /// Claude 3 Haiku model
    public static let claude3Haiku = LLMModel(
        id: "claude3-haiku",
        name: "Claude 3 Haiku",
        maxContextLength: 200000,
        provider: "anthropic"
    )
    
    /// All Claude 3 models
    public static let allClaude3Models: [LLMModel] = [
        .claude3Opus,
        .claude3Sonnet,
        .claude3Haiku
    ]
}
