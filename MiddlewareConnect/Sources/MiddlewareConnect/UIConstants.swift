/**
@fileoverview UI constants for standardized styling across the app
@module UIConstants
Created: 2025-04-01
Last Modified: 2025-04-01
Dependencies:
- SwiftUI
Exports:
- UIConstants struct with standardized UI values
- Supporting types and extensions
Notes:
- Use these constants for consistent styling throughout the app
/

import SwiftUI

/// Contains standardized UI constants to maintain consistent styling across the app
struct UIConstants {
    // MARK: - Corner Radius
    struct CornerRadius {
        /// Used for small UI elements like buttons, text fields
        static let small: CGFloat = 8
        /// Used for medium-sized elements like cards, panels
        static let medium: CGFloat = 12
        /// Used for large elements like modal sheets
        static let large: CGFloat = 16
    }
    
    // MARK: - Padding
    struct Padding {
        /// Standard horizontal padding for containers
        static let horizontal: CGFloat = 16
        /// Standard vertical padding for containers
        static let vertical: CGFloat = 12
        /// Spacing between related elements
        static let interItem: CGFloat = 8
        /// Spacing between groups of elements
        static let interGroup: CGFloat = 16
        /// Inset padding for lists and sections
        static let listInset: EdgeInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    }
    
    // MARK: - Font Sizes
    struct FontSize {
        static let caption: CGFloat = 12
        static let footnote: CGFloat = 13
        static let subheadline: CGFloat = 15
        static let body: CGFloat = 17
        static let headline: CGFloat = 17
        static let title3: CGFloat = 20
        static let title2: CGFloat = 22
        static let title1: CGFloat = 28
        static let largeTitle: CGFloat = 34
    }
    
    // MARK: - Font Weights
    struct FontWeight {
        static let regular = Font.Weight.regular
        static let medium = Font.Weight.medium
        static let semibold = Font.Weight.semibold
        static let bold = Font.Weight.bold
    }
    
    // MARK: - Colors
    struct Colors {
        // Base colors
        static let primary = Color("PrimaryColor")
        static let secondary = Color("SecondaryColor")
        static let accent = Color("AccentColor")
        static let background = Color("BackgroundColor")
        
        // Functional colors
        static let success = Color.green
        static let warning = Color.yellow
        static let error = Color.red
        static let info = Color.blue
        
        // Category colors
        static let analysis = Color.purple
        static let utilities = Color.orange
        static let generation = Color.green
        static let conversion = Color.blue
        
        // Text colors
        static let primaryText = Color("PrimaryTextColor")
        static let secondaryText = Color("SecondaryTextColor")
        static let tertiaryText = Color("TertiaryTextColor")
    }
    
    // MARK: - Shadows
    struct Shadow {
        /// Light shadow for subtle elevation
        static let light: Shadow = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
        
        /// Medium shadow for moderate elevation
        static let medium: Shadow = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
        
        /// Strong shadow for significant elevation
        static let strong: Shadow = Shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 4)
        
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // MARK: - Animation
    struct Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
    }
    
    // MARK: - Button Styles
    struct ButtonStyle {
        static func primary() -> some SwiftUI.ButtonStyle {
            CustomButtonStyle(
                backgroundColor: Colors.primary,
                foregroundColor: .white,
                cornerRadius: CornerRadius.small,
                font: .system(size: FontSize.body, weight: FontWeight.semibold)
            )
        }
        
        static func secondary() -> some SwiftUI.ButtonStyle {
            CustomButtonStyle(
                backgroundColor: Colors.secondary,
                foregroundColor: Colors.primaryText,
                cornerRadius: CornerRadius.small,
                font: .system(size: FontSize.body, weight: FontWeight.medium)
            )
        }
        
        static func tertiary() -> some SwiftUI.ButtonStyle {
            CustomButtonStyle(
                backgroundColor: .clear,
                foregroundColor: Colors.primary,
                cornerRadius: CornerRadius.small,
                font: .system(size: FontSize.body, weight: FontWeight.medium)
            )
        }
    }
}

// MARK: - Supporting Types

/// Custom button style that uses the standardized UI constants
struct CustomButtonStyle: SwiftUI.ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let cornerRadius: CGFloat
    let font: Font
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .padding(.horizontal, UIConstants.Padding.horizontal)
            .padding(.vertical, UIConstants.Padding.interItem)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.8 : 1))
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(UIConstants.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Extensions

extension View {
    /// Apply a standardized shadow to the view
    func standardShadow(_ shadow: UIConstants.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// Apply primary button style
    func primaryButtonStyle() -> some View {
        self.buttonStyle(UIConstants.ButtonStyle.primary())
    }
    
    /// Apply secondary button style
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(UIConstants.ButtonStyle.secondary())
    }
    
    /// Apply tertiary button style
    func tertiaryButtonStyle() -> some View {
        self.buttonStyle(UIConstants.ButtonStyle.tertiary())
    }
    
    /// Apply standardized padding to the view
    func standardPadding() -> some View {
        self.padding(.horizontal, UIConstants.Padding.horizontal)
            .padding(.vertical, UIConstants.Padding.vertical)
    }
}
