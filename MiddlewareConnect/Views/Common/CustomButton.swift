import SwiftUI

/// A custom button component that follows the app's design system
struct CustomButton: View {
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case text       // Text-only button, like a link
        case icon       // Icon-only button
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 56
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return DesignSystem.Spacing.small
            case .medium: return DesignSystem.Spacing.medium
            case .large: return DesignSystem.Spacing.large
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 20
            }
        }
        
        var font: Font {
            switch self {
            case .small: return DesignSystem.Typography.subheadline
            case .medium: return DesignSystem.Typography.headline
            case .large: return DesignSystem.Typography.title3
            }
        }
    }
    
    let title: String
    let icon: String?
    let style: ButtonStyle
    let size: ButtonSize
    let fullWidth: Bool
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    
    @State private var isPressed: Bool = false
    @State private var isHovered: Bool = false
    
    init(
        title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        fullWidth: Bool = false,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.fullWidth = fullWidth
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                withAnimation(DesignSystem.Animation.quick) {
                    isPressed = true
                    provideFeedback()
                }
                
                // Reset after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(DesignSystem.Animation.quick) {
                        isPressed = false
                    }
                    action()
                }
            }
        }) {
            buttonContent
        }
        .buttonStyle(PlainButtonStyle()) // Use PlainButtonStyle to handle custom press states
        .disabled(isDisabled || isLoading)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.quick) {
                isHovered = hovering
            }
        }
    }
    
    private var buttonContent: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            if isLoading {
                loadingIndicator
            } else if let icon = icon {
                iconView(icon)
            }
            
            if style != .icon || isLoading {
                Text(title)
                    .font(size.font)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
        }
        .frame(
            minWidth: style == .icon ? size.height : nil,
            minHeight: size.height,
            maxWidth: fullWidth ? .infinity : nil
        )
        .padding(.horizontal, style == .icon ? 0 : size.horizontalPadding)
        .background(backgroundView)
        .foregroundColor(foregroundColor)
        .cornerRadius(style == .icon ? size.height / 2 : DesignSystem.Radius.medium)
        .overlay(borderView)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(isDisabled ? 0.6 : (isPressed ? 0.9 : 1.0))
        .shadow(
            color: shadowColor,
            radius: isPressed ? 2 : (isHovered ? 6 : 4),
            x: 0,
            y: isPressed ? 1 : (isHovered ? 3 : 2)
        )
        .animation(DesignSystem.Animation.spring, value: isPressed)
        .animation(DesignSystem.Animation.quick, value: isHovered)
        .animation(DesignSystem.Animation.quick, value: isDisabled)
    }
    
    // MARK: - Component Views
    
    private var loadingIndicator: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
            .scaleEffect(size == .small ? 0.7 : (size == .medium ? 0.8 : 1.0))
    }
    
    private func iconView(_ iconName: String) -> some View {
        Image(systemName: iconName)
            .font(.system(size: size.iconSize, weight: .medium))
            .frame(width: size.iconSize, height: size.iconSize)
    }
    
    private var backgroundView: some View {
        backgroundColor
            .opacity(style == .text ? 0 : 1)
    }
    
    private var borderView: some View {
        RoundedRectangle(cornerRadius: style == .icon ? size.height / 2 : DesignSystem.Radius.medium)
            .stroke(borderColor, lineWidth: hasBorder ? 1 : 0)
    }
    
    // MARK: - Helper Properties
    
    private var hasBorder: Bool {
        style == .secondary || (style == .text && isHovered)
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return disabledBackgroundColor
        }
        
        if isPressed {
            return pressedBackgroundColor
        }
        
        if isHovered && (style == .primary || style == .destructive) {
            return hoverBackgroundColor
        }
        
        switch style {
        case .primary:
            return DesignSystem.Colors.primary
        case .secondary:
            return isHovered ? DesignSystem.Colors.primary.opacity(0.05) : Color.clear
        case .destructive:
            return DesignSystem.Colors.error
        case .text, .icon:
            return isHovered ? DesignSystem.Colors.primary.opacity(0.05) : Color.clear
        }
    }
    
    private var hoverBackgroundColor: Color {
        switch style {
        case .primary:
            return DesignSystem.Colors.primary.opacity(0.9)
        case .secondary:
            return DesignSystem.Colors.primary.opacity(0.1)
        case .destructive:
            return DesignSystem.Colors.error.opacity(0.9)
        case .text, .icon:
            return DesignSystem.Colors.primary.opacity(0.1)
        }
    }
    
    private var pressedBackgroundColor: Color {
        switch style {
        case .primary:
            return DesignSystem.Colors.primary.opacity(0.8)
        case .secondary:
            return DesignSystem.Colors.primary.opacity(0.15)
        case .destructive:
            return DesignSystem.Colors.error.opacity(0.8)
        case .text, .icon:
            return DesignSystem.Colors.primary.opacity(0.15)
        }
    }
    
    private var foregroundColor: Color {
        if isDisabled {
            return disabledForegroundColor
        }
        
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary, .text, .icon:
            return DesignSystem.Colors.primary
        }
    }
    
    private var borderColor: Color {
        if isDisabled {
            return disabledBorderColor
        }
        
        if isPressed {
            return pressedBorderColor
        }
        
        switch style {
        case .primary, .destructive:
            return Color.clear
        case .secondary:
            return isHovered ? DesignSystem.Colors.primary : DesignSystem.Colors.primary.opacity(0.5)
        case .text, .icon:
            return isHovered ? DesignSystem.Colors.primary.opacity(0.3) : Color.clear
        }
    }
    
    private var pressedBorderColor: Color {
        switch style {
        case .primary, .destructive:
            return Color.clear
        case .secondary, .text, .icon:
            return DesignSystem.Colors.primary
        }
    }
    
    private var disabledBackgroundColor: Color {
        switch style {
        case .primary:
            return DesignSystem.Colors.primary.opacity(0.3)
        case .secondary, .text, .icon:
            return Color.clear
        case .destructive:
            return DesignSystem.Colors.error.opacity(0.3)
        }
    }
    
    private var disabledForegroundColor: Color {
        switch style {
        case .primary, .destructive:
            return .white.opacity(0.7)
        case .secondary, .text, .icon:
            return DesignSystem.Colors.primary.opacity(0.5)
        }
    }
    
    private var disabledBorderColor: Color {
        switch style {
        case .primary, .destructive, .text, .icon:
            return Color.clear
        case .secondary:
            return DesignSystem.Colors.primary.opacity(0.3)
        }
    }
    
    private var shadowColor: Color {
        guard !isDisabled else { return Color.clear }
        
        switch style {
        case .primary:
            return DesignSystem.Colors.primary.opacity(0.4)
        case .destructive:
            return DesignSystem.Colors.error.opacity(0.4)
        case .secondary, .text, .icon:
            return isHovered ? Color.black.opacity(0.05) : Color.clear
        }
    }
    
    // MARK: - Helper Methods
    
    private func provideFeedback() {
        switch style {
        case .primary, .destructive:
            DesignSystem.hapticFeedback(.medium)
        case .secondary, .text, .icon:
            DesignSystem.hapticFeedback(.light)
        }
    }
}

// MARK: - Preview

struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Button Styles Preview
            VStack(spacing: 20) {
                Text("Button Styles")
                    .font(DesignSystem.Typography.title2)
                
                CustomButton(
                    title: "Primary Button",
                    icon: "arrow.right",
                    style: .primary,
                    action: {}
                )
                
                CustomButton(
                    title: "Secondary Button",
                    icon: "doc",
                    style: .secondary,
                    action: {}
                )
                
                CustomButton(
                    title: "Destructive Button",
                    icon: "trash",
                    style: .destructive,
                    action: {}
                )
                
                CustomButton(
                    title: "Text Button",
                    icon: "link",
                    style: .text,
                    action: {}
                )
                
                HStack(spacing: 20) {
                    CustomButton(
                        title: "Icon",
                        icon: "star.fill",
                        style: .icon,
                        action: {}
                    )
                    
                    CustomButton(
                        title: "Icon",
                        icon: "bell.fill",
                        style: .icon,
                        action: {}
                    )
                    
                    CustomButton(
                        title: "Icon",
                        icon: "heart.fill",
                        style: .icon,
                        action: {}
                    )
                }
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Button Styles")
            
            // Button Sizes Preview
            VStack(spacing: 20) {
                Text("Button Sizes")
                    .font(DesignSystem.Typography.title2)
                
                CustomButton(
                    title: "Small Button",
                    icon: "arrow.right",
                    style: .primary,
                    size: .small,
                    action: {}
                )
                
                CustomButton(
                    title: "Medium Button (Default)",
                    icon: "arrow.right",
                    style: .primary,
                    size: .medium,
                    action: {}
                )
                
                CustomButton(
                    title: "Large Button",
                    icon: "arrow.right",
                    style: .primary,
                    size: .large,
                    action: {}
                )
                
                CustomButton(
                    title: "Full Width Button",
                    icon: "arrow.right",
                    style: .primary,
                    fullWidth: true,
                    action: {}
                )
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Button Sizes")
            
            // Button States Preview
            VStack(spacing: 20) {
                Text("Button States")
                    .font(DesignSystem.Typography.title2)
                
                CustomButton(
                    title: "Normal Button",
                    icon: "arrow.right",
                    style: .primary,
                    action: {}
                )
                
                CustomButton(
                    title: "Loading Button",
                    style: .primary,
                    isLoading: true,
                    action: {}
                )
                
                CustomButton(
                    title: "Disabled Button",
                    icon: "xmark",
                    style: .primary,
                    isDisabled: true,
                    action: {}
                )
                
                CustomButton(
                    title: "Disabled Secondary",
                    icon: "xmark",
                    style: .secondary,
                    isDisabled: true,
                    action: {}
                )
                
                Text("Hover your cursor over buttons to see hover effects")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Button States")
            
            // Dark Mode Preview
            VStack(spacing: 20) {
                Text("Dark Mode Buttons")
                    .font(DesignSystem.Typography.title2)
                
                CustomButton(
                    title: "Primary Dark Mode",
                    icon: "arrow.right",
                    style: .primary,
                    action: {}
                )
                
                CustomButton(
                    title: "Secondary Dark Mode",
                    icon: "doc",
                    style: .secondary,
                    action: {}
                )
                
                CustomButton(
                    title: "Text Dark Mode",
                    icon: "link",
                    style: .text,
                    action: {}
                )
                
                HStack(spacing: 20) {
                    CustomButton(
                        title: "Icon",
                        icon: "star.fill",
                        style: .icon,
                        action: {}
                    )
                    
                    CustomButton(
                        title: "Icon",
                        icon: "moon.fill",
                        style: .icon,
                        action: {}
                    )
                }
            }
            .padding()
            .background(DesignSystem.Colors.background)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Dark Mode Buttons")
            .preferredColorScheme(.dark)
        }
    }
}
