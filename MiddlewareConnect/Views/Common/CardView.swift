import SwiftUI

/// A custom card component that follows the app's design system
struct CardView<Content: View>: View {
    enum CardStyle {
        case standard
        case elevated
        case bordered
        case interactive  // New style for cards that can be tapped
    }
    
    let title: String?
    let icon: String?
    let style: CardStyle
    let content: Content
    let action: (() -> Void)?
    
    @State private var isPressed: Bool = false
    @State private var isHovered: Bool = false
    
    init(
        title: String? = nil,
        icon: String? = nil,
        style: CardStyle = .standard,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        cardContent
            .contentShape(Rectangle())  // Makes the entire card tappable
            .onTapGesture {
                if let action = action {
                    withAnimation(DesignSystem.Animation.quick) {
                        isPressed = true
                        DesignSystem.hapticFeedback(.light)
                    }
                    
                    // Reset after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(DesignSystem.Animation.quick) {
                            isPressed = false
                        }
                        action()
                    }
                }
            }
            .onHover { hovering in
                withAnimation(DesignSystem.Animation.quick) {
                    isHovered = hovering
                }
            }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            // Title and icon
            if let title = title {
                HStack(spacing: DesignSystem.Spacing.small) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(DesignSystem.Colors.primary)
                            .font(.system(size: 18, weight: .semibold))
                            .animation(DesignSystem.Animation.quick, value: isPressed)
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
                        .opacity(isHovered ? 1.0 : 0.7)
                        .offset(x: isHovered ? 3 : 0)
                        .animation(DesignSystem.Animation.spring, value: isHovered)
                }
                .padding(.top, DesignSystem.Spacing.xSmall)
            }
        }
        .padding(DesignSystem.Spacing.medium)
        .background(backgroundColor)
        .cornerRadius(DesignSystem.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                .stroke(borderColor, lineWidth: style == .bordered || style == .interactive ? 1 : 0)
        )
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: 0,
            y: shadowY
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .opacity(isPressed ? 0.95 : 1.0)
    }
    
    // Dynamic background color based on state and style
    private var backgroundColor: Color {
        if style == .interactive && (isHovered || isPressed) {
            return DesignSystem.Colors.cardHighlight
        } else {
            return style == .interactive ? DesignSystem.Colors.cardBackground : DesignSystem.Colors.background
        }
    }
    
    // Dynamic border color
    private var borderColor: Color {
        switch style {
        case .bordered:
            return DesignSystem.Colors.divider
        case .interactive:
            return isHovered ? DesignSystem.Colors.primary.opacity(0.3) : DesignSystem.Colors.divider.opacity(0.7)
        default:
            return Color.clear
        }
    }
    
    // Dynamic shadow color
    private var shadowColor: Color {
        if style == .elevated || style == .interactive {
            return isHovered ? DesignSystem.Colors.primary.opacity(0.15) : Color.black.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    // Dynamic shadow radius
    private var shadowRadius: CGFloat {
        switch style {
        case .elevated:
            return 8
        case .interactive:
            return isHovered ? 10 : 5
        default:
            return 0
        }
    }
    
    // Dynamic shadow y-offset
    private var shadowY: CGFloat {
        switch style {
        case .elevated:
            return 4
        case .interactive:
            return isHovered ? 6 : 3
        default:
            return 0
        }
    }
}

// MARK: - Preview

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CardView(title: "Standard Card", icon: "doc.text") {
                Text("This is a standard card with a title and icon.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            CardView(title: "Elevated Card", icon: "star.fill", style: .elevated) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This is an elevated card with a shadow.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text("It stands out from the rest of the content.")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            CardView(title: "Bordered Card", style: .bordered) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(DesignSystem.Colors.info)
                    
                    Text("This is a bordered card with a border.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text)
                }
            }
            
            CardView(title: "Interactive Card", icon: "hand.tap", style: .interactive, action: {
                print("Card tapped!")
            }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This card is tappable with hover effects.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text("Hover over me and click to see the interactions!")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            CardView {
                Text("This is a card without a title or icon.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text)
            }
        }
        .padding()
        .background(DesignSystem.Colors.secondaryBackground)
        .previewLayout(.sizeThatFits)
        
        // Dark mode preview
        VStack(spacing: 20) {
            CardView(title: "Dark Mode Card", icon: "moon.fill") {
                Text("This shows how cards look in dark mode.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            CardView(title: "Interactive Dark Mode", icon: "sparkles", style: .interactive, action: {
                print("Dark mode card tapped!")
            }) {
                Text("Interactive cards work in dark mode too!")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text)
            }
        }
        .padding()
        .background(DesignSystem.Colors.secondaryBackground)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
