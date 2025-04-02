/**
 * @fileoverview LLM models definitions
 * @module LLMModels
 * 
 * Created: 2025-03-29
 * Last Modified: 2025-03-29
 * 
 * Dependencies:
 * - SwiftUI
 * - Foundation
 * 
 * Exports:
 * - LLMModel enum
 * - Provider enum
 * - Conversation struct
 */

import SwiftUI
import Foundation

/// Enum representing the provider of an LLM model
public enum Provider: String, CaseIterable {
    case anthropic
    case openai
    case google
    case mistral
    case meta
    case local
    
    public var displayName: String {
        return self.rawValue.capitalized
    }
}

/// Enum representing different LLM models available in the app
public enum LLMModel: String, CaseIterable, Identifiable {
    case claudeSonnet = "claude_sonnet"
    case claudeHaiku = "claude_haiku"
    case claudeOphus = "claude_opus"
    case gpt35Turbo = "gpt_35_turbo"
    case gpt4 = "gpt_4"
    case gpt4Turbo = "gpt_4_turbo"
    case mistral7B = "mistral_7b"
    case llama3 = "llama_3"
    
    public var id: String { self.rawValue }
    
    public var name: String { self.displayName }
    
    public var displayName: String {
        switch self {
        case .claudeSonnet:
            return "Claude Sonnet"
        case .claudeHaiku:
            return "Claude Haiku"
        case .claudeOphus:
            return "Claude Opus"
        case .gpt35Turbo:
            return "GPT-3.5 Turbo"
        case .gpt4:
            return "GPT-4"
        case .gpt4Turbo:
            return "GPT-4 Turbo"
        case .mistral7B:
            return "Mistral 7B"
        case .llama3:
            return "Llama 3"
        }
    }
    
    public var provider: Provider {
        switch self {
        case .claudeSonnet, .claudeHaiku, .claudeOphus:
            return .anthropic
        case .gpt35Turbo, .gpt4, .gpt4Turbo:
            return .openai
        case .mistral7B:
            return .mistral
        case .llama3:
            return .meta
        }
    }
    
    public var providerName: String {
        return provider.rawValue.capitalized
    }
    
    public var contextWindow: Int {
        switch self {
        case .claudeSonnet:
            return 200000
        case .claudeHaiku:
            return 100000
        case .claudeOphus:
            return 1000000
        case .gpt35Turbo:
            return 16385
        case .gpt4:
            return 8192
        case .gpt4Turbo:
            return 128000
        case .mistral7B:
            return 32768
        case .llama3:
            return 8192
        }
    }
    
    public var costPer1kTokens: Double {
        switch self {
        case .claudeSonnet:
            return 0.03
        case .claudeHaiku:
            return 0.01
        case .claudeOphus:
            return 0.15
        case .gpt35Turbo:
            return 0.0015
        case .gpt4:
            return 0.03
        case .gpt4Turbo:
            return 0.01
        case .mistral7B:
            return 0.007
        case .llama3:
            return 0.0 // Assuming local model
        }
    }
    
    public var description: String {
        switch self {
        case .claudeSonnet:
            return "Claude Sonnet is a powerful model with a strong balance of intelligence and speed."
        case .claudeHaiku:
            return "Claude Haiku is an efficient, cost-effective, and faster model designed for faster responses."
        case .claudeOphus:
            return "Claude Opus is Anthropic's most powerful model with extraordinary intelligence and reasoning."
        case .gpt35Turbo:
            return "GPT-3.5 Turbo is a cost-effective model with good performance for most tasks."
        case .gpt4:
            return "GPT-4 is OpenAI's advanced model with strong reasoning capabilities."
        case .gpt4Turbo:
            return "GPT-4 Turbo is OpenAI's latest model with improved performance and larger context window."
        case .mistral7B:
            return "Mistral 7B is an efficient open-source model with good performance for its size."
        case .llama3:
            return "Llama 3 is Meta's latest open-source model with strong reasoning capabilities."
        }
    }
    
    // Additional property needed by ContentView
    public var color: Color {
        switch provider {
        case .anthropic:
            return .purple
        case .openai:
            return .green
        case .google:
            return .blue
        case .mistral:
            return .orange
        case .meta:
            return .blue
        case .local:
            return .gray
        }
    }
    
    // Default models property needed by several views
    public static var defaultModels: [LLMModel] {
        return [.claudeSonnet, .gpt4, .gpt4Turbo, .claudeHaiku]
    }
}

/// Represents a chat conversation
public class Conversation: Identifiable, ObservableObject {
    public let id = UUID()
    @Published public var title: String
    @Published public var messages: [Message]
    @Published public var model: LLMModel
    public var createdAt: Date
    @Published public var lastUpdatedAt: Date
    
    public init(title: String, messages: [Message] = [], model: LLMModel, createdAt: Date = Date(), lastUpdatedAt: Date = Date()) {
        self.title = title
        self.messages = messages
        self.model = model
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
    }
    
    public class Message: Identifiable {
        public let id = UUID()
        public let content: String
        public let isUser: Bool
        public let timestamp = Date()
        
        public init(content: String, isUser: Bool) {
            self.content = content
            self.isUser = isUser
        }
    }
}
