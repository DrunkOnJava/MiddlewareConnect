import SwiftUI

extension DesignSystem {
    /// View modifier for card style
    struct CardStyle: ViewModifier {
        var padding: CGFloat = DesignSystem.Spacing.medium
        var cornerRadius: CGFloat = DesignSystem.Radius.large
        
        func body(content: Content) -> some View {
            content
                .padding(padding)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(cornerRadius)
                .shadow(
                    color: DesignSystem.Shadows.card.color,
                    radius: DesignSystem.Shadows.card.radius,
                    x: DesignSystem.Shadows.card.x,
                    y: DesignSystem.Shadows.card.y
                )
        }
    }

    /// Feature card style
    struct FeatureCardStyle: ViewModifier {
        var iconName: String
        var iconColor: Color
        
        func body(content: Content) -> some View {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(iconColor)
                    .cornerRadius(DesignSystem.Radius.medium)
                    
                content
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.cardBackground)
            .cornerRadius(DesignSystem.Radius.large)
            .shadow(
                color: DesignSystem.Shadows.card.color,
                radius: DesignSystem.Shadows.card.radius,
                x: DesignSystem.Shadows.card.x,
                y: DesignSystem.Shadows.card.y
            )
        }
    }
}

extension View {
    /// Apply card style to a view
    func cardStyle(padding: CGFloat = DesignSystem.Spacing.medium) -> some View {
        modifier(DesignSystem.CardStyle(padding: padding))
    }
    
    /// Apply feature card style
    func featureCard(icon: String, color: Color) -> some View {
        modifier(DesignSystem.FeatureCardStyle(iconName: icon, iconColor: color))
    }
}