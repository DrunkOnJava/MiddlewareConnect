import SwiftUI

extension CustomTextField {
    /// UI Components used in the CustomTextField
    
    /// Background view for the text field
    @ViewBuilder
    func textFieldBackground() -> some View {
        DesignSystem.Colors.secondaryBackground
            .cornerRadius(DesignSystem.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(currentFieldState.color, lineWidth: borderWidth)
            )
    }
    
    /// Title view shown above the text field
    @ViewBuilder
    func titleView() -> some View {
        if !title.isEmpty {
            Text(title)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .animation(nil, value: text) // Prevent title from animating
        }
    }
    
    /// Leading icon view
    @ViewBuilder
    func leadingIconView() -> some View {
        if let icon = icon {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)
        }
    }
    
    /// State icon view (success/error)
    @ViewBuilder
    func stateIconView() -> some View {
        if let stateIcon = currentFieldState.icon {
            Image(systemName: stateIcon)
                .foregroundColor(currentFieldState.color)
                .transition(.opacity)
        }
    }
    
    /// Clear button for the text field
    @ViewBuilder
    func clearButton() -> some View {
        if clearable && !text.isEmpty {
            Button(action: {
                withAnimation {
                    text = ""
                    DesignSystem.hapticFeedback(.light)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
            .transition(.opacity)
        }
    }
    
    /// Security toggle button for secure fields
    @ViewBuilder
    func securityToggleButton() -> some View {
        if isSecure {
            Button(action: {
                withAnimation {
                    isTextVisible.toggle()
                    DesignSystem.hapticFeedback(.light)
                }
            }) {
                Image(systemName: isTextVisible ? "eye.slash" : "eye")
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
    }
    
    /// Helper/error/success message view
    @ViewBuilder
    func messageView() -> some View {
        if let message = currentMessage {
            Text(message)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(messageColor)
                .padding(.horizontal, DesignSystem.Spacing.small)
                .animation(.easeInOut(duration: 0.2), value: currentMessage)
        }
    }
}