import SwiftUI

/// Main tab enum to manage navigation
enum AppTab: String, CaseIterable {
    case home = "home"
    case tools = "tools"
    case chat = "chat" 
    case analysis = "analysis"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .tools: return "Tools"
        case .chat: return "Chat"
        case .analysis: return "Analysis"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .tools: return "hammer"
        case .chat: return "bubble.left.and.bubble.right"
        case .analysis: return "chart.bar"
        case .settings: return "gearshape"
        }
    }
}