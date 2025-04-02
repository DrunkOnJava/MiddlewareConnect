import SwiftUI

// Re-export the key types needed by ContentView
@_exported import struct LLMBuddy_iOS.AppTab
@_exported import struct LLMBuddy_iOS.Tab

/// View helpers for the app
struct ViewHelpers {
    /// Convert a Tab to an AppTab for navigation
    /// - Parameter tab: The Tab to convert
    /// - Returns: The corresponding AppTab
    static func appTabForTab(_ tab: Tab) -> AppTab {
        switch tab {
        case .text, .textClean, .markdown, .pdfCombine, .pdfSplit, .csv, .image:
            return .tools
        case .tokenCost, .contextWindow:
            return .analysis
        case .summarize:
            return .tools // Document summarizer is under tools
        case .home:
            return .home
        }
    }
    
    /// Get the appropriate icon for a view
    /// - Parameter view: The view name
    /// - Returns: The SF Symbol name
    static func getIconForView(_ view: String) -> String {
        switch view.lowercased() {
        case "home":
            return "house"
        case "tools":
            return "hammer"
        case "chat":
            return "bubble.left.and.bubble.right"
        case "analysis":
            return "chart.bar"
        case "settings":
            return "gearshape"
        case "text":
            return "doc.text"
        case "pdf":
            return "doc.fill"
        case "csv":
            return "tablecells"
        case "image":
            return "photo"
        default:
            return "questionmark.circle"
        }
    }
}