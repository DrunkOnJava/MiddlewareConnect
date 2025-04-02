/**
 * @fileoverview Extensions to the design system for backward compatibility
 * @module Models
 * 
 * Created: 2025-03-29
 * Last Modified: 2025-03-29
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - DesignSystem extension methods
 * 
 * Notes:
 * - Enhances the design system with extension methods for compatibility with existing code
 */

import SwiftUI
import UIKit

/// Extensions to the DesignSystem alias to ensure backward compatibility with existing code
extension DesignSystem {
    /// Static values for haptic feedback patterns
    public static let light = HapticFeedbackIntensity.light
    public static let medium = HapticFeedbackIntensity.medium
    public static let heavy = HapticFeedbackIntensity.heavy
    
    /// Static values for notification haptic types
    public static let success = NotificationHapticType.success
    public static let warning = NotificationHapticType.warning
    public static let error = NotificationHapticType.error
    
    /// Instance-based haptic feedback generation for backward compatibility
    public func hapticFeedback(_ intensity: HapticFeedbackIntensity) {
        AppDesignSystem.hapticFeedback(intensity)
    }
    
    /// Instance-based notification haptic generation for backward compatibility
    public func notificationHaptic(_ type: NotificationHapticType) {
        AppDesignSystem.notificationHaptic(type)
    }
    
    /// Reference to Radius struct for backward compatibility
    public var Radius: AppDesignSystem.Radius.Type {
        return AppDesignSystem.Radius.self
    }
    
    /// Static reference to Radius struct for backward compatibility
    public static var Radius: AppDesignSystem.Radius.Type {
        return AppDesignSystem.Radius.self
    }
}

/// Extension to add missing Typography properties
extension DesignSystem.Typography {
    /// Headline font style as static property
    public static var headline: Font {
        AppDesignSystem.Typography.headline
    }
    
    /// Subheadline font style as static property
    public static var subheadline: Font {
        AppDesignSystem.Typography.subheadline
    }
    
    /// Title3 font style as static property
    public static var title3: Font {
        AppDesignSystem.Typography.title3
    }
}
