import Foundation

/// Represents a chat message in the LLM conversation
public struct LLMChatMessage: Identifiable {
    public let id = UUID()
    public let content: String
    public let isUser: Bool
    public let timestamp = Date()
    
    public init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
    }
}

/// Represents a chat session with an LLM
public struct ChatSession: Identifiable {
    public let id = UUID()
    public var title: String
    public var messages: [LLMChatMessage]
    public var model: LLMModel
    public var createdAt: Date
    public var lastUpdatedAt: Date
    
    public init(title: String, messages: [LLMChatMessage] = [], model: LLMModel, createdAt: Date = Date(), lastUpdatedAt: Date = Date()) {
        self.title = title
        self.messages = messages
        self.model = model
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
    }
    
    /// Updates the last updated timestamp
    public mutating func updateTimestamp() {
        self.lastUpdatedAt = Date()
    }
    
    /// Adds a message to the conversation
    public mutating func addMessage(_ message: LLMChatMessage) {
        self.messages.append(message)
        self.updateTimestamp()
    }
    
    /// Generates a title based on the conversation
    public mutating func generateTitle() {
        // This would use LLM to generate a title based on conversation
        if self.title.isEmpty && !messages.isEmpty {
            self.title = "Chat \(DateFormatter.localizedString(from: createdAt, dateStyle: .short, timeStyle: .short))"
        }
    }
}
