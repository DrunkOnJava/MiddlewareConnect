/**
@fileoverview Provider model for different LLM services
@module Provider
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- Foundation
Exports:
- Provider enum
/

import Foundation
import SwiftUI

/// LLM Provider enum
public enum Provider: String, Codable, CaseIterable {
    case anthropic = "Anthropic"
    case openai = "OpenAI"
    case google = "Google"
    case mistral = "Mistral"
    case meta = "Meta"
    case local = "Local"
    
    /// Provider icon name
    public var icon: String {
        switch self {
        case .openai: return "openai-logo"
        case .anthropic: return "anthropic-logo"
        case .google: return "google-logo"
        case .mistral: return "mistral-logo"
        case .meta: return "meta-logo"
        case .local: return "desktopcomputer"
        }
    }
    
    /// Provider brand color
    public var color: Color {
        switch self {
        case .openai: return Color(red: 0.01, green: 0.69, blue: 0.45)
        case .anthropic: return Color(red: 0.97, green: 0.42, blue: 0.25)
        case .google: return Color(red: 0.26, green: 0.52, blue: 0.96)
        case .mistral: return Color(red: 0.34, green: 0.63, blue: 0.83)
        case .meta: return Color(red: 0.23, green: 0.35, blue: 0.60)
        case .local: return Color.gray
        }
    }
    
    /// Base URL for the provider's API
    public var baseURL: URL? {
        switch self {
        case .openai: return URL(string: "https://api.openai.com/v1")
        case .anthropic: return URL(string: "https://api.anthropic.com/v1")
        case .google: return URL(string: "https://generativelanguage.googleapis.com/v1")
        case .mistral: return URL(string: "https://api.mistral.ai/v1")
        case .meta: return URL(string: "https://api.meta.ai/llama")
        case .local: return nil
        }
    }
}
