// Import from LLMBuddyModels.swift
Last Modified: 2025-03-29
Dependencies:
- Foundation
Exports:
- ApiValidationResult struct
/

import Foundation

/// Result of API key validation
public struct ApiValidationResult {
    /// Indicates whether the API key is valid
    public var valid: Bool
    
    /// Usage statistics if validation was successful
    public var usageStats: ApiUsageStats?
    
    /// Error message if validation failed
    public var error: String?
    
    public init(valid: Bool, usageStats: ApiUsageStats? = nil, error: String? = nil) {
        self.valid = valid
        self.usageStats = usageStats
        self.error = error
    }
}
