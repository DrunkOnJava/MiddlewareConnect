/**
 * @fileoverview API settings model
 * @module Models
 * 
 * Created: 2025-03-30
 * Last Modified: 2025-03-30
 * 
 * Dependencies:
 * - Foundation
 * 
 * Exports:
 * - ApiSettings struct
 * 
 * Notes:
 * - Manages API configuration and feature toggles
 */

import Foundation

/// API settings model
public struct ApiSettings: Codable, Equatable {
    /// API key for OpenAI
    public var openAIKey: String = ""
    
    /// API key for Anthropic
    public var anthropicKey: String = ""
    
    /// API key for Google AI
    public var googleKey: String = ""
    
    /// Custom API endpoints
    public var customEndpoints: [CustomApiEndpoint] = []
    
    /// Feature toggles
    public var featureToggles: ApiFeatureToggles = ApiFeatureToggles.defaultToggles
    
    /// Flag indicating if at least one valid API key is configured
    public var isValid: Bool {
        !openAIKey.isEmpty || !anthropicKey.isEmpty || !googleKey.isEmpty
    }
    
    /// Initialize with default settings
    public init() {}
    
    /// Initialize with specific settings
    public init(
        openAIKey: String = "",
        anthropicKey: String = "",
        googleKey: String = "",
        customEndpoints: [CustomApiEndpoint] = [],
        featureToggles: ApiFeatureToggles = ApiFeatureToggles.defaultToggles
    ) {
        self.openAIKey = openAIKey
        self.anthropicKey = anthropicKey
        self.googleKey = googleKey
        self.customEndpoints = customEndpoints
        self.featureToggles = featureToggles
    }
    
    /// Get the API key for a specific provider
    public func getApiKey(for provider: LLMProvider) -> String {
        switch provider {
        case .openAI:
            return openAIKey
        case .anthropic:
            return anthropicKey
        case .google:
            return googleKey
        case .meta, .localModel:
            return "" // No API key required
        case .customAPI:
            return customEndpoints.first?.apiKey ?? ""
        }
    }
}

/// Custom API endpoint configuration
public struct CustomApiEndpoint: Codable, Identifiable, Equatable {
    /// Unique identifier
    public var id = UUID()
    
    /// Endpoint name
    public var name: String
    
    /// Base URL
    public var baseUrl: String
    
    /// API key
    public var apiKey: String
    
    /// Additional headers
    public var headers: [String: String]
    
    /// Initialize a new custom endpoint
    public init(
        id: UUID = UUID(),
        name: String,
        baseUrl: String,
        apiKey: String,
        headers: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.baseUrl = baseUrl
        self.apiKey = apiKey
        self.headers = headers
    }
}
