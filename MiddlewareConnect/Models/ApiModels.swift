import Foundation

// MARK: - API Models

/// Model representing API settings configuration
public struct ApiSettings {
    /// Nested type for validation results
    public typealias ValidationResult = ApiValidationResult
    
    /// Nested type for usage statistics
    public typealias UsageStats = ApiUsageStats
    /// The API key for accessing external LLM services
    public var apiKey: String
    
    /// Indicates whether the API key is valid
    public var isValid: Bool
    
    /// Feature toggles for API-related functionality
    public var featureToggles: ApiFeatureToggles
    
    /// Statistics for API usage
    public var usageStats: ApiUsageStats
    
    public init(apiKey: String, isValid: Bool, featureToggles: ApiFeatureToggles, usageStats: ApiUsageStats) {
        self.apiKey = apiKey
        self.isValid = isValid
        self.featureToggles = featureToggles
        self.usageStats = usageStats
    }
}

/// Feature toggles for API-related functionality
public struct ApiFeatureToggles: Codable {
    /// Toggle for OCR transcription feature
    public var ocrTranscription: Bool
    
    /// Toggle for intelligent naming feature
    public var intelligentNaming: Bool
    
    /// Toggle for markdown converter feature
    public var markdownConverter: Bool
    
    /// Toggle for document summarization feature
    public var documentSummarization: Bool
    
    public init(ocrTranscription: Bool, intelligentNaming: Bool, markdownConverter: Bool, documentSummarization: Bool) {
        self.ocrTranscription = ocrTranscription
        self.intelligentNaming = intelligentNaming
        self.markdownConverter = markdownConverter
        self.documentSummarization = documentSummarization
    }
}

/// Statistics for API usage
public struct ApiUsageStats: Codable {
    /// Total number of API requests made
    public var totalRequests: Int
    
    /// Remaining API usage credits
    public var remainingCredits: Int
    
    /// When the stats were last updated
    public var lastUpdated: Date
    
    public init(totalRequests: Int, remainingCredits: Int, lastUpdated: Date) {
        self.totalRequests = totalRequests
        self.remainingCredits = remainingCredits
        self.lastUpdated = lastUpdated
    }
    
    /// Format the last updated date for display
    public var formattedLastUpdated: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: lastUpdated)
    }
}

/// Result of API key validation
public struct ApiValidationResult {
    /// Indicates whether the API key is valid
    public var valid: Bool
    
    /// Usage statistics if validation was successful
    public var usageStats: ApiUsageStats?
    
    /// Error message if validation failed
    public var error: String?
    
    public init(valid: Bool, usageStats: ApiUsageStats? = nil, error: String? = nil) {
        self.valid = valid
        self.usageStats = usageStats
        self.error = error
    }
}

// MARK: - API Service Protocols

/// Protocol for API key storage service
public protocol ApiKeyStorageService {
    /// Store API key securely
    func storeApiKey(_ identifier: String, apiKey: String) -> Bool
    
    /// Retrieve API key
    func retrieveApiKey(_ identifier: String) -> String?
    
    /// Delete API key
    func deleteApiKey(_ identifier: String) -> Bool
}

/// Protocol for LLM service provider
public protocol LLMServiceProvider {
    /// Validate the API key
    func validateApiKey(completion: @escaping (ApiValidationResult) -> Void)
    
    /// Generate text using the model
    func generateText(prompt: String, model: LLMModel, completion: @escaping (Result<String, Error>) -> Void)
}
