import SwiftUI

/**
 * @class AppDesignSystem
 * @description Centralized design system for the application
 *
 * This class defines the app's visual language including:
 * - Color schemes
 * - Typography
 * - Component styles
 * - Layout metrics
 */
class AppDesignSystem {
    // MARK: - Theme
    
    enum Theme: String, CaseIterable {
        case light
        case dark
        case system
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
        
        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "System"
            }
        }
    }
    
    // MARK: - Colors
    
    struct Colors {
        // Primary brand colors
        static let primary = Color("PrimaryColor")
        static let secondary = Color("SecondaryColor")
        static let accent = Color("AccentColor")
        
        // UI element colors
        static let background = Color("BackgroundColor")
        static let secondaryBackground = Color("SecondaryBackgroundColor")
        static let text = Color("TextColor")
        static let secondaryText = Color("SecondaryTextColor")
        
        // Semantic colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
    }
    
    // MARK: - Typography

    struct Typography {
    // Title styles
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.medium)
    static let title3 = Font.title3.weight(.semibold)
    static let subtitle = Font.title2.weight(.medium)
    
    // Body text styles
    static let body = Font.body
    static let bodyBold = Font.body.weight(.semibold)
    static let caption = Font.caption
    static let headline = Font.headline
    static let subheadline = Font.subheadline
        
        // Code styles
        static let code = Font.system(.body, design: .monospaced)
        static let codeSmall = Font.system(.callout, design: .monospaced)
    }
    
    // MARK: - Layout

    struct Layout {
    // Standard spacing
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 24
    
    // Corner radius
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 16
        
        // Component sizes
        static let buttonHeight: CGFloat = 44
        static let iconSize: CGFloat = 24
        static let smallIconSize: CGFloat = 16
        static let largeIconSize: CGFloat = 32
        
        // Screen metrics
        static let screenPadding: CGFloat = 20
        static let contentMaxWidth: CGFloat = 800
    }
    
    // MARK: - Animations
    
    struct Animations {
        static let standard = Animation.easeInOut(duration: 0.3)
        static let quick = Animation.easeOut(duration: 0.2)
        static let slow = Animation.easeInOut(duration: 0.5)
    }
}

// MARK: - View Extensions

extension View {
    // Apply standard padding based on design system
    func standardPadding() -> some View {
        self.padding(AppDesignSystem.Layout.spacing)
    }
    
    // Apply primary style to buttons
    func primaryButtonStyle() -> some View {
        self.foregroundColor(.white)
            .background(AppDesignSystem.Colors.primary)
            .cornerRadius(AppDesignSystem.Layout.cornerRadius)
            .frame(height: AppDesignSystem.Layout.buttonHeight)
    }
    
    // Apply secondary style to buttons
    func secondaryButtonStyle() -> some View {
        self.foregroundColor(AppDesignSystem.Colors.primary)
            .background(AppDesignSystem.Colors.secondaryBackground)
            .cornerRadius(AppDesignSystem.Layout.cornerRadius)
            .frame(height: AppDesignSystem.Layout.buttonHeight)
    }
}

// MARK: - Button Styles

extension DesignSystem {
    // Primary Button Style
    struct PrimaryButtonStyle: ButtonStyle {
        var fullWidth: Bool = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .padding(.vertical, 12)
                .padding(.horizontal, fullWidth ? 0 : 16)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .fill(Colors.primary)
                        .opacity(configuration.isPressed ? 0.8 : 1.0)
                )
                .foregroundColor(.white)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        }
    }
    
    // Secondary Button Style
    struct SecondaryButtonStyle: ButtonStyle {
        var fullWidth: Bool = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .padding(.vertical, 12)
                .padding(.horizontal, fullWidth ? 0 : 16)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .stroke(Colors.primary, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                                .fill(Color(.systemBackground))
                        )
                )
                .foregroundColor(Colors.primary)
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        }
    }
}

// For backward compatibility
typealias DesignSystem = AppDesignSystem

// Radius extension
extension DesignSystem {
    struct Radius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xLarge: CGFloat = 16
        static let xxLarge: CGFloat = 24
        static let circle: CGFloat = 999
    }
    
    // MARK: - Haptic Feedback
    
    static func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    static func selectionHaptic() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    static func notificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}