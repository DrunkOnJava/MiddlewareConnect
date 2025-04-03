/**
@fileoverview Centralized imports for the application
@module Imports
Created: 2025-03-29
Last Modified: 2025-03-29
Dependencies:
- N/A
Exports:
- Imports to be used throughout the app
/

// Import module types
@_exported import SwiftUI
@_exported import Combine
@_exported import Foundation
#if canImport(UIKit)
import UIKit
#endif

// Type aliases for backward compatibility
typealias DesignSystemTheme = AppDesignSystem.Theme
typealias MemoryManager = AppMemoryManager
