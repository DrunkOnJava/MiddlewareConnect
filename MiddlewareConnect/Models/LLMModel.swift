// Import from LLMBuddyModels.swift
 * Last Modified: 2025-03-29
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - LLMModel struct
 * - LLMProvider enum
 */

import Foundation
import SwiftUI

/// Represents a language model configuration
public struct LLMModel: Identifiable, Hashable, Codable {
    /// Unique identifier
    public var id = UUID()
    
    /// Name of the model
    public var name: String
    
    /// Model provider
    public var provider: LLMProvider
    
    /// Model identifier used by the provider's API
    public var modelId: String
    
    /// Context window size in tokens
    public var contextSize: Int
    
    /// Default temperature setting for this model
    public var defaultTemperature: Double = 0.7
    
    /// Whether the model supports streaming responses
    public var supportsStreaming: Bool = true
    
    /// Model's capabilities
    public var capabilities: [ModelCapability] = []
    
    /// Custom color associated with this model provider
    public var color: Color {
        provider.color
    }
    
    /// Model icon
    public var icon: String {
        provider.icon
    }
    
    /// Hash value for Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Equality check for Hashable conformance
    public static func == (lhs: LLMModel, rhs: LLMModel) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Default list of available models
    public static var defaultModels: [LLMModel] = [
        LLMModel(
            name: "Claude 3.5 Sonnet",
            provider: .anthropic,
            modelId: "claude-3-5-sonnet-20250307",
            contextSize: 200000,
            capabilities: [.chat, .codeGeneration, .reasoning]
        ),
        LLMModel(
            name: "GPT-4o",
            provider: .openAI,
            modelId: "gpt-4o",
            contextSize: 128000,
            capabilities: [.chat, .codeGeneration, .reasoning, .imageGeneration]
        ),
        LLMModel(
            name: "Gemini Pro",
            provider: .google,
            modelId: "gemini-pro",
            contextSize: 32768,
            capabilities: [.chat, .codeGeneration]
        ),
        LLMModel(
            name: "Llama 3 70B",
            provider: .meta,
            modelId: "meta-llama/llama-3-70b",
            contextSize: 8192,
            capabilities: [.chat, .codeGeneration]
        )
    ]
}

/// Model provider
public enum LLMProvider: String, Codable, CaseIterable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case google = "Google"
    case meta = "Meta"
    case localModel = "Local"
    case customAPI = "Custom API"
    
    /// Provider icon name
    public var icon: String {
        switch self {
        case .openAI: return "openai-logo"
        case .anthropic: return "anthropic-logo"
        case .google: return "google-logo"
        case .meta: return "meta-logo"
        case .localModel: return "desktopcomputer"
        case .customAPI: return "network"
        }
    }
    
    /// Provider brand color
    public var color: Color {
        switch self {
        case .openAI: return Color(red: 0.01, green: 0.69, blue: 0.45)
        case .anthropic: return Color(red: 0.97, green: 0.42, blue: 0.25)
        case .google: return Color(red: 0.26, green: 0.52, blue: 0.96)
        case .meta: return Color(red: 0.23, green: 0.35, blue: 0.60)
        case .localModel: return Color.gray
        case .customAPI: return Color.purple
        }
    }
    
    /// Base URL for the provider's API
    public var baseURL: URL? {
        switch self {
        case .openAI: return URL(string: "https://api.openai.com/v1")
        case .anthropic: return URL(string: "https://api.anthropic.com/v1")
        case .google: return URL(string: "https://generativelanguage.googleapis.com/v1")
        case .meta: return URL(string: "https://api.meta.ai/llama")
        case .localModel: return nil
        case .customAPI: return nil
        }
    }
}

/// Model capabilities
public enum ModelCapability: String, Codable {
    case chat = "Chat"
    case codeGeneration = "Code Generation"
    case reasoning = "Reasoning"
    case imageGeneration = "Image Generation"
    case audioTranscription = "Audio Transcription"
    case documentAnalysis = "Document Analysis"
}
