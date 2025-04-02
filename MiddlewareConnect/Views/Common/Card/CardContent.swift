import SwiftUI

extension CardView {
    /// Main content builder for CardView
    @ViewBuilder
    func buildCardContent(viewState: ViewState) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            // Title and icon
            if let title = title {
                HStack(spacing: DesignSystem.Spacing.small) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(DesignSystem.Colors.primary)
                            .font(.system(size: 18, weight: .semibold))
                            .animation(DesignSystem.Animation.quick, value: viewState.isPressed)
                    }
                    
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text)
                }
            }
            
            // Content
            content
            
            // Add an indicator for interactive cards
            if style == .interactive && action != nil {
                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .opacity(viewState.isHovered ? 1.0 : 0.7)
                        .offset(x: viewState.isHovered ? 3 : 0)
                        .animation(DesignSystem.Animation.spring, value: viewState.isHovered)
                }
                .padding(.top, DesignSystem.Spacing.xSmall)
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(viewState.backgroundColor)
        .cornerRadius(DesignSystem.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .stroke(viewState.borderColor, lineWidth: style == .bordered || style == .interactive ? 1 : 0)
        )
        .shadow(
            color: viewState.shadowColor,
            radius: viewState.shadowRadius,
            x: 0,
            y: viewState.shadowY
        )
        .scaleEffect(viewState.isPressed ? 0.98 : 1.0)
        .opacity(viewState.isPressed ? 0.95 : 1.0)
    }
}