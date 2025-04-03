import Foundation
import Security

/// Protocol for API key storage service
/// Temporary definition until module resolution issues are fixed
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

/// Service for secure storage of sensitive data using Keychain
public class KeychainService: ApiKeyStorageService {
    // MARK: - Properties
    
    /// Service name used for Keychain items - typically the app bundle ID
    private let serviceName: String
    
    // MARK: - Initialization
    
    /// Initialize with service name
    /// - Parameter serviceName: The service name for Keychain entries
    public init(serviceName: String = Bundle.main.bundleIdentifier ?? "com.llmbuddy.app") {
        self.serviceName = serviceName
    }
    
    // MARK: - ApiKeyStorageService Implementation
    
    /// Store an API key in the Keychain
    /// - Parameters:
    ///   - identifier: The identifier for the API key
    ///   - apiKey: The API key to store
    /// - Returns: Whether the operation was successful
    public func storeApiKey(_ identifier: String, apiKey: String) -> Bool {
        guard let data = apiKey.data(using: .utf8) else {
            return false
        }
        
        // Create query
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: identifier,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
            kSecAttrDescription: "API Key for \(identifier)"
        ]
        
        // Delete any existing key with the same identifier
        SecItemDelete(query as CFDictionary)
        
        // Add the new key
        let status = SecItemAdd(query as CFDictionary, nil)
        
        return status == errSecSuccess
    }
    
    /// Retrieve an API key from the Keychain
    /// - Parameter identifier: The identifier for the API key
    /// - Returns: The API key, or nil if not found
    public func retrieveApiKey(_ identifier: String) -> String? {
        // Create query
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: identifier,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        // Query the Keychain
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
    
    /// Delete an API key from the Keychain
    /// - Parameter identifier: The identifier for the API key
    /// - Returns: Whether the operation was successful
    public func deleteApiKey(_ identifier: String) -> Bool {
        // Create query
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: identifier
        ]
        
        // Delete the key
        let status = SecItemDelete(query as CFDictionary)
        
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - Extension for Error Handling

extension KeychainService {
    /// Keychain error enum for more detailed error handling
    public enum KeychainError: Error {
        case dataConversionError
        case unhandledError(status: OSStatus)
        case itemNotFound
        
        var localizedDescription: String {
            switch self {
            case .dataConversionError:
                return "Failed to convert string to data"
            case .unhandledError(let status):
                return "Keychain error with status: \(status)"
            case .itemNotFound:
                return "Item not found in keychain"
            }
        }
    }
    
    /// Store API key with detailed error handling
    /// - Parameters:
    ///   - identifier: The identifier for the API key
    ///   - apiKey: The API key to store
    /// - Throws: KeychainError if operation fails
    public func storeApiKeyWithError(_ identifier: String, apiKey: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            throw KeychainError.dataConversionError
        }
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: identifier,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
            kSecAttrDescription: "API Key for \(identifier)"
        ]
        
        // Delete any existing key
        SecItemDelete(query as CFDictionary)
        
        // Add the new key
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    /// Retrieve API key with detailed error handling
    /// - Parameter identifier: The identifier for the API key
    /// - Returns: The API key
    /// - Throws: KeychainError if operation fails
    public func retrieveApiKeyWithError(_ identifier: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: identifier,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            } else {
                throw KeychainError.unhandledError(status: status)
            }
        }
        
        guard let data = dataTypeRef as? Data, 
              let apiKey = String(data: data, encoding: .utf8) else {
            throw KeychainError.dataConversionError
        }
        
        return apiKey
    }
}
