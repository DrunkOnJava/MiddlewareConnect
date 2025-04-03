/**
@fileoverview Import file for API protocols
@module ApiKeyProtocolImports
Created: 2025-04-01
Last Modified: 2025-04-01
Dependencies:
- Foundation
Purpose:
This file ensures proper linking between ApiKeyStorageService protocol and its implementations.
Used to resolve compilation issues related to protocol visibility across module boundaries.
/

import Foundation

// Re-export the ApiKeyStorageService protocol
// This ensures the protocol is accessible from all files in the API folder
public typealias ApiKeyStorageService = LLMBuddy_iOS.ApiKeyStorageService
