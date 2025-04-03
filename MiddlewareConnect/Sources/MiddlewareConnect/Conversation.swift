/**
@fileoverview Conversation model
@module Models
Created: 2025-03-29
Last Modified: 2025-03-29
Dependencies:
- Foundation
- SwiftUI
- Combine
Exports:
- Conversation class
/

import Foundation
import SwiftUI
import Combine

/// Represents a conversation with an AI assistant
public class Conversation: ObservableObject, Identifiable, Codable {
    /// Unique identifier for the conversation
    public let id: UUID
    
    /// Title of the conversation
    @Published public var title: String
    
    /// Messages in the conversation
    @Published public var messages: [Message] = []
    
    /// The model used for this conversation
    @Published public var model: LLMModel
    
    /// When the conversation was created
    public let createdAt: Date
    
    /// When the conversation was last updated
    @Published public var lastUpdatedAt: Date
    
    /// Whether the conversation is pinned
    @Published public var isPinned: Bool = false
    
    /// Coding keys for Codable conformance
    enum CodingKeys: String, CodingKey {
        case id, title, messages, model, createdAt, lastUpdatedAt, isPinned
    }
    
    /// Initialize a new conversation
    public init(
        id: UUID = UUID(),
        title: String = "New Chat",
        messages: [Message] = [],
        model: LLMModel = LLMModel.defaultModels[0],
        createdAt: Date = Date(),
        lastUpdatedAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.model = model
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
        self.isPinned = isPinned
    }
    
    /// Required initializer for Decodable
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        messages = try container.decode([Message].self, forKey: .messages)
        model = try container.decode(LLMModel.self, forKey: .model)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastUpdatedAt = try container.decode(Date.self, forKey: .lastUpdatedAt)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
    }
    
    /// Encode to Codable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(messages, forKey: .messages)
        try container.encode(model, forKey: .model)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastUpdatedAt, forKey: .lastUpdatedAt)
        try container.encode(isPinned, forKey: .isPinned)
    }
    
    /// Add a message to the conversation
    public func addMessage(_ message: Message) {
        messages.append(message)
        updateTimestamp()
    }
    
    /// Update the timestamp
    private func updateTimestamp() {
        lastUpdatedAt = Date()
    }
}

/// Represents a message in a conversation
public struct Message: Identifiable, Codable {
    /// Unique identifier for the message
    public let id: UUID
    
    /// Content of the message
    public let content: String
    
    /// Whether the message is from the user
    public let isUser: Bool
    
    /// When the message was created
    public let timestamp: Date
    
    /// Initialize a new message
    public init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}
