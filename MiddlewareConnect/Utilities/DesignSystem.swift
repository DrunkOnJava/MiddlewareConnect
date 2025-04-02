/**
 * @fileoverview Design system for consistent UI styling
 * @module DesignSystem
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - DesignSystem with typography, colors, and button styles
 * 
 * Notes:
 * - Central location for app styling
 * - Provides consistent look and feel throughout the app
 */

import SwiftUI

/// Design system for the app
struct DesignSystem {
    // MARK: - Typography
    
    struct Typography {
        static let largeTitle = Font.largeTitle
        static let title = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let headline = Font.headline
        static let subheadline = Font.subheadline
        static let body = Font.body
        static let callout = Font.callout
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }
    
    // MARK: - Colors
    
    struct Colors {
        static let primary = Color("PrimaryColor")
        static let secondary = Color("SecondaryColor")
        static let accent = Color("AccentColor")
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)
        static let text = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        static let tertiaryText = Color(.tertiaryLabel)
    }
    
    // MARK: - Button Styles
    
    /// Primary button style
    struct PrimaryButtonStyle: ButtonStyle {
        var fullWidth: Bool = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .padding()
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(Colors.primary.opacity(configuration.isPressed ? 0.8 : 1))
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    /// Secondary button style
    struct SecondaryButtonStyle: ButtonStyle {
        var fullWidth: Bool = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .padding()
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(Color.gray.opacity(0.1))
                .foregroundColor(Colors.text)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    /// Tertiary button style (flat)
    struct TertiaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .padding()
                .foregroundColor(Colors.primary)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    /// Destructive button style
    struct DestructiveButtonStyle: ButtonStyle {
        var fullWidth: Bool = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .padding()
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(Color.red.opacity(configuration.isPressed ? 0.8 : 1))
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}