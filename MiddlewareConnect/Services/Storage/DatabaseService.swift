/**
 * @fileoverview SQLite database service via MCP
 * @module DatabaseService
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * - Combine
 * 
 * Exports:
 * - DatabaseService
 * 
 * Notes:
 * - Provides interface to SQLite MCP server
 * - Manages data models for app persistence
 * - Handles connection, schema, and transactions
 */

import Foundation
import Combine

/// Result of a database operation
enum DatabaseResult<T> {
    case success(T)
    case failure(Error)
}

/// Error types for database operations
enum DatabaseError: Error, LocalizedError {
    case connectionFailed
    case queryFailed(String)
    case insertFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case schemaError(String)
    case noResults
    case serializationError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to the database"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        case .insertFailed(let message):
            return "Insert operation failed: \(message)"
        case .updateFailed(let message):
            return "Update operation failed: \(message)"
        case .deleteFailed(let message):
            return "Delete operation failed: \(message)"
        case .schemaError(let message):
            return "Schema error: \(message)"
        case .noResults:
            return "No results found"
        case .serializationError:
            return "Failed to serialize or deserialize data"
        case .unknown:
            return "An unknown database error occurred"
        }
    }
}

/// Type of database cache
enum CacheType {
    case memory
    case persistent
    case none
}

/// Service for managing SQLite database operations via MCP
class DatabaseService {
    // MARK: - Singleton
    
    /// Shared instance
    static let shared = DatabaseService()
    
    // MARK: - Properties
    
    /// Whether the database is connected
    private(set) var isConnected = false
    
    /// Publisher for database connection status
    private let connectionStatusSubject = CurrentValueSubject<Bool, Never>(false)
    var connectionStatus: AnyPublisher<Bool, Never> {
        return connectionStatusSubject.eraseToAnyPublisher()
    }
    
    /// Cache for recent query results
    private var queryCache: [String: (Any, Date)] = [:]
    
    /// Cache expiration time (in seconds)
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    /// Cache type
    private let cacheType: CacheType = .memory
    
    // MARK: - Initialization
    
    private init() {
        // Initialize and connect to the database
        initializeDatabase()
    }
    
    // MARK: - Public Methods
    
    /// Execute a read query (SELECT)
    /// - Parameters:
    ///   - query: SQL query to execute
    ///   - parameters: Optional parameters for the query
    ///   - useCache: Whether to use cache for this query
    ///   - completion: Completion handler with the result
    func executeRead<T: Codable>(
        query: String,
        parameters: [String: Any]? = nil,
        useCache: Bool = true,
        completion: @escaping (DatabaseResult<[T]>) -> Void
    ) {
        // Check if result is in cache
        if useCache, cacheType != .none {
            let cacheKey = generateCacheKey(query: query, parameters: parameters)
            if let (cachedData, timestamp) = queryCache[cacheKey] {
                // Check if cache is still valid
                if Date().timeIntervalSince(timestamp) < cacheExpirationTime {
                    if let results = cachedData as? [T] {
                        completion(.success(results))
                        return
                    }
                } else {
                    // Cache expired, remove it
                    queryCache.removeValue(forKey: cacheKey)
                }
            }
        }
        
        // Execute the query using the MCP tool
        executeMCPQuery(query: query, parameters: parameters) { result in
            switch result {
            case .success(let jsonData):
                do {
                    // Parse the JSON data into the desired type
                    let decoder = JSONDecoder()
                    let results = try decoder.decode([T].self, from: jsonData)
                    
                    // Store in cache if needed
                    if useCache, self.cacheType != .none {
                        let cacheKey = self.generateCacheKey(query: query, parameters: parameters)
                        self.queryCache[cacheKey] = (results, Date())
                    }
                    
                    completion(.success(results))
                } catch {
                    completion(.failure(DatabaseError.serializationError))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Execute a write query (INSERT, UPDATE, DELETE)
    /// - Parameters:
    ///   - query: SQL query to execute
    ///   - parameters: Optional parameters for the query
    ///   - completion: Completion handler with the result
    func executeWrite(
        query: String,
        parameters: [String: Any]? = nil,
        completion: @escaping (DatabaseResult<Int>) -> Void
    ) {
        // Execute the query using the MCP tool
        executeMCPQuery(query: query, parameters: parameters) { result in
            switch result {
            case .success(let jsonData):
                do {
                    // Extract the number of affected rows from the response
                    if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let affectedRows = json["affectedRows"] as? Int {
                        completion(.success(affectedRows))
                    } else {
                        completion(.success(0)) // Default to 0 affected rows
                    }
                } catch {
                    completion(.failure(DatabaseError.serializationError))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Create a table in the database
    /// - Parameters:
    ///   - tableName: Name of the table
    ///   - schema: Schema definition SQL
    ///   - completion: Completion handler with the result
    func createTable(
        tableName: String,
        schema: String,
        completion: @escaping (DatabaseResult<Bool>) -> Void
    ) {
        // Execute the create table query
        let createTableQuery = "CREATE TABLE IF NOT EXISTS \(tableName) (\(schema))"
        
        executeMCPQuery(query: createTableQuery, parameters: nil) { result in
            switch result {
            case .success(_):
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Check if a table exists
    /// - Parameters:
    ///   - tableName: Name of the table
    ///   - completion: Completion handler with the result
    func tableExists(
        tableName: String,
        completion: @escaping (DatabaseResult<Bool>) -> Void
    ) {
        // Query sqlite_master to check if the table exists
        let query = "SELECT name FROM sqlite_master WHERE type='table' AND name='\(tableName)'"
        
        executeMCPQuery(query: query, parameters: nil) { result in
            switch result {
            case .success(let jsonData):
                do {
                    // Check if there are any results
                    if let json = try JSONSerialization.jsonObject(with: jsonData) as? [Any],
                       !json.isEmpty {
                        completion(.success(true))
                    } else {
                        completion(.success(false))
                    }
                } catch {
                    completion(.failure(DatabaseError.serializationError))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Clear the query cache
    func clearCache() {
        queryCache.removeAll()
    }
    
    /// Set the cache type
    /// - Parameter type: Cache type
    func setCacheType(_ type: CacheType) {
        // Clear existing cache if changing types
        if type != cacheType {
            clearCache()
        }
        
        // Set the new cache type
        switch type {
        case .memory:
            print("Using in-memory cache")
        case .persistent:
            print("Using persistent cache") // Would implement disk storage
        case .none:
            print("Cache disabled")
        }
    }
    
    // MARK: - Private Methods
    
    /// Initialize the database
    private func initializeDatabase() {
        // Check if the MCP SQLite server is available
        // For now, we'll consider it connected
        isConnected = true
        connectionStatusSubject.send(isConnected)
        
        // Create initial tables if needed
        initializeTables()
    }
    
    /// Initialize the database tables
    private func initializeTables() {
        // Create conversations table
        createTable(
            tableName: "conversations",
            schema: """
                id TEXT PRIMARY KEY,
                title TEXT,
                model TEXT,
                created_at INTEGER,
                updated_at INTEGER,
                data BLOB
            """
        ) { result in
            switch result {
            case .success(_):
                print("Conversations table created successfully")
            case .failure(let error):
                print("Failed to create conversations table: \(error.localizedDescription)")
            }
        }
        
        // Create user_preferences table
        createTable(
            tableName: "user_preferences",
            schema: """
                key TEXT PRIMARY KEY,
                value BLOB,
                updated_at INTEGER
            """
        ) { result in
            switch result {
            case .success(_):
                print("User preferences table created successfully")
            case .failure(let error):
                print("Failed to create user preferences table: \(error.localizedDescription)")
            }
        }
        
        // Create message_cache table
        createTable(
            tableName: "message_cache",
            schema: """
                id TEXT PRIMARY KEY,
                conversation_id TEXT,
                role TEXT,
                content TEXT,
                created_at INTEGER,
                FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
            """
        ) { result in
            switch result {
            case .success(_):
                print("Message cache table created successfully")
            case .failure(let error):
                print("Failed to create message cache table: \(error.localizedDescription)")
            }
        }
    }
    
    /// Execute a query using the MCP SQLite server
    /// - Parameters:
    ///   - query: SQL query to execute
    ///   - parameters: Optional parameters for the query
    ///   - completion: Completion handler with the result
    private func executeMCPQuery(
        query: String,
        parameters: [String: Any]?,
        completion: @escaping (DatabaseResult<Data>) -> Void
    ) {
        // Determine which MCP tool to use based on the query type
        let toolName: String
        
        if query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("select") {
            toolName = "read_query"
        } else {
            toolName = "write_query"
        }
        
        // Prepare query JSON
        var queryJSON: [String: Any] = ["query": query]
        
        // Add parameters if provided
        if let parameters = parameters {
            queryJSON["parameters"] = parameters
        }
        
        // Convert query JSON to a string
        guard let queryJSONData = try? JSONSerialization.data(withJSONObject: queryJSON),
              let queryJSONString = String(data: queryJSONData, encoding: .utf8) else {
            completion(.failure(DatabaseError.serializationError))
            return
        }
        
        // Display the query for debugging (remove in production)
        print("Executing SQL: \(query)")
        
        // In a real implementation, this would use the MCP tool
        // For now, we'll simulate the response based on the query
        simulateMCPResponse(toolName: toolName, query: query, completion: completion)
    }
    
    /// Simulate MCP response for testing
    /// - Parameters:
    ///   - toolName: MCP tool name
    ///   - query: SQL query
    ///   - completion: Completion handler with the result
    private func simulateMCPResponse(
        toolName: String,
        query: String,
        completion: @escaping (DatabaseResult<Data>) -> Void
    ) {
        // This is a placeholder for actual MCP tool implementation
        // In a real app, this would use the MCP SDK to call the MCP SQLite server
        
        // Simulate a delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            // Process based on the query type
            if toolName == "read_query" {
                if query.contains("sqlite_master") {
                    // Table exists query
                    let response: [[String: Any]] = [["name": "conversations"]]
                    if let jsonData = try? JSONSerialization.data(withJSONObject: response) {
                        completion(.success(jsonData))
                    } else {
                        completion(.failure(DatabaseError.serializationError))
                    }
                } else if query.contains("conversations") {
                    // Conversation query
                    let sampleConversations: [[String: Any]] = [
                        [
                            "id": "conv1",
                            "title": "Sample Conversation 1",
                            "model": "claude3-sonnet",
                            "created_at": Int(Date().timeIntervalSince1970),
                            "updated_at": Int(Date().timeIntervalSince1970)
                        ],
                        [
                            "id": "conv2",
                            "title": "Sample Conversation 2",
                            "model": "claude3-haiku",
                            "created_at": Int(Date().timeIntervalSince1970 - 3600),
                            "updated_at": Int(Date().timeIntervalSince1970 - 1800)
                        ]
                    ]
                    
                    if let jsonData = try? JSONSerialization.data(withJSONObject: sampleConversations) {
                        completion(.success(jsonData))
                    } else {
                        completion(.failure(DatabaseError.serializationError))
                    }
                } else if query.contains("user_preferences") {
                    // User preferences query
                    let samplePreferences: [[String: Any]] = [
                        [
                            "key": "default_model",
                            "value": "claude3-sonnet",
                            "updated_at": Int(Date().timeIntervalSince1970)
                        ],
                        [
                            "key": "theme",
                            "value": "dark",
                            "updated_at": Int(Date().timeIntervalSince1970 - 86400)
                        ]
                    ]
                    
                    if let jsonData = try? JSONSerialization.data(withJSONObject: samplePreferences) {
                        completion(.success(jsonData))
                    } else {
                        completion(.failure(DatabaseError.serializationError))
                    }
                } else {
                    // Generic empty result
                    if let jsonData = try? JSONSerialization.data(withJSONObject: []) {
                        completion(.success(jsonData))
                    } else {
                        completion(.failure(DatabaseError.serializationError))
                    }
                }
            } else { // write_query
                // Simulate a successful write operation
                let response: [String: Any] = ["affectedRows": 1]
                if let jsonData = try? JSONSerialization.data(withJSONObject: response) {
                    completion(.success(jsonData))
                } else {
                    completion(.failure(DatabaseError.serializationError))
                }
            }
        }
    }
    
    /// Generate a cache key for a query
    /// - Parameters:
    ///   - query: SQL query
    ///   - parameters: Optional parameters
    /// - Returns: Cache key string
    private func generateCacheKey(query: String, parameters: [String: Any]?) -> String {
        var key = query
        
        if let parameters = parameters {
            if let parametersData = try? JSONSerialization.data(withJSONObject: parameters),
               let parametersString = String(data: parametersData, encoding: .utf8) {
                key += "_" + parametersString
            }
        }
        
        return key
    }
}

// MARK: - Data Models

/// Protocol for database storable models
protocol DatabaseStorable: Codable {
    /// Get the database table name for this model
    static var tableName: String { get }
    
    /// Get the primary key for this instance
    var primaryKey: String { get }
    
    /// Convert to a dictionary for storage
    func toDictionary() -> [String: Any]
}

/// Conversation model for database storage
struct ConversationRecord: DatabaseStorable {
    /// Unique ID
    let id: String
    
    /// Conversation title
    let title: String
    
    /// Model used for the conversation
    let model: String
    
    /// When the conversation was created
    let createdAt: Date
    
    /// When the conversation was last updated
    let updatedAt: Date
    
    /// Serialized conversation data
    let data: Data
    
    /// Table name
    static var tableName: String { "conversations" }
    
    /// Primary key
    var primaryKey: String { id }
    
    /// Convert to dictionary
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "model": model,
            "created_at": Int(createdAt.timeIntervalSince1970),
            "updated_at": Int(updatedAt.timeIntervalSince1970),
            "data": data
        ]
    }
}

/// User preference model for database storage
struct UserPreferenceRecord: DatabaseStorable {
    /// Preference key
    let key: String
    
    /// Serialized preference value
    let value: Data
    
    /// When the preference was last updated
    let updatedAt: Date
    
    /// Table name
    static var tableName: String { "user_preferences" }
    
    /// Primary key
    var primaryKey: String { key }
    
    /// Convert to dictionary
    func toDictionary() -> [String: Any] {
        return [
            "key": key,
            "value": value,
            "updated_at": Int(updatedAt.timeIntervalSince1970)
        ]
    }
}

/// Message cache model for database storage
struct MessageCacheRecord: DatabaseStorable {
    /// Unique ID
    let id: String
    
    /// Parent conversation ID
    let conversationId: String
    
    /// Message role (user/assistant)
    let role: String
    
    /// Message content
    let content: String
    
    /// When the message was created
    let createdAt: Date
    
    /// Table name
    static var tableName: String { "message_cache" }
    
    /// Primary key
    var primaryKey: String { id }
    
    /// Convert to dictionary
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "conversation_id": conversationId,
            "role": role,
            "content": content,
            "created_at": Int(createdAt.timeIntervalSince1970)
        ]
    }
}
