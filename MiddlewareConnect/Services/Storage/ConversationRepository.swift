/**
 * @fileoverview Repository for managing conversation data
 * @module ConversationRepository
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * - Combine
 * 
 * Exports:
 * - ConversationRepository
 * 
 * Notes:
 * - Repository pattern for conversation persistence
 * - Provides CRUD operations for conversations
 * - Uses DatabaseService for storage
 */

import Foundation
import Combine

/// Repository for managing conversation storage and retrieval
class ConversationRepository {
    // MARK: - Properties
    
    /// Shared instance
    static let shared = ConversationRepository()
    
    /// Database service
    private let databaseService = DatabaseService.shared
    
    /// Cache of loaded conversations
    private var conversationCache: [String: Conversation] = [:]
    
    /// Publisher for conversation changes
    private let conversationChangesSubject = PassthroughSubject<[String], Never>()
    var conversationChanges: AnyPublisher<[String], Never> {
        return conversationChangesSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    private init() {
        // Initialize
    }
    
    // MARK: - Public Methods
    
    /// Get all conversations
    /// - Parameter completion: Completion handler with the result
    func getAllConversations(completion: @escaping (Result<[Conversation], Error>) -> Void) {
        // Query for all conversations
        let query = "SELECT * FROM conversations ORDER BY updated_at DESC"
        
        databaseService.executeRead(query: query) { (result: DatabaseResult<[ConversationRecord]>) in
            switch result {
            case .success(let records):
                let conversations = records.compactMap { self.recordToConversation($0) }
                
                // Update cache
                for conversation in conversations {
                    self.conversationCache[conversation.id] = conversation
                }
                
                completion(.success(conversations))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get a conversation by ID
    /// - Parameters:
    ///   - id: Conversation ID
    ///   - completion: Completion handler with the result
    func getConversation(id: String, completion: @escaping (Result<Conversation, Error>) -> Void) {
        // Check cache first
        if let cachedConversation = conversationCache[id] {
            completion(.success(cachedConversation))
            return
        }
        
        // Query for the conversation
        let query = "SELECT * FROM conversations WHERE id = '\(id)'"
        
        databaseService.executeRead(query: query) { (result: DatabaseResult<[ConversationRecord]>) in
            switch result {
            case .success(let records):
                guard let record = records.first,
                      let conversation = self.recordToConversation(record) else {
                    completion(.failure(DatabaseError.noResults))
                    return
                }
                
                // Update cache
                self.conversationCache[conversation.id] = conversation
                
                completion(.success(conversation))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Save a conversation
    /// - Parameters:
    ///   - conversation: Conversation to save
    ///   - completion: Completion handler with the result
    func saveConversation(_ conversation: Conversation, completion: @escaping (Result<Bool, Error>) -> Void) {
        // Serialize conversation
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(conversation)
            
            // Create record
            let record = ConversationRecord(
                id: conversation.id,
                title: conversation.title,
                model: conversation.model.id,
                createdAt: conversation.createdAt,
                updatedAt: conversation.updatedAt,
                data: data
            )
            
            // Check if the conversation exists
            self.conversationExists(id: conversation.id) { result in
                switch result {
                case .success(let exists):
                    if exists {
                        // Update existing conversation
                        self.updateConversation(record, completion: completion)
                    } else {
                        // Insert new conversation
                        self.insertConversation(record, completion: completion)
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            
            // Update cache
            self.conversationCache[conversation.id] = conversation
            
            // Notify about changes
            self.conversationChangesSubject.send([conversation.id])
            
        } catch {
            completion(.failure(DatabaseError.serializationError))
        }
    }
    
    /// Delete a conversation
    /// - Parameters:
    ///   - id: Conversation ID
    ///   - completion: Completion handler with the result
    func deleteConversation(id: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        // Delete query
        let query = "DELETE FROM conversations WHERE id = '\(id)'"
        
        databaseService.executeWrite(query: query) { result in
            switch result {
            case .success(let affectedRows):
                // Remove from cache
                self.conversationCache.removeValue(forKey: id)
                
                // Notify about changes
                self.conversationChangesSubject.send([id])
                
                completion(.success(affectedRows > 0))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Clear the conversation cache
    func clearCache() {
        conversationCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Convert a database record to a conversation
    /// - Parameter record: Conversation record
    /// - Returns: Conversation object
    private func recordToConversation(_ record: ConversationRecord) -> Conversation? {
        do {
            // Deserialize conversation data
            let decoder = JSONDecoder()
            return try decoder.decode(Conversation.self, from: record.data)
        } catch {
            print("Failed to deserialize conversation: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Check if a conversation exists
    /// - Parameters:
    ///   - id: Conversation ID
    ///   - completion: Completion handler with the result
    private func conversationExists(id: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let query = "SELECT COUNT(*) as count FROM conversations WHERE id = '\(id)'"
        
        databaseService.executeRead(query: query) { (result: DatabaseResult<[CountResult]>) in
            switch result {
            case .success(let records):
                if let record = records.first {
                    completion(.success(record.count > 0))
                } else {
                    completion(.success(false))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Insert a new conversation
    /// - Parameters:
    ///   - record: Conversation record
    ///   - completion: Completion handler with the result
    private func insertConversation(_ record: ConversationRecord, completion: @escaping (Result<Bool, Error>) -> Void) {
        let query = """
        INSERT INTO conversations (id, title, model, created_at, updated_at, data)
        VALUES ('\(record.id)', '\(record.title)', '\(record.model)', \(Int(record.createdAt.timeIntervalSince1970)), \(Int(record.updatedAt.timeIntervalSince1970)), ?)
        """
        
        let parameters: [String: Any] = ["1": record.data]
        
        databaseService.executeWrite(query: query, parameters: parameters) { result in
            switch result {
            case .success(let affectedRows):
                completion(.success(affectedRows > 0))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Update an existing conversation
    /// - Parameters:
    ///   - record: Conversation record
    ///   - completion: Completion handler with the result
    private func updateConversation(_ record: ConversationRecord, completion: @escaping (Result<Bool, Error>) -> Void) {
        let query = """
        UPDATE conversations
        SET title = '\(record.title)', model = '\(record.model)', updated_at = \(Int(record.updatedAt.timeIntervalSince1970)), data = ?
        WHERE id = '\(record.id)'
        """
        
        let parameters: [String: Any] = ["1": record.data]
        
        databaseService.executeWrite(query: query, parameters: parameters) { result in
            switch result {
            case .success(let affectedRows):
                completion(.success(affectedRows > 0))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

/// Helper struct for count queries
private struct CountResult: Codable {
    let count: Int
}
