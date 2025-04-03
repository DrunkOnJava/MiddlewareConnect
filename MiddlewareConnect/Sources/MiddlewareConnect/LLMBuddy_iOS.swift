/**
@fileoverview LLMBuddy umbrella header
Created: 2025-03-29
Last Modified: 2025-03-29
This file re-exports all of the key types in the project to ensure
they're accessible across module boundaries. By importing this file,
you'll have access to all the primary types in the project.
/

// Re-export SwiftUI and Foundation
@_exported import SwiftUI
@_exported import Foundation
@_exported import Combine

// Make all of our key models publicly available
@_exported import struct Foundation.Data
@_exported import struct Foundation.URL

// Type aliases for backward compatibility
public typealias DesignSystemType = AppDesignSystem
public typealias MemoryManagerType = AppMemoryManager

// Global declarations of shared types
public let LLMBuddyVersion = "1.0.0"
