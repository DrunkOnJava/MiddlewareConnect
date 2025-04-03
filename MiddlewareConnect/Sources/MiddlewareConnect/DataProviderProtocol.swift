/**
@fileoverview Protocol for data providers
@module DataProviderProtocol
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- Foundation
Exports:
- DataProviderProtocol
/

import Foundation
import Combine

/// Protocol defining the interface for data providers
protocol DataProviderProtocol {
    /// Save a conversation
    func saveConversation(_ conversation: ChatConversation)
    
    /// Get a conversation by ID
    func getConversation(id: UUID) -> ChatConversation?
    
    /// Delete a conversation
    func deleteConversation(id: UUID)
    
    /// Get all conversations
    func getAllConversations() -> [ChatConversation]
    
    /// Publisher for conversation changes
    var conversationsPublisher: AnyPublisher<[ChatConversation], Never> { get }
}