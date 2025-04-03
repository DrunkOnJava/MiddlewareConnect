/**
 * @fileoverview Chat data persistence provider
 * @module ChatDataProvider
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * 
 * Exports:
 * - ChatDataProvider
 */

import Foundation
import Combine

/// Data provider for chat conversations persistent storage
class ChatDataProvider: DataProviderProtocol {
    // MARK: - Properties
    
    /// Shared instance for singleton pattern
    static let shared = ChatDataProvider()
    
    /// In-memory cache of conversations
    private var conversationsCache: [UUID: ChatConversation] = [:]
    
    /// Subject to publish conversation changes
    private let conversationsSubject = PassthroughSubject<[ChatConversation], Never>()
    
    /// Publisher for conversation changes
    var conversationsPublisher: AnyPublisher<[ChatConversation], Never> {
        conversationsSubject.eraseToAnyPublisher()
    }
    
    /// File URL for persistent storage
    private var storeURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("conversations.json")
    }
    
    // MARK: - Initialization
    
    private init() {
        loadConversations()
    }
    
    // MARK: - DataProviderProtocol Methods
    
    /// Save a conversation
    func saveConversation(_ conversation: ChatConversation) {
        // Update cache
        conversationsCache[conversation.id] = conversation
        
        // Persist to disk
        saveToFile()
        
        // Publish changes
        notifyChanges()
    }
    
    /// Get a conversation by ID
    func getConversation(id: UUID) -> ChatConversation? {
        return conversationsCache[id]
    }
    
    /// Delete a conversation
    func deleteConversation(id: UUID) {
        // Remove from cache
        conversationsCache.removeValue(forKey: id)
        
        // Persist to disk
        saveToFile()
        
        // Publish changes
        notifyChanges()
    }
    
    /// Get all conversations
    func getAllConversations() -> [ChatConversation] {
        return Array(conversationsCache.values)
            .sorted { $0.lastUpdated > $1.lastUpdated }
    }
    
    // MARK: - Private Methods
    
    /// Load conversations from persistent storage
    private func loadConversations() {
        guard FileManager.default.fileExists(atPath: storeURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: storeURL)
            let decoder = JSONDecoder()
            let conversations = try decoder.decode([ChatConversation].self, from: data)
            
            // Update cache
            conversationsCache = Dictionary(uniqueKeysWithValues: conversations.map { ($0.id, $0) })
        } catch {
            // Log error but continue with empty cache
            print("Failed to load conversations: \(error)")
        }
    }
    
    /// Save conversations to persistent storage
    private func saveToFile() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(getAllConversations())
            try data.write(to: storeURL)
        } catch {
            print("Failed to save conversations: \(error)")
        }
    }
    
    /// Notify subscribers of changes
    private func notifyChanges() {
        conversationsSubject.send(getAllConversations())
    }
}
