import SwiftUI

extension DesignSystem {
    // MARK: - Haptic Feedback
    
    static func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    static func selectionHaptic() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    static func notificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}