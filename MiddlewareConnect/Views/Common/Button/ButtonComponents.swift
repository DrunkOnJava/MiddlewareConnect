import SwiftUI

extension CustomButton {
    /// Components used to build the CustomButton
    @ViewBuilder
    func loadingIndicator(tint: Color, size: Size) -> some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: tint))
            .scaleEffect(size == .small ? 0.7 : (size == .medium ? 0.8 : 1.0))
    }
    
    @ViewBuilder
    func iconView(name: String, size: Size) -> some View {
        Image(systemName: name)
            .font(.system(size: size.iconSize, weight: .medium))
            .frame(width: size.iconSize, height: size.iconSize)
    }
    
    @ViewBuilder
    func backgroundView(color: Color, isText: Bool) -> some View {
        color.opacity(isText ? 0 : 1)
    }
    
    @ViewBuilder
    func borderView(color: Color, hasBorder: Bool, isIcon: Bool, cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(color, lineWidth: hasBorder ? 1 : 0)
    }
    
    func hapticFeedbackForButtonType(style: Style) {
        switch style {
        case .primary, .destructive:
            DesignSystem.hapticFeedback(.medium)
        case .secondary, .text, .icon:
            DesignSystem.hapticFeedback(.light)
        }
    }
}