import SwiftUI

extension CustomButton {
    /// Button size options for the `CustomButton` component
    enum Size {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 56
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return DesignSystem.Spacing.small
            case .medium: return DesignSystem.Spacing.medium
            case .large: return DesignSystem.Spacing.large
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 20
            }
        }
        
        var font: Font {
            switch self {
            case .small: return DesignSystem.Typography.subheadline
            case .medium: return DesignSystem.Typography.headline
            case .large: return DesignSystem.Typography.title3
            }
        }
    }
}