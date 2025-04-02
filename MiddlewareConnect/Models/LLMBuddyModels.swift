import Foundation
import SwiftUI

/**
 * @file LLMBuddyModels.swift
 * @description Central file that re-exports all model types
 * 
 * This file serves as a central point for importing all model types used throughout the app.
 */

// Module stub types

// LLM Model Stubs
struct LLMModel: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var modelId: String = ""
    var displayName: String = "Model"
    var provider: String = "Unknown"
    var contextWindow: Int = 0
    var maxOutputTokens: Int = 0
    var supportsVision: Bool = false
    var supportsFunctions: Bool = false
    var costPer1kInputTokens: Double = 0
    var costPer1kOutputTokens: Double = 0
    var capabilities: String = ""
    
    func estimatedCost(inputTokens: Int, outputTokens: Int) -> Double {
        let inputCost = Double(inputTokens) / 1000.0 * costPer1kInputTokens
        let outputCost = Double(outputTokens) / 1000.0 * costPer1kOutputTokens
        return inputCost + outputCost
    }
    
    static let claudeSonnet = LLMModel(
        modelId: "claude-3-sonnet-20240229",
        displayName: "Claude 3 Sonnet",
        provider: "Anthropic",
        contextWindow: 200000,
        maxOutputTokens: 4096,
        supportsVision: true,
        supportsFunctions: true,
        costPer1kInputTokens: 0.003,
        costPer1kOutputTokens: 0.015,
        capabilities: "Powerful, versatile model with excellent reasoning and writing abilities"
    )
    
    static let gpt4 = LLMModel(
        modelId: "gpt-4",
        displayName: "GPT-4",
        provider: "OpenAI",
        contextWindow: 8192,
        maxOutputTokens: 4096,
        supportsVision: false,
        supportsFunctions: true,
        costPer1kInputTokens: 0.03,
        costPer1kOutputTokens: 0.06,
        capabilities: "Advanced reasoning and problem-solving capabilities"
    )
    
    static var defaultModels: [LLMModel] {
        return [claudeSonnet, gpt4]
    }
}

// Stub for ApiFeatureToggles
struct ApiFeatureToggles: Codable, Equatable {
    var enableVision: Bool = true
    var enableFunctionCalling: Bool = true
    var useBetaFeatures: Bool = false
    var allowExperimentalModels: Bool = false
    var enableTools: Bool = true
    var enableStreaming: Bool = true
    var logApiRequests: Bool = false
}

// Stub for ApiValidationResult
struct ApiValidationResult {
    var isValid: Bool
    var errorMessage: String?
    var accountInfo: ApiAccountInfo?
    
    static func success(accountInfo: ApiAccountInfo) -> ApiValidationResult {
        return ApiValidationResult(isValid: true, errorMessage: nil, accountInfo: accountInfo)
    }
    
    static func failure(error: String) -> ApiValidationResult {
        return ApiValidationResult(isValid: false, errorMessage: error, accountInfo: nil)
    }
}

struct ApiAccountInfo: Codable {
    var accountId: String
    var organizationName: String?
    var accountType: String
    var credits: Double?
    var createdAt: Date?
    var availableModels: [String]?
    var hasBillingConfigured: Bool
}

// Stub for Conversation
struct Conversation: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var messages: [Message] = []
    var model: LLMModel
    var systemPrompt: String = ""
    var isFavorite: Bool = false
    var tags: [String] = []
    var parameters: ConversationParameters = ConversationParameters()

    var lastMessage: Message? {
        return messages.last
    }
    
    var messageCount: Int {
        return messages.count
    }
    
    var preview: String {
        if let lastMessage = lastMessage {
            let previewText = lastMessage.content
            if previewText.count > 100 {
                return String(previewText.prefix(100)) + "..."
            }
            return previewText
        }
        return "Empty conversation"
    }
}

// Stub for Message
struct Message: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var role: MessageRole
    var content: String
    var timestamp: Date = Date()
    var isEdited: Bool = false
    var tokenCount: Int = 0
    var attachments: [Attachment] = []
}

// Stub for MessageRole
enum MessageRole: String, Codable, CaseIterable {
    case user
    case assistant
    case system
}

// Stub for Attachment
struct Attachment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var type: AttachmentType
    var url: URL
    var mimeType: String
    var filename: String
    var fileSize: Int
}

// Stub for AttachmentType
enum AttachmentType: String, Codable, CaseIterable {
    case image
    case document
    case audio
    case video
}

// Stub for ConversationParameters
struct ConversationParameters: Codable, Hashable {
    var temperature: Double = 0.7
    var topP: Double = 0.95
    var maxTokens: Int? = nil
    var stopSequences: [String] = []
    var frequencyPenalty: Double = 0.0
    var presencePenalty: Double = 0.0
}
 * Last Modified: 2025-03-29
 * 
 * Dependencies:
 * - Foundation
 * - SwiftUI
 * 
 * Exports:
 * - Re-exports all model types for simpler imports across the project
 */

import Foundation
import SwiftUI

// Re-export all model types for easier imports
@_exported import struct Foundation.Data
@_exported import struct Foundation.Date
@_exported import struct Foundation.URL

// Type aliases for backward compatibility
public typealias LLMModelType = LLMModel
public typealias ApiSettingsType = ApiSettings
public typealias DesignSystemType = AppDesignSystem

// Ensure AppTheme references the correct type
public typealias AppTheme = AppDesignSystem.Theme
