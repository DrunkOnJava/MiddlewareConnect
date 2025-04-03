import Foundation

/// Represents the configuration and capabilities of Claude 3 language models
///
/// Provides a comprehensive abstraction for managing different variants of the Claude 3 model family,
/// enabling flexible and intelligent model selection based on specific use cases and performance requirements.
public struct Claude3Model {
    /// Defines the specific variants of the Claude 3 model family
    public enum Variant {
        /// Haiku: Optimized for speed and efficiency
        case haiku
        
        /// Sonnet: Balanced performance for general-purpose tasks
        case sonnet
        
        /// Opus: Most powerful model with advanced reasoning capabilities
        case opus
        
        /// Custom variant for specialized configurations
        case custom(name: String, capabilities: [Capability])
    }
    
    /// Represents specific capabilities of the language model
    public struct Capability: Hashable {
        /// Unique identifier for the capability
        public let identifier: String
        
        /// Descriptive name of the capability
        public let name: String
        
        /// Detailed description of the capability
        public let description: String
        
        /// Predefined standard capabilities
        public static let advancedReasoning = Capability(
            identifier: "advanced_reasoning",
            name: "Advanced Reasoning",
            description: "Sophisticated logical and analytical reasoning capabilities"
        )
        
        public static let multilingualSupport = Capability(
            identifier: "multilingual_support",
            name: "Multilingual Processing",
            description: "Robust understanding and generation across multiple languages"
        )
        
        public static let contextualUnderstanding = Capability(
            identifier: "contextual_understanding",
            name: "Deep Contextual Understanding",
            description: "Nuanced interpretation of complex contextual cues"
        )
        
        public static let creativeGeneration = Capability(
            identifier: "creative_generation",
            name: "Creative Content Generation",
            description: "Ability to generate original and innovative content"
        )
    }
    
    /// Detailed configuration for a Claude 3 model instance
    public struct Configuration {
        /// Specific model variant
        public let variant: Variant
        
        /// Maximum context window size in tokens
        public let contextWindowSize: Int
        
        /// Maximum response generation tokens
        public let maxResponseTokens: Int
        
        /// Supported capabilities for this model configuration
        public let capabilities: Set<Capability>
        
        /// Temperature controls randomness in response generation
        public let temperature: Double
        
        /// Top-p sampling parameter for controlled randomness
        public let topP: Double
        
        /// Creates a default configuration for a specific model variant
        /// - Parameter variant: The Claude 3 model variant
        public init(variant: Variant) {
            switch variant {
            case .haiku:
                self.init(
                    variant: .haiku,
                    contextWindowSize: 16_384,
                    maxResponseTokens: 4_096,
                    capabilities: [
                        .advancedReasoning,
                        .contextualUnderstanding
                    ],
                    temperature: 0.7,
                    topP: 0.9
                )
            case .sonnet:
                self.init(
                    variant: .sonnet,
                    contextWindowSize: 32_768,
                    maxResponseTokens: 8_192,
                    capabilities: [
                        .advancedReasoning,
                        .multilingualSupport,
                        .contextualUnderstanding,
                        .creativeGeneration
                    ],
                    temperature: 0.6,
                    topP: 0.8
                )
            case .opus:
                self.init(
                    variant: .opus,
                    contextWindowSize: 65_536,
                    maxResponseTokens: 16_384,
                    capabilities: [
                        .advancedReasoning,
                        .multilingualSupport,
                        .contextualUnderstanding,
                        .creativeGeneration
                    ],
                    temperature: 0.5,
                    topP: 0.7
                )
            case .custom(let name, let capabilities):
                self.init(
                    variant: .custom(name: name, capabilities: capabilities),
                    contextWindowSize: 32_768,
                    maxResponseTokens: 8_192,
                    capabilities: Set(capabilities),
                    temperature: 0.6,
                    topP: 0.8
                )
            }
        }
        
        /// Designated initializer for full model configuration
        /// - Parameters:
        ///   - variant: Model variant
        ///   - contextWindowSize: Maximum context length
        ///   - maxResponseTokens: Maximum tokens in generated response
        ///   - capabilities: Model-specific capabilities
        ///   - temperature: Randomness control
        ///   - topP: Sampling parameter
        public init(
            variant: Variant,
            contextWindowSize: Int,
            maxResponseTokens: Int,
            capabilities: Set<Capability>,
            temperature: Double,
            topP: Double
        ) {
            self.variant = variant
            self.contextWindowSize = contextWindowSize
            self.maxResponseTokens = maxResponseTokens
            self.capabilities = capabilities
            
            // Validate temperature and top-p values
            self.temperature = max(0.0, min(1.0, temperature))
            self.topP = max(0.0, min(1.0, topP))
        }
        
        /// Determines if the model supports a specific capability
        /// - Parameter capability: Capability to check
        /// - Returns: Boolean indicating capability support
        public func supportsCapability(_ capability: Capability) -> Bool {
            return capabilities.contains(capability)
        }
    }
    
    /// Provides model-specific pricing information
    public struct Pricing {
        /// Cost per 1 million input tokens
        public let inputTokenCost: Decimal
        
        /// Cost per 1 million output tokens
        public let outputTokenCost: Decimal
        
        /// Predefined pricing for standard variants
        public static let haiku = Pricing(inputTokenCost: 0.00025, outputTokenCost: 0.00125)
        public static let sonnet = Pricing(inputTokenCost: 0.003, outputTokenCost: 0.015)
        public static let opus = Pricing(inputTokenCost: 0.015, outputTokenCost: 0.075)
        
        /// Calculate total cost for a specific interaction
        /// - Parameters:
        ///   - inputTokens: Number of input tokens
        ///   - outputTokens: Number of output tokens
        /// - Returns: Total cost of the interaction
        public func calculateCost(inputTokens: Int, outputTokens: Int) -> Decimal {
            let inputCost = Decimal(inputTokens) / 1_000_000 * inputTokenCost
            let outputCost = Decimal(outputTokens) / 1_000_000 * outputTokenCost
            return inputCost + outputCost
        }
    }
    
    /// Factory method to create a model configuration
    /// - Parameter variant: Desired model variant
    /// - Returns: Configured Claude 3 model instance
    public static func configure(variant: Variant) -> Configuration {
        return Configuration(variant: variant)
    }
}

// MARK: - Codable Conformance
extension Claude3Model.Variant: Codable {}
extension Claude3Model.Capability: Codable {}
extension Claude3Model.Configuration: Codable {}
extension Claude3Model.Pricing: Codable {}
