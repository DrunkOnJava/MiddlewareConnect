import SwiftUI

extension CustomTextField {
    /// The field states for the CustomTextField
    enum FieldState {
        case normal
        case success
        case error
        case focused
        
        var color: Color {
            switch self {
            case .normal: return DesignSystem.Colors.divider
            case .success: return DesignSystem.Colors.success
            case .error: return DesignSystem.Colors.error
            case .focused: return DesignSystem.Colors.primary
            }
        }
        
        var icon: String? {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            default: return nil
            }
        }
    }
}