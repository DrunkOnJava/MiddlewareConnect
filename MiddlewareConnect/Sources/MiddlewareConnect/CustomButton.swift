import SwiftUI

/// A custom button component that follows the app's design system
struct CustomButton: View {
    // MARK: - Properties
    
    let title: String
    let icon: String?
    let style: Style
    let size: Size
    let fullWidth: Bool
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    
    @State private var viewState: ViewState
    
    // MARK: - Initialization
    
    init(
        title: String,
        icon: String? = nil,
        style: Style = .primary,
        size: Size = .medium,
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
        self._viewState = State(initialValue: ViewState(style: style, isDisabled: isDisabled))
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                withAnimation(DesignSystem.Animation.quick) {
                    viewState.isPressed = true
                    hapticFeedbackForButtonType(style: style)
                }
                
                // Reset after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(DesignSystem.Animation.quick) {
                        viewState.isPressed = false
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
                viewState.isHovered = hovering
            }
        }
    }
    
    // MARK: - Button Content
    
    private var buttonContent: some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            if isLoading {
                loadingIndicator(tint: viewState.foregroundColor, size: size)
            } else if let icon = icon {
                iconView(name: icon, size: size)
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
        .background(backgroundView(color: viewState.backgroundColor, isText: style == .text))
        .foregroundColor(viewState.foregroundColor)
        .cornerRadius(style == .icon ? size.height / 2 : DesignSystem.Radius.medium)
        .overlay(borderView(
            color: viewState.borderColor, 
            hasBorder: viewState.hasBorder, 
            isIcon: style == .icon, 
            cornerRadius: style == .icon ? size.height / 2 : DesignSystem.Radius.medium
        ))
        .scaleEffect(viewState.isPressed ? 0.97 : 1.0)
        .opacity(isDisabled ? 0.6 : (viewState.isPressed ? 0.9 : 1.0))
        .shadow(
            color: viewState.shadowColor,
            radius: viewState.isPressed ? 2 : (viewState.isHovered ? 6 : 4),
            x: 0,
            y: viewState.isPressed ? 1 : (viewState.isHovered ? 3 : 2)
        )
        .animation(DesignSystem.Animation.spring, value: viewState.isPressed)
        .animation(DesignSystem.Animation.quick, value: viewState.isHovered)
        .animation(DesignSystem.Animation.quick, value: isDisabled)
    }
}