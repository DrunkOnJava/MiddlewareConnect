/**
 * @fileoverview Design system for consistent UI styling
 * @module DesignSystem
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - DesignSystem
 */

import SwiftUI
import Foundation

/// Custom shadow structure for design system
public struct Shadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    
    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
    
    /// Apply this shadow to a view
    public func apply<T: View>(to view: T) -> some View {
        view.shadow(color: color, radius: radius, x: x, y: y)
    }
}

/// Design system for consistent styling across the app
public enum DesignSystem {
    /// Color palette
    public enum Colors {
        /// Primary brand color
        public static let primary = Color("Primary", bundle: nil)
        
        /// Secondary brand color
        public static let secondary = Color("Secondary", bundle: nil)
        
        /// Accent color for highlights
        public static let accent = Color("Accent", bundle: nil)
        
        /// Background color
        public static let background = Color("Background", bundle: nil)
        
        /// Secondary background color
        public static let secondaryBackground = Color("SecondaryBackground", bundle: nil)
        
        /// Text color
        public static let text = Color("Text", bundle: nil)
        
        /// Secondary text color
        public static let secondaryText = Color("SecondaryText", bundle: nil)
        
        /// Error color
        public static let error = Color.red
        
        /// Success color
        public static let success = Color.green
        
        /// Warning color
        public static let warning = Color.orange
        
        /// Information color
        public static let info = Color.blue
    }
    
    /// Font styles
    public enum Typography {
        /// Title style
        public static let title = Font.system(.title, design: .default).weight(.semibold)
        
        /// Title 2 style
        public static let title2 = Font.system(.title2, design: .default).weight(.semibold)
        
        /// Title 3 style
        public static let title3 = Font.system(.title3, design: .default).weight(.semibold)
        
        /// Headline style
        public static let headline = Font.system(.headline, design: .default)
        
        /// Body style
        public static let body = Font.system(.body, design: .default)
        
        /// Subheadline style
        public static let subheadline = Font.system(.subheadline, design: .default)
        
        /// Caption style
        public static let caption = Font.system(.caption, design: .default)
        
        /// Small caption style
        public static let captionSmall = Font.system(.caption2, design: .default)
        
        /// Monospaced code style
        public static let code = Font.system(.body, design: .monospaced)
    }
    
    /// Spacing values
    public enum Spacing {
        /// Extra small spacing (4 points)
        public static let xs: CGFloat = 4
        
        /// Small spacing (8 points)
        public static let sm: CGFloat = 8
        
        /// Medium spacing (16 points)
        public static let md: CGFloat = 16
        
        /// Large spacing (24 points)
        public static let lg: CGFloat = 24
        
        /// Extra large spacing (32 points)
        public static let xl: CGFloat = 32
        
        /// Double extra large spacing (48 points)
        public static let xxl: CGFloat = 48
    }
    
    /// Corner radius values
    public enum CornerRadius {
        /// Small corner radius (4 points)
        public static let sm: CGFloat = 4
        
        /// Medium corner radius (8 points)
        public static let md: CGFloat = 8
        
        /// Large corner radius (12 points)
        public static let lg: CGFloat = 12
        
        /// Extra large corner radius (16 points)
        public static let xl: CGFloat = 16
        
        /// Circular corner radius (uses half the height)
        public static func circular(height: CGFloat) -> CGFloat {
            return height / 2
        }
    }
    
    /// Shadow styles
    public enum Shadows {
        /// Small shadow
        public static let sm: Shadow = Shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        
        /// Medium shadow
        public static let md: Shadow = Shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        
        /// Large shadow
        public static let lg: Shadow = Shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    /// Primary button style for branded buttons
    public struct PrimaryButtonStyle: ButtonStyle {
        private let fullWidth: Bool
        
        public init(fullWidth: Bool = false) {
            self.fullWidth = fullWidth
        }
        
        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Typography.headline)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .foregroundColor(.white)
                .background(
                    Colors.primary
                        .opacity(configuration.isPressed ? 0.8 : 1.0)
                )
                .cornerRadius(CornerRadius.md)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    /// Secondary button style for less prominent actions
    public struct SecondaryButtonStyle: ButtonStyle {
        private let fullWidth: Bool
        
        public init(fullWidth: Bool = false) {
            self.fullWidth = fullWidth
        }
        
        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Typography.headline)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .foregroundColor(Colors.primary)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Colors.primary, lineWidth: 1.5)
                        .background(Color.clear)
                )
                .cornerRadius(CornerRadius.md)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}