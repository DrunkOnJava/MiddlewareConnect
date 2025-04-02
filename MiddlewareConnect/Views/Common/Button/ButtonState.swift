import SwiftUI

extension CustomButton {
    /// Internal view state and computed properties for CustomButton
    struct ViewState {
        let style: Style
        let isDisabled: Bool
        var isPressed: Bool = false
        var isHovered: Bool = false
        
        init(style: Style, isDisabled: Bool) {
            self.style = style
            self.isDisabled = isDisabled
        }
        
        // Extract custom color if available
        private var customColor: Color? {
            if case .custom(let color) = style {
                return color
            }
            return nil
        }
        
        var backgroundColor: Color {
            if isDisabled {
                return disabledBackgroundColor
            }
            
            if isPressed {
                return pressedBackgroundColor
            }
            
            if isHovered && (style == .primary || style == .destructive || customColor != nil) {
                return hoverBackgroundColor
            }
            
            switch style {
            case .primary:
                return DesignSystem.Colors.primary
            case .secondary:
                return isHovered ? DesignSystem.Colors.primary.opacity(0.05) : Color.clear
            case .destructive:
                return DesignSystem.Colors.error
            case .text, .icon:
                return isHovered ? DesignSystem.Colors.primary.opacity(0.05) : Color.clear
            case .custom(let color):
                return color
            }
        }
        
        var hoverBackgroundColor: Color {
            switch style {
            case .primary:
                return DesignSystem.Colors.primary.opacity(0.9)
            case .secondary:
                return DesignSystem.Colors.primary.opacity(0.1)
            case .destructive:
                return DesignSystem.Colors.error.opacity(0.9)
            case .text, .icon:
                return DesignSystem.Colors.primary.opacity(0.1)
            case .custom(let color):
                return color.opacity(0.9)
            }
        }
        
        var pressedBackgroundColor: Color {
            switch style {
            case .primary:
                return DesignSystem.Colors.primary.opacity(0.8)
            case .secondary:
                return DesignSystem.Colors.primary.opacity(0.15)
            case .destructive:
                return DesignSystem.Colors.error.opacity(0.8)
            case .text, .icon:
                return DesignSystem.Colors.primary.opacity(0.15)
            case .custom(let color):
                return color.opacity(0.8)
            }
        }
        
        var foregroundColor: Color {
            if isDisabled {
                return disabledForegroundColor
            }
            
            switch style {
            case .primary, .destructive, .custom:
                return .white
            case .secondary, .text, .icon:
                return DesignSystem.Colors.primary
            }
        }
        
        var borderColor: Color {
            if isDisabled {
                return disabledBorderColor
            }
            
            if isPressed {
                return pressedBorderColor
            }
            
            switch style {
            case .primary, .destructive, .custom:
                return Color.clear
            case .secondary:
                return isHovered ? DesignSystem.Colors.primary : DesignSystem.Colors.primary.opacity(0.5)
            case .text, .icon:
                return isHovered ? DesignSystem.Colors.primary.opacity(0.3) : Color.clear
            }
        }
        
        var pressedBorderColor: Color {
            switch style {
            case .primary, .destructive, .custom:
                return Color.clear
            case .secondary, .text, .icon:
                return DesignSystem.Colors.primary
            }
        }
        
        var disabledBackgroundColor: Color {
            switch style {
            case .primary:
                return DesignSystem.Colors.primary.opacity(0.3)
            case .secondary, .text, .icon:
                return Color.clear
            case .destructive:
                return DesignSystem.Colors.error.opacity(0.3)
            case .custom(let color):
                return color.opacity(0.3)
            }
        }
        
        var disabledForegroundColor: Color {
            switch style {
            case .primary, .destructive, .custom:
                return .white.opacity(0.7)
            case .secondary, .text, .icon:
                return DesignSystem.Colors.primary.opacity(0.5)
            }
        }
        
        var disabledBorderColor: Color {
            switch style {
            case .primary, .destructive, .text, .icon, .custom:
                return Color.clear
            case .secondary:
                return DesignSystem.Colors.primary.opacity(0.3)
            }
        }
        
        var shadowColor: Color {
            guard !isDisabled else { return Color.clear }
            
            switch style {
            case .primary:
                return DesignSystem.Colors.primary.opacity(0.4)
            case .destructive:
                return DesignSystem.Colors.error.opacity(0.4)
            case .custom(let color):
                return color.opacity(0.4)
            case .secondary, .text, .icon:
                return isHovered ? Color.black.opacity(0.05) : Color.clear
            }
        }
        
        var hasBorder: Bool {
            style == .secondary || (style == .text && isHovered)
        }
    }
}