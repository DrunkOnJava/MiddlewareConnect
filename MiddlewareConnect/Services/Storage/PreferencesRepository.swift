/**
 * @fileoverview Repository for managing user preferences
 * @module PreferencesRepository
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * - Combine
 * 
 * Exports:
 * - PreferencesRepository
 * 
 * Notes:
 * - Repository pattern for user preferences persistence
 * - Provides methods for reading and writing preferences
 * - Uses DatabaseService for storage
 * - Supports sync with CloudStorageManager
 */

import Foundation
import Combine

/// Repository for managing user preferences
class PreferencesRepository {
    // MARK: - Properties
    
    /// Shared instance
    static let shared = PreferencesRepository()
    
    /// Database service
    private let databaseService = DatabaseService.shared
    
    /// Cloud storage manager for sync
    private let cloudStorageManager = CloudStorageManager.shared
    
    /// In-memory cache of preferences
    private var preferencesCache: [String: Any] = [:]
    
    /// Publisher for preference changes
    private let preferencesChangedSubject = PassthroughSubject<[String], Never>()
    var preferencesChanged: AnyPublisher<[String], Never> {
        return preferencesChangedSubject.eraseToAnyPublisher()
    }
    
    /// Decoder for preferences
    private let decoder = JSONDecoder()
    
    /// Encoder for preferences
    private let encoder = JSONEncoder()
    
    // MARK: - Initialization
    
    private init() {
        // Load initial preferences
        loadPreferences()
    }
    
    // MARK: - Public Methods
    
    /// Get a preference value
    /// - Parameters:
    ///   - key: Preference key
    ///   - defaultValue: Default value if preference doesn't exist
    /// - Returns: Preference value
    func getPreference<T: Codable>(key: String, defaultValue: T) -> T {
        // Check cache first
        if let cachedValue = preferencesCache[key] as? T {
            return cachedValue
        }
        
        // Get from database
        var resultValue = defaultValue
        let semaphore = DispatchSemaphore(value: 0)
        
        getPreferenceAsync(key: key) { (result: Result<T?, Error>) in
            switch result {
            case .success(let value):
                if let value = value {
                    resultValue = value
                }
            case .failure:
                // Use default value on error
                break
            }
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 1.0)
        return resultValue
    }
    
    /// Get a preference value asynchronously
    /// - Parameters:
    ///   - key: Preference key
    ///   - completion: Completion handler with the result
    func getPreferenceAsync<T: Codable>(key: String, completion: @escaping (Result<T?, Error>) -> Void) {
        // Check cache first
        if let cachedValue = preferencesCache[key] as? T {
            completion(.success(cachedValue))
            return
        }
        
        // Query for the preference
        let query = "SELECT * FROM user_preferences WHERE key = '\(key)'"
        
        databaseService.executeRead(query: query) { (result: DatabaseResult<[UserPreferenceRecord]>) in
            switch result {
            case .success(let records):
                guard let record = records.first else {
                    completion(.success(nil))
                    return
                }
                
                do {
                    // Deserialize the value
                    let value = try self.decoder.decode(T.self, from: record.value)
                    
                    // Update cache
                    self.preferencesCache[key] = value
                    
                    completion(.success(value))
                } catch {
                    completion(.failure(DatabaseError.serializationError))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Set a preference value
    /// - Parameters:
    ///   - value: Preference value
    ///   - key: Preference key
    ///   - sync: Whether to sync with cloud
    ///   - completion: Optional completion handler
    func setPreference<T: Codable>(_ value: T, forKey key: String, sync: Bool = true, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        do {
            // Serialize the value
            let data = try encoder.encode(value)
            
            // Create the record
            let record = UserPreferenceRecord(
                key: key,
                value: data,
                updatedAt: Date()
            )
            
            // Check if the preference exists
            self.preferenceExists(key: key) { result in
                switch result {
                case .success(let exists):
                    if exists {
                        // Update existing preference
                        self.updatePreference(record) { result in
                            if case .success = result {
                                // Update cache
                                self.preferencesCache[key] = value
                                
                                // Notify about changes
                                self.preferencesChangedSubject.send([key])
                                
                                // Sync with cloud if requested
                                if sync {
                                    self.syncPreferenceToCloud(key: key, value: value)
                                }
                            }
                            
                            completion?(result)
                        }
                    } else {
                        // Insert new preference
                        self.insertPreference(record) { result in
                            if case .success = result {
                                // Update cache
                                self.preferencesCache[key] = value
                                
                                // Notify about changes
                                self.preferencesChangedSubject.send([key])
                                
                                // Sync with cloud if requested
                                if sync {
                                    self.syncPreferenceToCloud(key: key, value: value)
                                }
                            }
                            
                            completion?(result)
                        }
                    }
                case .failure(let error):
                    completion?(.failure(error))
                }
            }
        } catch {
            completion?(.failure(DatabaseError.serializationError))
        }
    }
    
    /// Remove a preference
    /// - Parameters:
    ///   - key: Preference key
    ///   - sync: Whether to sync with cloud
    ///   - completion: Optional completion handler
    func removePreference(forKey key: String, sync: Bool = true, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        // Delete query
        let query = "DELETE FROM user_preferences WHERE key = '\(key)'"
        
        databaseService.executeWrite(query: query) { result in
            switch result {
            case .success(let affectedRows):
                // Remove from cache
                self.preferencesCache.removeValue(forKey: key)
                
                // Notify about changes
                self.preferencesChangedSubject.send([key])
                
                // Sync with cloud if requested
                if sync {
                    self.removePreferenceFromCloud(key: key)
                }
                
                completion?(.success(affectedRows > 0))
                
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    /// Get all preference keys
    /// - Parameter completion: Completion handler with the result
    func getAllPreferenceKeys(completion: @escaping (Result<[String], Error>) -> Void) {
        // Query for all preference keys
        let query = "SELECT key FROM user_preferences"
        
        databaseService.executeRead(query: query) { (result: DatabaseResult<[KeyResult]>) in
            switch result {
            case .success(let records):
                let keys = records.map { $0.key }
                completion(.success(keys))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Synchronize preferences with cloud
    /// - Parameter completion: Optional completion handler
    func syncWithCloud(completion: ((Result<Bool, Error>) -> Void)? = nil) {
        // Check if cloud storage is available
        guard cloudStorageManager.isAvailable else {
            completion?(.failure(CloudStorageError.iCloudNotAvailable))
            return
        }
        
        // Get all preferences
        getAllPreferenceKeys { result in
            switch result {
            case .success(let keys):
                // Create a group to track all sync operations
                let group = DispatchGroup()
                var syncErrors: [Error] = []
                
                for key in keys {
                    group.enter()
                    
                    // Get the preference value
                    self.getPreferenceAsync(key: key) { (result: Result<Any?, Error>) in
                        switch result {
                        case .success(let value):
                            if let value = value {
                                // Sync to cloud
                                self.syncPreferenceToCloud(key: key, value: value) { result in
                                    if case .failure(let error) = result {
                                        syncErrors.append(error)
                                    }
                                    group.leave()
                                }
                            } else {
                                group.leave()
                            }
                        case .failure(let error):
                            syncErrors.append(error)
                            group.leave()
                        }
                    }
                }
                
                // Wait for all sync operations to complete
                group.notify(queue: .main) {
                    if syncErrors.isEmpty {
                        completion?(.success(true))
                    } else {
                        completion?(.failure(syncErrors.first!))
                    }
                }
                
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
    
    /// Clear the preferences cache
    func clearCache() {
        preferencesCache.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Load all preferences into the cache
    private func loadPreferences() {
        // Query for all preferences
        let query = "SELECT * FROM user_preferences"
        
        databaseService.executeRead(query: query) { (result: DatabaseResult<[UserPreferenceRecord]>) in
            switch result {
            case .success(let records):
                for record in records {
                    do {
                        // Try to decode as a generic JSON value
                        let value = try JSONSerialization.jsonObject(with: record.value)
                        
                        // Store in cache
                        self.preferencesCache[record.key] = value
                    } catch {
                        print("Failed to deserialize preference: \(error.localizedDescription)")
                    }
                }
                
            case .failure(let error):
                print("Failed to load preferences: \(error.localizedDescription)")
            }
        }
    }
    
    /// Check if a preference exists
    /// - Parameters:
    ///   - key: Preference key
    ///   - completion: Completion handler with the result
    private func preferenceExists(key: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let query = "SELECT COUNT(*) as count FROM user_preferences WHERE key = '\(key)'"
        
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
    
    /// Insert a new preference
    /// - Parameters:
    ///   - record: Preference record
    ///   - completion: Completion handler with the result
    private func insertPreference(_ record: UserPreferenceRecord, completion: @escaping (Result<Bool, Error>) -> Void) {
        let query = """
        INSERT INTO user_preferences (key, value, updated_at)
        VALUES ('\(record.key)', ?, \(Int(record.updatedAt.timeIntervalSince1970)))
        """
        
        let parameters: [String: Any] = ["1": record.value]
        
        databaseService.executeWrite(query: query, parameters: parameters) { result in
            switch result {
            case .success(let affectedRows):
                completion(.success(affectedRows > 0))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Update an existing preference
    /// - Parameters:
    ///   - record: Preference record
    ///   - completion: Completion handler with the result
    private func updatePreference(_ record: UserPreferenceRecord, completion: @escaping (Result<Bool, Error>) -> Void) {
        let query = """
        UPDATE user_preferences
        SET value = ?, updated_at = \(Int(record.updatedAt.timeIntervalSince1970))
        WHERE key = '\(record.key)'
        """
        
        let parameters: [String: Any] = ["1": record.value]
        
        databaseService.executeWrite(query: query, parameters: parameters) { result in
            switch result {
            case .success(let affectedRows):
                completion(.success(affectedRows > 0))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Sync a preference to cloud storage
    /// - Parameters:
    ///   - key: Preference key
    ///   - value: Preference value
    ///   - completion: Optional completion handler
    private func syncPreferenceToCloud<T: Codable>(key: String, value: T, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        // Check if cloud storage is available
        guard cloudStorageManager.isAvailable else {
            completion?(.failure(CloudStorageError.iCloudNotAvailable))
            return
        }
        
        do {
            // Serialize the preference
            let data = try JSONEncoder().encode(value)
            
            // Create a cloud document
            let document = CloudDocument.create(
                name: "preference_\(key)",
                type: .settings,
                data: data
            )
            
            // Save to cloud
            cloudStorageManager.saveDocument(document) { success, error in
                if success {
                    completion?(.success(true))
                } else if let error = error {
                    completion?(.failure(error))
                } else {
                    completion?(.failure(CloudStorageError.unknown))
                }
            }
        } catch {
            completion?(.failure(DatabaseError.serializationError))
        }
    }
    
    /// Remove a preference from cloud storage
    /// - Parameters:
    ///   - key: Preference key
    ///   - completion: Optional completion handler
    private func removePreferenceFromCloud(key: String, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        // Check if cloud storage is available
        guard cloudStorageManager.isAvailable else {
            completion?(.failure(CloudStorageError.iCloudNotAvailable))
            return
        }
        
        // Fetch all documents
        cloudStorageManager.fetchAllDocuments { documents, error in
            if let error = error {
                completion?(.failure(error))
                return
            }
            
            // Find the preference document
            if let documents = documents, let document = documents.first(where: { $0.name == "preference_\(key)" }) {
                // Delete the document
                cloudStorageManager.deleteDocument(document) { success, error in
                    if success {
                        completion?(.success(true))
                    } else if let error = error {
                        completion?(.failure(error))
                    } else {
                        completion?(.failure(CloudStorageError.unknown))
                    }
                }
            } else {
                // Document not found, consider it a success
                completion?(.success(true))
            }
        }
    }
}

/// Helper struct for count queries
private struct CountResult: Codable {
    let count: Int
}

/// Helper struct for key queries
private struct KeyResult: Codable {
    let key: String
}
