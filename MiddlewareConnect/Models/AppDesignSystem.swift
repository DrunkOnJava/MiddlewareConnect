/**
 * @fileoverview App design system definitions
 * @module Models
 * 
 * Created: 2025-03-29
 * Last Modified: 2025-03-29
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - AppDesignSystem struct
 * - AppDesignSystem.Theme enum
 * 
 * Notes:
 * - Defines the application's design tokens and theme system
 */

import SwiftUI
import UIKit

/// Design system for the application
public struct AppDesignSystem {
    
    /// Available app themes
    public enum Theme: String, CaseIterable, Identifiable {
        case light
        case dark
        case system
        
        public var id: String { self.rawValue }
        
        /// Corresponding color scheme for SwiftUI
        public var colorScheme: ColorScheme? {
            switch self {
            case .light:
                return .light
            case .dark:
                return .dark
            case .system:
                return nil
            }
        }
    }
    
    /// Color palette for the application
    public struct Colors {
        // Primary colors
        public static let primary = Color("PrimaryColor", default: .blue)
        public static let secondary = Color("SecondaryColor", default: .orange)
        public static let accent = Color.blue
        
        // Background colors
        public static let background = Color("BackgroundColor", default: Color(.systemBackground))
        public static let secondaryBackground = Color("SecondaryBackgroundColor", default: Color(.secondarySystemBackground))
        
        // Text colors
        public static let text = Color("TextColor", default: Color(.label))
        public static let secondaryText = Color("SecondaryTextColor", default: Color(.secondaryLabel))
        
        // Status colors
        public static let success = Color.green
        public static let warning = Color.yellow
        public static let error = Color.red
        public static let info = Color.blue
    }
    
    /// Font styles for the application
    public struct Typography {
        public static let title = Font.title
        public static let title2 = Font.title2
        public static let title3 = Font.title3
        public static let headline = Font.headline
        public static let subheadline = Font.subheadline
        public static let body = Font.body
        public static let callout = Font.callout
        public static let footnote = Font.footnote
        public static let caption = Font.caption
        public static let caption2 = Font.caption2
        
        public static let largeTitle = Font.largeTitle.weight(.bold)
        public static let boldHeadline = Font.headline.weight(.bold)
        
        // Custom font sizes
        public static let customTitle = Font.system(size: 28, weight: .bold)
        public static let customHeading = Font.system(size: 22, weight: .semibold)
        public static let customBody = Font.system(size: 16, weight: .regular)
        public static let customCaption = Font.system(size: 12, weight: .regular)
    }
    
    /// Layout metrics for the application
    public struct Layout {
        // Spacing
        public static let xxSmall: CGFloat = 4
        public static let xSmall: CGFloat = 8
        public static let small: CGFloat = 12
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 24
        public static let xLarge: CGFloat = 32
        public static let xxLarge: CGFloat = 48
        
        // Padding
        public static let standardPadding: CGFloat = 16
        public static let tightPadding: CGFloat = 8
        public static let loosePadding: CGFloat = 24
        
        // Radius
        public static let smallRadius: CGFloat = 4
        public static let mediumRadius: CGFloat = 8
        public static let largeRadius: CGFloat = 16
        
        // Standard view sizes
        public static let iconSize: CGFloat = 24
        public static let buttonHeight: CGFloat = 44
        public static let inputHeight: CGFloat = 44
    }
    
    /// Radius values for the application
    public struct Radius {
        public static let small: CGFloat = 4
        public static let medium: CGFloat = 8
        public static let large: CGFloat = 16
        public static let extraLarge: CGFloat = 24
        public static let circle: CGFloat = 999
    }
    
    /// Shared shadows for the application
    public struct Shadows {
        public static let small = Shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        public static let medium = Shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        public static let large = Shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        public static let extraLarge = Shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
        
        /// Helper struct for shadow specifications
        public struct Shadow {
            public let color: Color
            public let radius: CGFloat
            public let x: CGFloat
            public let y: CGFloat
            
            /// Initialize a new shadow
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
    }
    
    /// Animation presets for the application
    public struct Animations {
        public static let standard = Animation.easeInOut(duration: 0.3)
        public static let fast = Animation.easeInOut(duration: 0.2)
        public static let slow = Animation.easeInOut(duration: 0.5)
        
        public static let springy = Animation.spring(response: 0.3, dampingFraction: 0.6)
        public static let bounce = Animation.spring(response: 0.4, dampingFraction: 0.4)
    }
    
    // MARK: - Haptic Feedback
    
    /// Haptic feedback intensity constants
    public static let light = HapticFeedbackIntensity.light
    public static let medium = HapticFeedbackIntensity.medium
    public static let heavy = HapticFeedbackIntensity.heavy
    
    /// Notification feedback type constants
    public static let success = NotificationHapticType.success
    public static let warning = NotificationHapticType.warning
    public static let error = NotificationHapticType.error
    
    /// Haptic feedback intensity enum
    public enum HapticFeedbackIntensity {
        case light
        case medium
        case heavy
        
        var uiKitFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light: return .light
            case .medium: return .medium
            case .heavy: return .heavy
            }
        }
    }
    
    /// Notification haptic types
    public enum NotificationHapticType {
        case success
        case warning
        case error
        
        var uiKitFeedbackType: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .success: return .success
            case .warning: return .warning
            case .error: return .error
            }
        }
    }
    
    /// Generate haptic feedback
    public static func hapticFeedback(_ intensity: HapticFeedbackIntensity) {
        let generator = UIImpactFeedbackGenerator(style: intensity.uiKitFeedbackStyle)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Generate notification haptic
    public static func notificationHaptic(_ type: NotificationHapticType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type.uiKitFeedbackType)
    }
    
    /// Generate selection feedback
    public static func selectionHaptic() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    // MARK: - Button Styles
    
    /// Primary button style
    public struct PrimaryButtonStyle: ButtonStyle {
        let fullWidth: Bool
        
        public init(fullWidth: Bool = false) {
            self.fullWidth = fullWidth
        }
        
        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(
                    configuration.isPressed ? 
                        Colors.primary.opacity(0.8) : 
                        Colors.primary
                )
                .cornerRadius(10)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    /// Secondary button style
    public struct SecondaryButtonStyle: ButtonStyle {
        let fullWidth: Bool
        
        public init(fullWidth: Bool = false) {
            self.fullWidth = fullWidth
        }
        
        public func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .foregroundColor(Colors.primary)
                .padding()
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(
                    configuration.isPressed ? 
                        Colors.primary.opacity(0.1) : 
                        Colors.primary.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Colors.primary.opacity(0.5), lineWidth: 1)
                )
                .cornerRadius(10)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}

// Color extension to add default values
extension Color {
    /// Initialize a color with a default fallback
    init(_ name: String, default defaultColor: Color) {
        self = Color(name)
    }
}

/// Alias to maintain compatibility with existing code
public typealias DesignSystem = AppDesignSystem
