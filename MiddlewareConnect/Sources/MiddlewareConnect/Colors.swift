import SwiftUI

struct _DesignSystemColors {
    // Primary colors
    static let primary = Color("AppPrimaryColor") // Custom primary color from assets
    static let secondary = Color("AppSecondaryColor") // Custom secondary color from assets 
    static let accent = Color.accentColor
    
    // Background colors
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    
    // Text colors
    static let text = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    
    // Semantic colors
    static let success = Color.green
    static let warning = Color.yellow
    static let error = Color.red
    static let info = Color.blue
    
    // Custom colors
    static let divider = Color(.separator)
    
    // Tab bar colors
    static let tabBarBackground = Color(.systemBackground)
    static let tabBarSelected = primary
    static let tabBarUnselected = Color(.secondaryLabel)
    
    // Card colors
    static let cardBackground = Color(.secondarySystemBackground)
    static let cardShadow = Color.black.opacity(0.12)
    static let cardHighlight = primary.opacity(0.05)
}