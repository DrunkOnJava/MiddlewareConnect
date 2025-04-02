import Foundation

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