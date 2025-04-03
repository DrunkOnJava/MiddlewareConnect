import Foundation

/// Protocol for API key storage service
public protocol ApiKeyStorageService {
    /// Store API key securely
    /// - Parameters:
    ///   - identifier: The identifier for the API key
    ///   - apiKey: The API key to store
    /// - Returns: Whether the operation was successful
    func storeApiKey(_ identifier: String, apiKey: String) -> Bool
    
    /// Retrieve API key
    /// - Parameter identifier: The identifier for the API key
    /// - Returns: The API key, or nil if not found
    func retrieveApiKey(_ identifier: String) -> String?
    
    /// Delete API key
    /// - Parameter identifier: The identifier for the API key
    /// - Returns: Whether the operation was successful
    func deleteApiKey(_ identifier: String) -> Bool
}

/// Extended API key storage service with error handling
public protocol AdvancedApiKeyStorageService: ApiKeyStorageService {
    /// Error type for API key storage operations
    associatedtype StorageError: Error
    
    /// Store API key securely with error handling
    /// - Parameters:
    ///   - identifier: The identifier for the API key
    ///   - apiKey: The API key to store
    /// - Throws: StorageError if operation fails
    func storeApiKeyWithError(_ identifier: String, apiKey: String) throws
    
    /// Retrieve API key with error handling
    /// - Parameter identifier: The identifier for the API key
    /// - Returns: The API key
    /// - Throws: StorageError if operation fails
    func retrieveApiKeyWithError(_ identifier: String) throws -> String
}
