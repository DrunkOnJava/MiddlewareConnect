/**
@fileoverview Central module imports for the application
@module ModuleImports
Created: 2025-03-29
Last Modified: 2025-03-29
This file serves as a central location for importing types that need to be globally accessible
throughout the application. Including this file in a Swift file makes all these types available.
Note: Swift doesn't have a true module system like some other languages, but this pattern
helps organize and centralize imports.
/

import Foundation
import SwiftUI
import Combine

// Re-export models
@_exported import struct Foundation.URL
@_exported import struct Foundation.Date
@_exported import struct Foundation.UUID

// Re-export SwiftUI components
@_exported import struct SwiftUI.Color
@_exported import struct SwiftUI.Font
@_exported import struct SwiftUI.Binding
@_exported import protocol SwiftUI.View
@_exported import struct SwiftUI.AnyView
@_exported import class SwiftUI.UIHostingController

// Re-export Combine components
@_exported import class Combine.ObservableObjectPublisher
@_exported import protocol Combine.ObservableObject
@_exported import class Combine.AnyCancellable
@_exported import struct Combine.Published

// Make app models accessible globally
typealias DS = DesignSystem
