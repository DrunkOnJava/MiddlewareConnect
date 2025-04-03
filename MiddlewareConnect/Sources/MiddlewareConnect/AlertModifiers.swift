import SwiftUI

extension DesignSystem {
    /// Alert message view
    struct AlertMessage: ViewModifier {
        var type: AlertType
        
        enum AlertType {
            case success, error, warning, info
            
            var color: Color {
                switch self {
                case .success: return DesignSystem.Colors.success
                case .error: return DesignSystem.Colors.error
                case .warning: return DesignSystem.Colors.warning
                case .info: return DesignSystem.Colors.info
                }
            }
            
            var icon: String {
                switch self {
                case .success: return "checkmark.circle.fill"
                case .error: return "exclamationmark.circle.fill"
                case .warning: return "exclamationmark.triangle.fill"
                case .info: return "info.circle.fill"
                }
            }
        }
        
        func body(content: Content) -> some View {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.small) {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                
                content
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.text)
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.medium)
            .background(type.color.opacity(0.1))
            .cornerRadius(DesignSystem.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(type.color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

extension View {
    /// Apply alert message style
    func alertMessage(type: DesignSystem.AlertMessage.AlertType) -> some View {
        modifier(DesignSystem.AlertMessage(type: type))
    }
}