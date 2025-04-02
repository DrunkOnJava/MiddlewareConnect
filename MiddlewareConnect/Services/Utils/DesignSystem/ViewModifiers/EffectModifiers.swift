import SwiftUI

extension DesignSystem {
    /// Creates a subtle pulsing animation
    struct PulseEffect: ViewModifier {
        @State private var isAnimating = false
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(isAnimating ? 1.05 : 1)
                .opacity(isAnimating ? 1 : 0.9)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
        }
    }
}

extension View {
    /// Apply a subtle pulse animation to a view
    func pulseAnimation() -> some View {
        self.modifier(DesignSystem.PulseEffect())
    }
    
    /// Add a floating action button to a view
    func withFloatingActionButton(iconName: String, action: @escaping () -> Void) -> some View {
        ZStack(alignment: .bottomTrailing) {
            self
            
            Button(action: {
                DesignSystem.hapticFeedback(.medium)
                action()
            }) {
                EmptyView()
            }
            .buttonStyle(DesignSystem.FloatingActionButtonStyle(iconName: iconName))
            .padding(DesignSystem.Spacing.medium)
            .padding(.bottom, DesignSystem.Spacing.large)
        }
    }
    
    /// Add horizontal padding for screen edges
    func horizontalScreenPadding() -> some View {
        self.padding(.horizontal, DesignSystem.Spacing.screenEdge)
    }
    
    /// Add screen padding for all edges
    func screenPadding() -> some View {
        self.padding(DesignSystem.Spacing.screenMargin)
    }
    
    /// Apply a glass morphism effect for components that need a blurred backdrop
    func glassBackground() -> some View {
        self
            .background(.ultraThinMaterial)
            .cornerRadius(DesignSystem.Radius.medium)
    }
}