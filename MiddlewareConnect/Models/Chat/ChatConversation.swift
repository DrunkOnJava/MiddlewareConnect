/**
 * @fileoverview Chat conversation model
 * @module ChatConversation
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * 
 * Exports:
 * - ChatConversation
 */

import Foundation
import SwiftUI

/// Represents a complete chat conversation between a user and an LLM
public struct ChatConversation: Identifiable, Codable, Equatable {
    /// Unique identifier for the conversation
    public let id: UUID
    
    /// The title of the conversation
    public var title: String
    
    /// The messages in the conversation
    public var messages: [LLMChatMessage]
    
    /// The LLM model used for this conversation
    public var model: LLMModel
    
    /// When the conversation was last updated
    public var lastUpdated: Date
    
    /// Initialize a new conversation
    public init(
        id: UUID = UUID(),
        title: String,
        messages: [LLMChatMessage] = [],
        model: LLMModel = .claudeSonnet,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.model = model
        self.lastUpdated = lastUpdated
    }
    
    /// Get the system message from the conversation if one exists
    public var systemMessage: LLMChatMessage? {
        messages.first { $0.role == .system }
    }
    
    /// Get user and assistant messages (exclude system messages)
    public var chatMessages: [LLMChatMessage] {
        messages.filter { $0.role != .system }
    }
    
    /// Add a new message to the conversation
    public mutating func addMessage(_ message: LLMChatMessage) {
        messages.append(message)
        lastUpdated = Date()
    }
    
    /// Get the most recent message in the conversation
    public var lastMessage: LLMChatMessage? {
        messages.last
    }
    
    /// Check if the conversation is empty (no user or assistant messages)
    public var isEmpty: Bool {
        chatMessages.isEmpty
    }
    
    // MARK: - Equatable
    
    public static func == (lhs: ChatConversation, rhs: ChatConversation) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.messages == rhs.messages &&
        lhs.model == rhs.model
    }
}