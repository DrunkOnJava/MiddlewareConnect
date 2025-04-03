/**
@fileoverview API settings model
@module Models
Created: 2025-03-30
Last Modified: 2025-04-02
Dependencies:
- Foundation
Exports:
- ApiSettings struct
Notes:
- Manages API configuration and feature toggles
/

import Foundation

// MARK: - ApiFeatureToggles Definition

/// Toggles for API-dependent features
public struct ApiFeatureToggles: Codable, Equatable {
    /// Enable streaming responses
    public var enableStreaming: Bool = true
    
    /// Enable vision capabilities
    public var enableVision: Bool = false
    
    /// Enable system prompts
    public var enableSystemPrompt: Bool = true
    
    /// Enable temperature adjustments
    public var enableTemperature: Bool = true
    
    /// Enable customization
    public var enableCustomization: Bool = true
    
    /// Enable function calling
    public var enableFunctionCalling: Bool = false
    
    /// Enable tool use
    public var enableTools: Bool = false
    
    /// OCR transcription feature
    public var ocrTranscription: Bool = false
    
    /// Intelligent naming feature
    public var intelligentNaming: Bool = false
    
    /// Markdown converter feature
    public var markdownConverter: Bool = false
    
    /// Document summarization feature
    public var documentSummarization: Bool = false
    
    /// Initialize with default values
    public init(
        enableStreaming: Bool = true,
        enableVision: Bool = false,
        enableSystemPrompt: Bool = true,
        enableTemperature: Bool = true,
        enableCustomization: Bool = true,
        enableFunctionCalling: Bool = false,
        enableTools: Bool = false,
        ocrTranscription: Bool = false,
        intelligentNaming: Bool = false,
        markdownConverter: Bool = false,
        documentSummarization: Bool = false
    ) {
        self.enableStreaming = enableStreaming
        self.enableVision = enableVision
        self.enableSystemPrompt = enableSystemPrompt
        self.enableTemperature = enableTemperature
        self.enableCustomization = enableCustomization
        self.enableFunctionCalling = enableFunctionCalling
        self.enableTools = enableTools
        self.ocrTranscription = ocrTranscription
        self.intelligentNaming = intelligentNaming
        self.markdownConverter = markdownConverter
        self.documentSummarization = documentSummarization
    }
    
    /// Default toggles with standard settings
    public static var defaultToggles: ApiFeatureToggles {
        return ApiFeatureToggles()
    }
}

// MARK: - LLMProvider Definition

/// Enum representing different LLM providers
public enum LLMProvider: String, Codable, Equatable, CaseIterable {
    /// OpenAI provider (GPT models)
    case openAI = "openai"
    
    /// Anthropic provider (Claude models)
    case anthropic = "anthropic"
    
    /// Google provider (Gemini/PaLM models)
    case google = "google"
    
    /// Meta provider (Llama models)
    case meta = "meta"
    
    /// Local models (no API required)
    case localModel = "local"
    
    /// Custom API endpoints
    case customAPI = "custom"
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .openAI:
            return "OpenAI"
        case .anthropic:
            return "Anthropic"
        case .google:
            return "Google AI"
        case .meta:
            return "Meta AI"
        case .localModel:
            return "Local Model"
        case .customAPI:
            return "Custom API"
        }
    }
    
    /// Default base URL for this provider
    public var defaultBaseUrl: String {
        switch self {
        case .openAI:
            return "https://api.openai.com/v1"
        case .anthropic:
            return "https://api.anthropic.com/v1"
        case .google:
            return "https://generativelanguage.googleapis.com/v1"
        case .meta, .localModel, .customAPI:
            return ""
        }
    }
}

// MARK: - CustomApiEndpoint Definition

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

// MARK: - ApiSettings Definition

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
    public var featureToggles: ApiFeatureToggles = ApiFeatureToggles()
    
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
        featureToggles: ApiFeatureToggles = ApiFeatureToggles()
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
    
    /// Equatable implementation
    public static func == (lhs: ApiSettings, rhs: ApiSettings) -> Bool {
        return lhs.openAIKey == rhs.openAIKey &&
               lhs.anthropicKey == rhs.anthropicKey &&
               lhs.googleKey == rhs.googleKey &&
               lhs.customEndpoints == rhs.customEndpoints &&
               lhs.featureToggles == rhs.featureToggles
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case openAIKey
        case anthropicKey
        case googleKey
        case customEndpoints
        case featureToggles
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(openAIKey, forKey: .openAIKey)
        try container.encode(anthropicKey, forKey: .anthropicKey)
        try container.encode(googleKey, forKey: .googleKey)
        try container.encode(customEndpoints, forKey: .customEndpoints)
        try container.encode(featureToggles, forKey: .featureToggles)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        openAIKey = try container.decodeIfPresent(String.self, forKey: .openAIKey) ?? ""
        anthropicKey = try container.decodeIfPresent(String.self, forKey: .anthropicKey) ?? ""
        googleKey = try container.decodeIfPresent(String.self, forKey: .googleKey) ?? ""
        customEndpoints = try container.decodeIfPresent([CustomApiEndpoint].self, forKey: .customEndpoints) ?? []
        featureToggles = try container.decodeIfPresent(ApiFeatureToggles.self, forKey: .featureToggles) ?? ApiFeatureToggles()
    }
}