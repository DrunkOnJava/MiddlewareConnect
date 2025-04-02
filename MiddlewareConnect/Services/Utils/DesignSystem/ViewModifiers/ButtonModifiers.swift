import SwiftUI

extension DesignSystem {
    /// View modifier for primary button style
    struct PrimaryButtonStyle: ButtonStyle {
        var fullWidth: Bool = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(DesignSystem.Typography.headline)
                .fontWeight(.semibold)
                .padding(.vertical, DesignSystem.Spacing.small)
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(DesignSystem.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(DesignSystem.Radius.medium)
                .shadow(
                    color: DesignSystem.Colors.primary.opacity(0.4),
                    radius: 8,
                    x: 0,
                    y: 4
                )
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .opacity(configuration.isPressed ? 0.9 : 1)
                .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
        }
    }

    /// View modifier for secondary button style
    struct SecondaryButtonStyle: ButtonStyle {
        var fullWidth: Bool = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(DesignSystem.Typography.headline)
                .fontWeight(.medium)
                .padding(.vertical, DesignSystem.Spacing.small)
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .background(DesignSystem.Colors.secondaryBackground)
                .foregroundColor(DesignSystem.Colors.primary)
                .cornerRadius(DesignSystem.Radius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                        .stroke(DesignSystem.Colors.primary.opacity(0.5), lineWidth: 1)
                )
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .opacity(configuration.isPressed ? 0.9 : 1)
                .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
        }
    }

    /// View modifier for text button style (looks like a link)
    struct TextButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.primary)
                .opacity(configuration.isPressed ? 0.7 : 1)
                .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
        }
    }

    /// View modifier for floating action button style
    struct FloatingActionButtonStyle: ButtonStyle {
        var iconName: String
        var backgroundColor: Color = DesignSystem.Colors.primary
        
        func makeBody(configuration: Configuration) -> some View {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(backgroundColor)
                .cornerRadius(DesignSystem.Radius.circle)
                .shadow(
                    color: DesignSystem.Shadows.floatingButton.color,
                    radius: DesignSystem.Shadows.floatingButton.radius,
                    x: DesignSystem.Shadows.floatingButton.x,
                    y: DesignSystem.Shadows.floatingButton.y
                )
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .opacity(configuration.isPressed ? 0.9 : 1)
                .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
        }
    }
}