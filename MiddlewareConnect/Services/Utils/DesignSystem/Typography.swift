import SwiftUI

struct _DesignSystemTypography {
    // Title styles
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.bold)
    static let title2 = Font.title2.weight(.semibold)
    static let title3 = Font.title3.weight(.semibold)
    
    // Body styles
    static let body = Font.body
    static let bodyBold = Font.body.bold()
    static let bodyItalic = Font.body.italic()
    
    // Caption styles
    static let caption = Font.caption
    static let caption2 = Font.caption2
    
    // Headline styles
    static let headline = Font.headline
    static let subheadline = Font.subheadline
    
    // Monospaced font for code or fixed-width text
    static let monospaced = Font.system(.body, design: .monospaced)
    static let monospacedCaption = Font.system(.caption, design: .monospaced)
    
    // Custom styles
    static let tabBar = Font.system(size: 10, weight: .semibold)
    static let homeCardTitle = Font.headline.weight(.bold)
    static let homeCardDescription = Font.callout
}