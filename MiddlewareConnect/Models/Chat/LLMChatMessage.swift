/**
 * @fileoverview LLM chat message model
 * @module LLMChatMessage
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * 
 * Exports:
 * - LLMChatMessage
 * - MessageSender
 */

import Foundation
import SwiftUI

/// Represents a message in an LLM chat conversation
public struct LLMChatMessage: Identifiable, Equatable, Codable {
    /// Unique identifier for the message
    public let id: UUID
    
    /// The message content
    public var content: String
    
    /// The role of the message sender
    public let role: MessageRole
    
    /// The timestamp when the message was created
    public let timestamp: Date
    
    /// Whether the message is streaming
    public var isStreaming: Bool = false
    
    /// Whether the message is complete
    public var isComplete: Bool = true
    
    /// The message ID from the API, if available
    public var apiMessageId: String?
    
    /// Additional metadata associated with the message
    public var metadata: [String: String] = [:]

    /// Initialize with custom ID and parameters
    public init(
        id: UUID = UUID(),
        content: String,
        role: MessageRole = .user,
        timestamp: Date = Date(),
        isStreaming: Bool = false,
        isComplete: Bool = true,
        apiMessageId: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
        self.isStreaming = isStreaming
        self.isComplete = isComplete
        self.apiMessageId = apiMessageId
        self.metadata = metadata
    }
    
    /// Initialize for a user message
    public static func user(content: String) -> LLMChatMessage {
        LLMChatMessage(content: content, role: .user)
    }
    
    /// Initialize for an assistant message
    public static func assistant(content: String, isStreaming: Bool = false) -> LLMChatMessage {
        LLMChatMessage(content: content, role: .assistant, isStreaming: isStreaming, isComplete: !isStreaming)
    }
    
    /// Initialize for a system message
    public static func system(content: String) -> LLMChatMessage {
        LLMChatMessage(content: content, role: .system)
    }
    
    /// Create a copy of this message with updated content
    public func updatedWithContent(_ newContent: String, isStreaming: Bool = false) -> LLMChatMessage {
        var copy = self
        copy.content = newContent
        copy.isStreaming = isStreaming
        copy.isComplete = !isStreaming
        return copy
    }
    
    /// Create a streaming message
    public static func streaming(content: String = "", role: MessageRole = .assistant) -> LLMChatMessage {
        LLMChatMessage(content: content, role: role, isStreaming: true, isComplete: false)
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: LLMChatMessage, rhs: LLMChatMessage) -> Bool {
        lhs.id == rhs.id &&
        lhs.content == rhs.content &&
        lhs.role == rhs.role &&
        lhs.isStreaming == rhs.isStreaming &&
        lhs.isComplete == rhs.isComplete
    }
}

/// Message roles in a chat conversation
public enum MessageRole: String, Codable, CaseIterable {
    case user
    case assistant
    case system
    
    public var color: Color {
        switch self {
        case .user:
            return DesignSystem.Colors.primary
        case .assistant:
            return DesignSystem.Colors.secondaryBackground
        case .system:
            return Color.gray.opacity(0.3)
        }
    }
    
    public var textColor: Color {
        switch self {
        case .user:
            return .white
        case .assistant, .system:
            return DesignSystem.Colors.text
        }
    }
    
    public var icon: String {
        switch self {
        case .user:
            return "person.crop.circle.fill"
        case .assistant:
            return "sparkle.magnifyingglass"
        case .system:
            return "info.circle.fill"
        }
    }
    
    /// Role for API requests
    public var apiRole: String {
        self.rawValue
    }
}

/// Extension for chat-related helpers
extension Array where Element == LLMChatMessage {
    /// Convert messages to the format expected by the Anthropic API
    public func toAnthropicApiFormat() -> [[String: Any]] {
        self.map { message in
            var messageDict: [String: Any] = [
                "role": message.role.apiRole
            ]
            
            // For content, create a content array with text blocks
            let contentBlock: [String: String] = ["type": "text", "text": message.content]
            messageDict["content"] = [contentBlock]
            
            return messageDict
        }
    }
    
    /// Get only messages that should be sent to the API (exclude system messages for some APIs)
    public func apiMessages() -> [LLMChatMessage] {
        self.filter { $0.role != .system }
    }
    
    /// Extract the system message from the conversation
    public func systemMessage() -> LLMChatMessage? {
        self.first { $0.role == .system }
    }
}
