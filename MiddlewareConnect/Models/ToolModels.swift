import SwiftUI
import Foundation

// MARK: - Tool Categories and Types

/// Categories for tool filtering
public enum ToolCategory: String, CaseIterable, Identifiable {
    case all = "All Tools"
    case text = "Text Processing"
    case document = "Document Tools"
    case data = "Data Formatting"
    case analysis = "Analysis Tools"
    case utilities = "Utilities"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .text: return "text.badge.plus"
        case .document: return "doc.fill"
        case .data: return "tablecells"
        case .analysis: return "chart.bar.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .all: return .gray
        case .text: return .blue
        case .document: return .red
        case .data: return .purple
        case .analysis: return .orange
        case .utilities: return .green
        }
    }
}

/// Tool development status
public enum ToolStatus: String {
    case ready = "Ready"
    case beta = "Beta"
    case comingSoon = "Coming Soon"
    case experimental = "Experimental"
    case premium = "Premium"
    
    public var color: Color {
        switch self {
        case .ready: return .green
        case .beta: return .blue
        case .comingSoon: return .gray
        case .experimental: return .orange
        case .premium: return Color(red: 0.85, green: 0.65, blue: 0.13) // Gold color
        }
    }
}

/// Model representing a tool in the app
public struct ToolModel: Identifiable, Equatable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let icon: String
    public let category: ToolCategory
    public let status: ToolStatus
    public let destination: String
    public var isFavorite: Bool = false
    public var lastUsed: Date? = nil
    public var usageCount: Int = 0
    public var isPremium: Bool = false
    
    public var color: Color {
        category.color
    }
    
    public init(
        name: String,
        description: String,
        icon: String,
        category: ToolCategory,
        status: ToolStatus,
        destination: String,
        isFavorite: Bool = false,
        lastUsed: Date? = nil,
        usageCount: Int = 0,
        isPremium: Bool = false
    ) {
        self.name = name
        self.description = description
        self.icon = icon
        self.category = category
        self.status = status
        self.destination = destination
        self.isFavorite = isFavorite
        self.lastUsed = lastUsed
        self.usageCount = usageCount
        self.isPremium = isPremium
    }
    
    public static func == (lhs: ToolModel, rhs: ToolModel) -> Bool {
        lhs.id == rhs.id
    }
}

/// Sort options for tool listing
public enum ToolSortOption: String, CaseIterable, Identifiable {
    case nameAsc = "Name (A-Z)"
    case nameDesc = "Name (Z-A)" 
    case recentlyUsed = "Recently Used"
    case mostUsed = "Most Used"
    
    public var id: String { rawValue }
}

// Date formatting helpers
public extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}