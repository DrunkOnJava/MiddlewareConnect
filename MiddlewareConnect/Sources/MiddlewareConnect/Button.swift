/**
@fileoverview Button components for MiddlewareConnect
@module Button
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- SwiftUI
- DesignSystem
Exports:
- MCButton struct
- MCIconButton struct
- MCFloatingActionButton struct
/

import SwiftUI

/// Standard button component with multiple styles
public struct MCButton: View {
    // MARK: - Properties
    
    /// Button style variants
    public enum Style {
        case primary
        case secondary
        case tertiary
        case danger
        case success
        case ghost
        case link
    }
    
    /// Button size variants
    public enum Size {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return DesignSystem.Sizing.buttonSmall
            case .medium: return DesignSystem.Sizing.buttonMedium
            case .large: return DesignSystem.Sizing.buttonLarge
            }
        }
        
        var font: Font {
            switch self {
            case .small: return DesignSystem.Typography.labelMedium
            case .medium: return DesignSystem.Typography.bodyMedium
            case .large: return DesignSystem.Typography.bodyLarge
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(
                top: DesignSystem.Spacing.xs,
                leading: DesignSystem.Spacing.s,
                bottom: DesignSystem.Spacing.xs,
                trailing: DesignSystem.Spacing.s
            )
            case .medium: return EdgeInsets(
                top: DesignSystem.Spacing.s,
                leading: DesignSystem.Spacing.m,
                bottom: DesignSystem.Spacing.s,
                trailing: DesignSystem.Spacing.m
            )
            case .large: return EdgeInsets(
                top: DesignSystem.Spacing.m,
                leading: DesignSystem.Spacing.l,
                bottom: DesignSystem.Spacing.m,
                trailing: DesignSystem.Spacing.l
            )
            }
        }
    }
    
    /// Text to display on the button
    private let title: String
    
    /// Icon to display (optional)
    private let icon: String?
    
    /// Button style
    private let style: Style
    
    /// Button size
    private let size: Size
    
    /// Whether to make the button full width
    private let isFullWidth: Bool
    
    /// Whether the button is in a loading state
    @Binding private var isLoading: Bool
    
    /// Whether the button is disabled
    private let isDisabled: Bool
    
    /// Action to perform when tapped
    private let action: () -> Void
    
    // MARK: - Initializers
    
    /// Initialize a button with all options
    public init(
        title: String,
        icon: String? = nil,
        style: Style = .primary,
        size: Size = .medium,
        isFullWidth: Bool = false,
        isLoading: Binding<Bool> = .constant(false),
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isFullWidth = isFullWidth
        self._isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: {
            if !isLoading && !isDisabled {
                action()
            }
        }) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(size == .small ? 0.8 : 1.0)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(size.font)
                }
                
                Text(title)
                    .font(size.font.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(size.padding)
            .frame(height: size.height)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(backgroundView)
            .foregroundColor(foregroundColor)
            .cornerRadius(DesignSystem.Sizing.cornerMedium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Sizing.cornerMedium)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .disabled(isDisabled || isLoading)
    }
    
    // MARK: - Helper Computed Properties
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return DesignSystem.Colors.primary
        case .secondary:
            return DesignSystem.Colors.secondary
        case .tertiary:
            return Color.clear
        case .danger:
            return DesignSystem.Colors.error
        case .success:
            return DesignSystem.Colors.success
        case .ghost, .link:
            return Color.clear
        }
    }
    
    private var backgroundView: some View {
        backgroundColor
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return DesignSystem.Colors.textOnPrimary
        case .secondary:
            return DesignSystem.Colors.textOnSecondary
        case .tertiary:
            return DesignSystem.Colors.primary
        case .danger:
            return Color.white
        case .success:
            return Color.white
        case .ghost:
            return DesignSystem.Colors.textPrimary
        case .link:
            return DesignSystem.Colors.primary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .tertiary:
            return DesignSystem.Colors.primary.opacity(0.3)
        case .ghost:
            return DesignSystem.Colors.gray300
        case .link:
            return Color.clear
        default:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .tertiary, .ghost:
            return 1
        default:
            return 0
        }
    }
}

/// Icon-only button
public struct MCIconButton: View {
    // MARK: - Properties
    
    /// Button style variants
    public enum Style {
        case primary
        case secondary
        case tertiary
        case ghost
    }
    
    /// Button size variants
    public enum Size {
        case small
        case medium
        case large
        
        var iconSize: CGFloat {
            switch self {
            case .small: return DesignSystem.Sizing.iconSmall
            case .medium: return DesignSystem.Sizing.iconMedium
            case .large: return DesignSystem.Sizing.iconLarge
            }
        }
        
        var buttonSize: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            }
        }
    }
    
    /// Icon to display
    private let icon: String
    
    /// Button style
    private let style: Style
    
    /// Button size
    private let size: Size
    
    /// Whether the button is disabled
    private let isDisabled: Bool
    
    /// Accessibility label
    private let accessibilityLabel: String
    
    /// Action to perform when tapped
    private let action: () -> Void
    
    // MARK: - Initializers
    
    /// Initialize an icon button
    public init(
        icon: String,
        style: Style = .primary,
        size: Size = .medium,
        isDisabled: Bool = false,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.isDisabled = isDisabled
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize))
                .frame(width: size.buttonSize, height: size.buttonSize)
                .background(backgroundView)
                .foregroundColor(foregroundColor)
                .cornerRadius(size.buttonSize / 2)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .opacity(isDisabled ? 0.6 : 1.0)
        }
        .accessibility(label: Text(accessibilityLabel))
        .disabled(isDisabled)
    }
    
    // MARK: - Helper Computed Properties
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return DesignSystem.Colors.primary
        case .secondary:
            return DesignSystem.Colors.secondary
        case .tertiary, .ghost:
            return Color.clear
        }
    }
    
    private var backgroundView: some View {
        backgroundColor
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return DesignSystem.Colors.textOnPrimary
        case .secondary:
            return DesignSystem.Colors.textOnSecondary
        case .tertiary:
            return DesignSystem.Colors.primary
        case .ghost:
            return DesignSystem.Colors.textPrimary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .tertiary:
            return DesignSystem.Colors.primary.opacity(0.3)
        case .ghost:
            return DesignSystem.Colors.gray300
        default:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .tertiary, .ghost:
            return 1
        default:
            return 0
        }
    }
}

/// Floating action button
public struct MCFloatingActionButton: View {
    // MARK: - Properties
    
    /// Icon to display
    private let icon: String
    
    /// Color of the button
    private let color: Color
    
    /// Size of the button
    private let size: CGFloat
    
    /// Whether the button shows a shadow
    private let hasShadow: Bool
    
    /// Accessibility label
    private let accessibilityLabel: String
    
    /// Action to perform when tapped
    private let action: () -> Void
    
    // MARK: - Initializers
    
    /// Initialize a floating action button
    public init(
        icon: String,
        color: Color = DesignSystem.Colors.primary,
        size: CGFloat = 56,
        hasShadow: Bool = true,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.color = color
        self.size = size
        self.hasShadow = hasShadow
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(color)
                .clipShape(Circle())
                .shadow(
                    color: hasShadow ? Color.black.opacity(0.2) : Color.clear,
                    radius: hasShadow ? 8 : 0,
                    x: 0,
                    y: hasShadow ? 4 : 0
                )
        }
        .accessibility(label: Text(accessibilityLabel))
    }
}

// MARK: - Preview
struct MCButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            Group {
                MCButton(title: "Primary Button", action: {})
                MCButton(title: "Secondary Button", style: .secondary, action: {})
                MCButton(title: "Tertiary Button", style: .tertiary, action: {})
                MCButton(title: "Danger Button", style: .danger, action: {})
                MCButton(title: "Success Button", style: .success, action: {})
                MCButton(title: "Ghost Button", style: .ghost, action: {})
                MCButton(title: "Link Button", style: .link, action: {})
            }
            
            Group {
                MCButton(title: "With Icon", icon: "star.fill", action: {})
                MCButton(
                    title: "Loading Button",
                    isLoading: .constant(true),
                    action: {}
                )
                MCButton(
                    title: "Disabled Button",
                    isDisabled: true,
                    action: {}
                )
                MCButton(
                    title: "Full Width Button",
                    isFullWidth: true,
                    action: {}
                )
            }
            
            HStack(spacing: DesignSystem.Spacing.m) {
                MCIconButton(
                    icon: "star.fill",
                    style: .primary,
                    accessibilityLabel: "Favorite",
                    action: {}
                )
                
                MCIconButton(
                    icon: "trash",
                    style: .secondary,
                    accessibilityLabel: "Delete",
                    action: {}
                )
                
                MCIconButton(
                    icon: "pencil",
                    style: .tertiary,
                    accessibilityLabel: "Edit",
                    action: {}
                )
                
                MCIconButton(
                    icon: "info.circle",
                    style: .ghost,
                    accessibilityLabel: "Info",
                    action: {}
                )
            }
            
            MCFloatingActionButton(
                icon: "plus",
                accessibilityLabel: "Add new item",
                action: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
