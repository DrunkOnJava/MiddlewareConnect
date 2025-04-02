import SwiftUI

/// A custom card component that follows the app's design system
struct CardView<Content: View>: View {
    // MARK: - Properties
    
    let title: String?
    let icon: String?
    let style: Style
    let content: Content
    let action: (() -> Void)?
    
    @State private var viewState: ViewState
    
    // MARK: - Initialization
    
    init(
        title: String? = nil,
        icon: String? = nil,
        style: Style = .standard,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
        self.content = content()
        self._viewState = State(initialValue: ViewState(cardStyle: style))
    }
    
    // MARK: - Body
    
    var body: some View {
        buildCardContent(viewState: viewState)
            .contentShape(Rectangle())  // Makes the entire card tappable
            .onTapGesture {
                if let action = action {
                    withAnimation(DesignSystem.Animation.quick) {
                        viewState.isPressed = true
                        DesignSystem.hapticFeedback(.light)
                    }
                    
                    // Reset after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(DesignSystem.Animation.quick) {
                            viewState.isPressed = false
                        }
                        action()
                    }
                }
            }
            .onHover { hovering in
                withAnimation(DesignSystem.Animation.quick) {
                    viewState.isHovered = hovering
                }
            }
    }
}