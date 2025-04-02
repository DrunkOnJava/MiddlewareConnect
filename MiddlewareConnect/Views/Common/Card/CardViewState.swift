import SwiftUI

extension CardView {
    /// Internal view state for CardView animations and interactions
    struct ViewState {
        var isPressed: Bool = false
        var isHovered: Bool = false
        
        var backgroundColor: Color {
            if cardStyle == .interactive && (isHovered || isPressed) {
                return DesignSystem.Colors.cardHighlight
            } else {
                return cardStyle == .interactive ? DesignSystem.Colors.cardBackground : DesignSystem.Colors.background
            }
        }
        
        var borderColor: Color {
            switch cardStyle {
            case .bordered:
                return DesignSystem.Colors.divider
            case .interactive:
                return isHovered ? DesignSystem.Colors.primary.opacity(0.3) : DesignSystem.Colors.divider.opacity(0.7)
            default:
                return Color.clear
            }
        }
        
        var shadowColor: Color {
            if cardStyle == .elevated || cardStyle == .interactive {
                return isHovered ? DesignSystem.Colors.primary.opacity(0.15) : Color.black.opacity(0.1)
            } else {
                return Color.clear
            }
        }
        
        var shadowRadius: CGFloat {
            switch cardStyle {
            case .elevated:
                return 8
            case .interactive:
                return isHovered ? 10 : 5
            default:
                return 0
            }
        }
        
        var shadowY: CGFloat {
            switch cardStyle {
            case .elevated:
                return 4
            case .interactive:
                return isHovered ? 6 : 3
            default:
                return 0
            }
        }
        
        private let cardStyle: CardView.Style
        
        init(cardStyle: CardView.Style) {
            self.cardStyle = cardStyle
        }
    }
}