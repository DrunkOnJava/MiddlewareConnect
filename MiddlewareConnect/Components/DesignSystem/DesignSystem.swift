/**
 * @fileoverview Core design system for MiddlewareConnect
 * @module DesignSystem
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - DesignSystem struct
 * - Colors, Typography, Spacing constants
 * - Various design tokens
 * 
 * Notes:
 * - Single source of truth for design values across the application
 * - Implement design tokens following atomic design principles
 */

import SwiftUI

/// Central design system defining the visual language of the application
public struct DesignSystem {
    
    // MARK: - Colors
    
    /// Color palette for the application
    public struct Colors {
        // Primary colors
        public static let primary = Color("PrimaryColor")
        public static let primaryLight = Color("PrimaryLightColor")
        public static let primaryDark = Color("PrimaryDarkColor")
        
        // Secondary colors
        public static let secondary = Color("SecondaryColor")
        public static let secondaryLight = Color("SecondaryLightColor")
        public static let secondaryDark = Color("SecondaryDarkColor")
        
        // Accent colors
        public static let accent = Color("AccentColor")
        public static let accentLight = Color("AccentLightColor")
        public static let accentDark = Color("AccentDarkColor")
        
        // Provider colors
        public static let anthropic = Color(red: 0.97, green: 0.42, blue: 0.25)
        public static let openai = Color(red: 0.01, green: 0.69, blue: 0.45)
        public static let google = Color(red: 0.26, green: 0.52, blue: 0.96)
        public static let meta = Color(red: 0.23, green: 0.35, blue: 0.60)
        public static let mistral = Color(red: 0.8, green: 0.35, blue: 0.1)
        
        // Semantic colors
        public static let success = Color("SuccessColor")
        public static let warning = Color("WarningColor")
        public static let error = Color("ErrorColor")
        public static let info = Color("InfoColor")
        
        // Grayscale
        public static let gray100 = Color("Gray100")
        public static let gray200 = Color("Gray200")
        public static let gray300 = Color("Gray300")
        public static let gray400 = Color("Gray400")
        public static let gray500 = Color("Gray500")
        public static let gray600 = Color("Gray600")
        public static let gray700 = Color("Gray700")
        public static let gray800 = Color("Gray800")
        public static let gray900 = Color("Gray900")
        
        // Surface colors
        public static let background = Color("BackgroundColor")
        public static let surface = Color("SurfaceColor")
        public static let surfaceHigh = Color("SurfaceHighColor")
        public static let surfaceMedium = Color("SurfaceMediumColor")
        public static let surfaceLow = Color("SurfaceLowColor")
        
        // Text colors
        public static let textPrimary = Color("TextPrimaryColor")
        public static let textSecondary = Color("TextSecondaryColor")
        public static let textTertiary = Color("TextTertiaryColor")
        public static let textOnPrimary = Color("TextOnPrimaryColor")
        public static let textOnSecondary = Color("TextOnSecondaryColor")
        public static let textOnAccent = Color("TextOnAccentColor")
        
        // System colors
        public static let systemBackground = Color(.systemBackground)
        public static let secondarySystemBackground = Color(.secondarySystemBackground)
        public static let tertiarySystemBackground = Color(.tertiarySystemBackground)
        
        /// Get the appropriate color for a provider
        public static func forProvider(_ provider: Provider) -> Color {
            switch provider {
            case .anthropic: return anthropic
            case .openai: return openai
            case .google: return google
            case .meta: return meta
            case .mistral: return mistral
            case .local: return gray600
            }
        }
        
        /// Get a color with appropriate contrast for text on a provider background
        public static func textForProvider(_ provider: Provider) -> Color {
            switch provider {
            case .anthropic, .mistral, .meta: return .white
            case .openai, .google: return .black
            case .local: return .white
            }
        }
    }
    
    // MARK: - Typography
    
    /// Typography scale for the application
    public struct Typography {
        // Font families
        public static let primaryFontFamily = "SF Pro"
        public static let secondaryFontFamily = "SF Pro Rounded"
        public static let monospaceFontFamily = "SF Mono"
        
        // Heading styles
        public static let displayLarge = Font.system(size: 48, weight: .bold)
        public static let displayMedium = Font.system(size: 36, weight: .bold)
        public static let displaySmall = Font.system(size: 32, weight: .bold)
        
        public static let headingLarge = Font.system(size: 28, weight: .bold)
        public static let headingMedium = Font.system(size: 24, weight: .bold)
        public static let headingSmall = Font.system(size: 20, weight: .bold)
        
        // Body styles
        public static let bodyLarge = Font.system(size: 18, weight: .regular)
        public static let bodyMedium = Font.system(size: 16, weight: .regular)
        public static let bodySmall = Font.system(size: 14, weight: .regular)
        
        // Label styles
        public static let labelLarge = Font.system(size: 14, weight: .medium)
        public static let labelMedium = Font.system(size: 12, weight: .medium)
        public static let labelSmall = Font.system(size: 10, weight: .medium)
        
        // Code styles
        public static let codeLarge = Font.system(size: 18, weight: .regular, design: .monospaced)
        public static let codeMedium = Font.system(size: 16, weight: .regular, design: .monospaced)
        public static let codeSmall = Font.system(size: 14, weight: .regular, design: .monospaced)
        
        // Weight variants
        public static func withWeight(_ font: Font, _ weight: Font.Weight) -> Font {
            // This is a simplified implementation - in a real app, we would
            // need more complex logic to apply weight while preserving size
            return font.weight(weight)
        }
    }
    
    // MARK: - Spacing
    
    /// Spacing scale for the application
    public struct Spacing {
        public static let xxxs: CGFloat = 2
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let s: CGFloat = 12
        public static let m: CGFloat = 16
        public static let l: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
        public static let xxxl: CGFloat = 64
        
        // Common spacing patterns
        public static let sectionSpacing: CGFloat = 32
        public static let groupSpacing: CGFloat = 24
        public static let itemSpacing: CGFloat = 16
        public static let contentSpacing: CGFloat = 12
        public static let elementSpacing: CGFloat = 8
    }
    
    // MARK: - Sizing
    
    /// Sizing constants for the application
    public struct Sizing {
        // Icon sizes
        public static let iconXSmall: CGFloat = 12
        public static let iconSmall: CGFloat = 16
        public static let iconMedium: CGFloat = 24
        public static let iconLarge: CGFloat = 32
        public static let iconXLarge: CGFloat = 48
        
        // Button heights
        public static let buttonSmall: CGFloat = 32
        public static let buttonMedium: CGFloat = 44
        public static let buttonLarge: CGFloat = 56
        
        // Control heights
        public static let controlSmall: CGFloat = 32
        public static let controlMedium: CGFloat = 40
        public static let controlLarge: CGFloat = 48
        
        // Container sizes
        public static let containerSmall: CGFloat = 400
        public static let containerMedium: CGFloat = 600
        public static let containerLarge: CGFloat = 800
        public static let containerXLarge: CGFloat = 1000
        
        // Corner radii
        public static let cornerSmall: CGFloat = 4
        public static let cornerMedium: CGFloat = 8
        public static let cornerLarge: CGFloat = 12
        public static let cornerXLarge: CGFloat = 16
    }
    
    // MARK: - Shadows
    
    /// Shadow definitions for the application
    public struct Shadows {
        public static let subtle = Shadow(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        
        public static let medium = Shadow(
            color: Color.black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
        
        public static let pronounced = Shadow(
            color: Color.black.opacity(0.2),
            radius: 16,
            x: 0,
            y: 8
        )
        
        public static let floating = Shadow(
            color: Color.black.opacity(0.25),
            radius: 24,
            x: 0,
            y: 16
        )
    }
    
    // MARK: - Animation
    
    /// Animation presets for the application
    public struct Animation {
        public static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        public static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        public static let pronounced = SwiftUI.Animation.easeInOut(duration: 0.35)
        public static let gradual = SwiftUI.Animation.easeInOut(duration: 0.5)
        
        public static let springQuick = SwiftUI.Animation.spring(
            response: 0.3,
            dampingFraction: 0.7,
            blendDuration: 0.1
        )
        
        public static let springStandard = SwiftUI.Animation.spring(
            response: 0.5,
            dampingFraction: 0.65,
            blendDuration: 0.1
        )
        
        public static let springGentle = SwiftUI.Animation.spring(
            response: 0.7,
            dampingFraction: 0.6,
            blendDuration: 0.1
        )
    }
    
    // MARK: - Helper Structs
    
    /// Defines a shadow style
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
        
        /// Apply the shadow to a view
        public func apply<T: View>(to view: T) -> some View {
            view.shadow(color: color, radius: radius, x: x, y: y)
        }
    }
}

// MARK: - SwiftUI View Extensions

/// Extension to SwiftUI View for applying design system styles
public extension View {
    /// Apply a text style from the design system
    func textStyle(_ font: Font) -> some View {
        self.font(font)
    }
    
    /// Apply primary button style from design system
    func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    /// Apply secondary button style from design system
    func secondaryButtonStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
    
    /// Apply tertiary button style from design system
    func tertiaryButtonStyle() -> some View {
        self.buttonStyle(TertiaryButtonStyle())
    }
    
    /// Apply a card style from the design system
    func cardStyle(
        backgroundColor: Color = DesignSystem.Colors.surface,
        cornerRadius: CGFloat = DesignSystem.Sizing.cornerMedium,
        shadow: DesignSystem.Shadow = DesignSystem.Shadows.medium
    ) -> some View {
        self
            .padding(DesignSystem.Spacing.m)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

// MARK: - Button Styles

/// Primary button style using design system tokens
public struct PrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, DesignSystem.Spacing.m)
            .padding(.vertical, DesignSystem.Spacing.s)
            .frame(minHeight: DesignSystem.Sizing.buttonMedium)
            .background(
                DesignSystem.Colors.primary
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .foregroundColor(DesignSystem.Colors.textOnPrimary)
            .font(DesignSystem.Typography.bodyMedium.weight(.semibold))
            .cornerRadius(DesignSystem.Sizing.cornerMedium)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

/// Secondary button style using design system tokens
public struct SecondaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, DesignSystem.Spacing.m)
            .padding(.vertical, DesignSystem.Spacing.s)
            .frame(minHeight: DesignSystem.Sizing.buttonMedium)
            .background(
                DesignSystem.Colors.secondary
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .foregroundColor(DesignSystem.Colors.textOnSecondary)
            .font(DesignSystem.Typography.bodyMedium.weight(.semibold))
            .cornerRadius(DesignSystem.Sizing.cornerMedium)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

/// Tertiary button style using design system tokens
public struct TertiaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, DesignSystem.Spacing.m)
            .padding(.vertical, DesignSystem.Spacing.s)
            .frame(minHeight: DesignSystem.Sizing.buttonMedium)
            .background(Color.clear)
            .foregroundColor(DesignSystem.Colors.primary)
            .font(DesignSystem.Typography.bodyMedium.weight(.semibold))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}
