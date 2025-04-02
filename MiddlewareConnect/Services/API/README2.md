# API Services

This directory contains services related to API integrations and secure storage of API keys.

## KeychainService

The `KeychainService` provides a secure way to store sensitive data like API keys in the device's Keychain.

### Features

- Securely store, retrieve, and delete API keys
- Service name-based isolation to prevent conflicts
- Error handling with detailed error types
- Proper memory management for sensitive data
- Comprehensive documentation and test coverage

### Usage

```swift
// Create a KeychainService instance
let keychainService = KeychainService()

// Or with a custom service name
let customKeychainService = KeychainService(serviceName: "com.myapp.customservice")

// Basic operations
let apiKey = "your-api-key-here"
let identifier = "anthropic_api_key"

// Store API key
if keychainService.storeApiKey(identifier, apiKey: apiKey) {
    print("API key stored successfully")
} else {
    print("Failed to store API key")
}

// Retrieve API key
if let storedKey = keychainService.retrieveApiKey(identifier) {
    print("Retrieved API key: \(storedKey)")
} else {
    print("API key not found")
}

// Delete API key
if keychainService.deleteApiKey(identifier) {
    print("API key deleted successfully")
} else {
    print("Failed to delete API key")
}

// Advanced error handling
do {
    try keychainService.storeApiKeyWithError(identifier, apiKey: apiKey)
    print("API key stored successfully")
    
    let storedKey = try keychainService.retrieveApiKeyWithError(identifier)
    print("Retrieved API key: \(storedKey)")
} catch let error as KeychainService.KeychainError {
    switch error {
    case .dataConversionError:
        print("Failed to convert string to data")
    case .unhandledError(let status):
        print("Keychain error with status: \(status)")
    case .itemNotFound:
        print("API key not found")
    }
} catch {
    print("Unexpected error: \(error)")
}
```

### Implementation Details

The `KeychainService` uses the Security framework to interact with the Keychain. It follows these best practices:

1. Properly formatting Keychain queries
2. Adding service name for isolation
3. Setting appropriate accessibility options
4. Adding descriptive labels for stored items
5. Proper error handling
6. Cleanup of sensitive data

## ApiKeyStorageService Protocol

This protocol defines the interface for API key storage services. It allows for different implementations (like `KeychainService`) to be used interchangeably.

### Basic Interface

```swift
public protocol ApiKeyStorageService {
    func storeApiKey(_ identifier: String, apiKey: String) -> Bool
    func retrieveApiKey(_ identifier: String) -> String?
    func deleteApiKey(_ identifier: String) -> Bool
}
```

### Advanced Interface

```swift
public protocol AdvancedApiKeyStorageService: ApiKeyStorageService {
    associatedtype StorageError: Error
    
    func storeApiKeyWithError(_ identifier: String, apiKey: String) throws
    func retrieveApiKeyWithError(_ identifier: String) throws -> String
}
```

## Test Coverage

The `KeychainService` implementation is covered by comprehensive unit tests in `KeychainServiceTests.swift`. The tests validate:

- Basic storage, retrieval, and deletion operations
- Error handling
- Edge cases like overwriting existing keys
- Multiple keys with different identifiers

## Security Considerations

When working with sensitive data like API keys:

- Never log API keys or other sensitive information
- Always use the KeychainService for storage, not UserDefaults or other insecure storage
- Consider integrating with device biometrics for additional security
- Ensure proper memory management for sensitive data
- Validate and sanitize inputs
