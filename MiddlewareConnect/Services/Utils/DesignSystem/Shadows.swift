import SwiftUI

struct _DesignSystemShadows {
    static let small = (color: Color.black.opacity(0.1), radius: 4.0, x: 0.0, y: 2.0)
    static let medium = (color: Color.black.opacity(0.15), radius: 8.0, x: 0.0, y: 4.0)
    static let large = (color: Color.black.opacity(0.2), radius: 16.0, x: 0.0, y: 8.0)
    
    // Card shadow
    static let card = (color: DesignSystem.Colors.cardShadow, radius: 10.0, x: 0.0, y: 5.0)
    
    // Floating button shadow
    static let floatingButton = (color: Color.black.opacity(0.2), radius: 10.0, x: 0.0, y: 5.0)
    
    // Tab Bar shadow
    static let tabBar = (color: Color.black.opacity(0.08), radius: 8.0, x: 0.0, y: -3.0)
}