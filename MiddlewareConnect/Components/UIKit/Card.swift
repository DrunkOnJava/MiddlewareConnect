/**
 * @fileoverview Card components for MiddlewareConnect
 * @module Card
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - SwiftUI
 * - DesignSystem
 * 
 * Exports:
 * - MCCard struct
 * - MCActionCard struct
 * - MCInfoCard struct
 */

import SwiftUI

/// Standard card component with various styles
public struct MCCard<Content: View>: View {
    // MARK: - Properties
    
    /// Card elevation levels
    public enum Elevation {
        case none
        case low
        case medium
        case high
        
        var shadow: DesignSystem.Shadow {
            switch self {
            case .none:
                return DesignSystem.Shadow(color: Color.clear, radius: 0, x: 0, y: 0)
            case .low:
                return DesignSystem.Shadows.subtle
            case .medium:
                return DesignSystem.Shadows.medium
            case .high:
                return DesignSystem.Shadows.pronounced
            }
        }
    }
    
    /// Card content
    private let content: Content
    
    /// Background color
    private let backgroundColor: Color
    
    /// Border color (if any)
    private let borderColor: Color?
    
    /// Corner radius
    private let cornerRadius: CGFloat
    
    /// Padding
    private let padding: EdgeInsets
    
    /// Elevation/shadow level
    private let elevation: Elevation
    
    /// Whether to expand to fill width
    private let isFullWidth: Bool
    
    // MARK: - Initializers
    
    /// Initialize a card with custom content and styling
    public init(
        backgroundColor: Color = DesignSystem.Colors.surface,
        borderColor: Color? = nil,
        cornerRadius: CGFloat = DesignSystem.Sizing.cornerMedium,
        padding: EdgeInsets? = nil,
        elevation: Elevation = .medium,
        isFullWidth: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.padding = padding ?? EdgeInsets(
            top: DesignSystem.Spacing.m,
            leading: DesignSystem.Spacing.m,
            bottom: DesignSystem.Spacing.m,
            trailing: DesignSystem.Spacing.m
        )
        self.elevation = elevation
        self.isFullWidth = isFullWidth
        self.content = content()
    }
    
    // MARK: - Body
    
    public var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor ?? Color.clear, lineWidth: borderColor != nil ? 1 : 0)
            )
            .shadow(
                color: elevation.shadow.color,
                radius: elevation.shadow.radius,
                x: elevation.shadow.x,
                y: elevation.shadow.y
            )
    }
}

/// Card with a tap action
public struct MCActionCard<Content: View>: View {
    // MARK: - Properties
    
    /// Card content
    private let content: Content
    
    /// Background color
    private let backgroundColor: Color
    
    /// Background color when pressed
    private let pressedBackgroundColor: Color
    
    /// Border color (if any)
    private let borderColor: Color?
    
    /// Corner radius
    private let cornerRadius: CGFloat
    
    /// Padding
    private let padding: EdgeInsets
    
    /// Elevation/shadow level
    private let elevation: MCCard<EmptyView>.Elevation
    
    /// Whether the card is disabled
    private let isDisabled: Bool
    
    /// Action to perform when tapped
    private let action: () -> Void
    
    /// State for press effect
    @State private var isPressed: Bool = false
    
    // MARK: - Initializers
    
    /// Initialize an action card with custom content and styling
    public init(
        backgroundColor: Color = DesignSystem.Colors.surface,
        pressedBackgroundColor: Color? = nil,
        borderColor: Color? = nil,
        cornerRadius: CGFloat = DesignSystem.Sizing.cornerMedium,
        padding: EdgeInsets? = nil,
        elevation: MCCard<EmptyView>.Elevation = .medium,
        isDisabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.pressedBackgroundColor = pressedBackgroundColor ?? backgroundColor.opacity(0.8)
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.padding = padding ?? EdgeInsets(
            top: DesignSystem.Spacing.m,
            leading: DesignSystem.Spacing.m,
            bottom: DesignSystem.Spacing.m,
            trailing: DesignSystem.Spacing.m
        )
        self.elevation = elevation
        self.isDisabled = isDisabled
        self.action = action
        self.content = content()
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: action) {
            content
                .padding(padding)
                .frame(maxWidth: .infinity)
                .background(isPressed ? pressedBackgroundColor : backgroundColor)
                .cornerRadius(cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor ?? Color.clear, lineWidth: borderColor != nil ? 1 : 0)
                )
                .shadow(
                    color: elevation.shadow.color,
                    radius: elevation.shadow.radius,
                    x: elevation.shadow.x,
                    y: elevation.shadow.y
                )
                .opacity(isDisabled ? 0.6 : 1.0)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(DesignSystem.Animation.quick, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle()) // Use plain style to customize appearance
        .disabled(isDisabled)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in self.isPressed = true }
                .onEnded { _ in self.isPressed = false }
        )
    }
}

/// Pre-styled information card with icon, title and description
public struct MCInfoCard: View {
    // MARK: - Properties
    
    /// Title text
    private let title: String
    
    /// Description text (optional)
    private let description: String?
    
    /// Icon name (SF Symbol)
    private let icon: String?
    
    /// Card type determines colors
    public enum CardType {
        case info
        case success
        case warning
        case error
        case neutral
        case custom(iconColor: Color, backgroundColor: Color)
        
        var iconColor: Color {
            switch self {
            case .info:
                return DesignSystem.Colors.info
            case .success:
                return DesignSystem.Colors.success
            case .warning:
                return DesignSystem.Colors.warning
            case .error:
                return DesignSystem.Colors.error
            case .neutral:
                return DesignSystem.Colors.gray600
            case .custom(let iconColor, _):
                return iconColor
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .info:
                return DesignSystem.Colors.info.opacity(0.1)
            case .success:
                return DesignSystem.Colors.success.opacity(0.1)
            case .warning:
                return DesignSystem.Colors.warning.opacity(0.1)
            case .error:
                return DesignSystem.Colors.error.opacity(0.1)
            case .neutral:
                return DesignSystem.Colors.gray100
            case .custom(_, let backgroundColor):
                return backgroundColor
            }
        }
    }
    
    /// Card type
    private let type: CardType
    
    /// Optional action when tapped
    private let action: (() -> Void)?
    
    // MARK: - Initializers
    
    /// Initialize an info card with title, description and icon
    public init(
        title: String,
        description: String? = nil,
        icon: String? = nil,
        type: CardType = .info,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.type = type
        self.action = action
    }
    
    // MARK: - Body
    
    public var body: some View {
        if let action = action {
            MCActionCard(
                backgroundColor: type.backgroundColor,
                borderColor: type.iconColor.opacity(0.3),
                cornerRadius: DesignSystem.Sizing.cornerMedium,
                elevation: .low,
                action: action
            ) {
                cardContent
            }
        } else {
            MCCard(
                backgroundColor: type.backgroundColor,
                borderColor: type.iconColor.opacity(0.3),
                cornerRadius: DesignSystem.Sizing.cornerMedium,
                elevation: .low,
                isFullWidth: true
            ) {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.m) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(type.iconColor)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.bodyMedium.weight(.semibold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if let description = description {
                    Text(description)
                        .font(DesignSystem.Typography.bodySmall)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(DesignSystem.Colors.gray400)
            }
        }
    }
}

// MARK: - Previews
struct MCCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.l) {
                Group {
                    // Standard Card
                    MCCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                            Text("Standard Card")
                                .font(DesignSystem.Typography.headingSmall)
                            
                            Text("This is a basic card component with default styling.")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    
                    // Card with custom styling
                    MCCard(
                        backgroundColor: DesignSystem.Colors.primary.opacity(0.1),
                        borderColor: DesignSystem.Colors.primary.opacity(0.3),
                        cornerRadius: DesignSystem.Sizing.cornerLarge,
                        elevation: .high,
                        isFullWidth: true
                    ) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                            Text("Custom Styled Card")
                                .font(DesignSystem.Typography.headingSmall)
                                .foregroundColor(DesignSystem.Colors.primary)
                            
                            Text("This card has custom background, border, and elevation.")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    
                    // Action Card
                    MCActionCard(
                        action: {}
                    ) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(DesignSystem.Colors.accent)
                            
                            Text("Tap this card")
                                .font(DesignSystem.Typography.bodyMedium)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(DesignSystem.Colors.gray400)
                        }
                    }
                }
                
                Group {
                    // Info Card types
                    MCInfoCard(
                        title: "Information",
                        description: "This is an informational message that provides helpful context.",
                        icon: "info.circle",
                        type: .info
                    )
                    
                    MCInfoCard(
                        title: "Success",
                        description: "The operation was completed successfully.",
                        icon: "checkmark.circle",
                        type: .success
                    )
                    
                    MCInfoCard(
                        title: "Warning",
                        description: "This action might have consequences you should be aware of.",
                        icon: "exclamationmark.triangle",
                        type: .warning
                    )
                    
                    MCInfoCard(
                        title: "Error",
                        description: "Something went wrong. Please try again later.",
                        icon: "xmark.circle",
                        type: .error
                    )
                    
                    MCInfoCard(
                        title: "Tappable Card",
                        description: "Tap this card to perform an action.",
                        icon: "hand.tap",
                        type: .neutral,
                        action: {}
                    )
                }
            }
            .padding()
        }
    }
}
