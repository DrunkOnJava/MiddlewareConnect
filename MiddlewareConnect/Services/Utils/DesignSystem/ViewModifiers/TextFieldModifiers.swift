import SwiftUI

extension View {
    /// Apply a consistent text field style
    func textFieldStyle() -> some View {
        self.padding(DesignSystem.Spacing.medium)
            .background(DesignSystem.Colors.background)
            .cornerRadius(DesignSystem.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(DesignSystem.Colors.divider, lineWidth: 1)
            )
            .shadow(color: DesignSystem.Colors.cardShadow.opacity(0.5), radius: 2, x: 0, y: 1)
    }
    
    /// Placeholder view for text fields
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}