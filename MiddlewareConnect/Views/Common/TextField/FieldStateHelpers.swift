import SwiftUI

extension CustomTextField {
    /// Helper computed properties for field state and messaging
    var currentFieldState: FieldState {
        if errorMessage != nil && !errorMessage!.isEmpty {
            return .error
        } else if successMessage != nil && !successMessage!.isEmpty {
            return .success
        } else if isFocused {
            return .focused
        } else {
            return fieldState
        }
    }
    
    var currentMessage: String? {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            return errorMessage
        } else if let successMessage = successMessage, !successMessage.isEmpty {
            return successMessage
        } else if let helpText = helpText, !helpText.isEmpty {
            return helpText
        }
        return nil
    }
    
    var messageColor: Color {
        if errorMessage != nil && !errorMessage!.isEmpty {
            return DesignSystem.Colors.error
        } else if successMessage != nil && !successMessage!.isEmpty {
            return DesignSystem.Colors.success
        } else {
            return DesignSystem.Colors.tertiaryText
        }
    }
    
    var iconColor: Color {
        if isFocused {
            return DesignSystem.Colors.primary
        } else {
            return DesignSystem.Colors.secondaryText
        }
    }
    
    var borderWidth: CGFloat {
        if currentFieldState == .focused || 
           currentFieldState == .error || 
           currentFieldState == .success {
            return 2
        } else {
            return 1
        }
    }
}