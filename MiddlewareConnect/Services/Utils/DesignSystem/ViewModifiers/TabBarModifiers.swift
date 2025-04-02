import SwiftUI

extension DesignSystem {
    /// Tab bar item style
    struct TabBarItemStyle: ViewModifier {
        var isSelected: Bool
        var systemImage: String
        
        func body(content: Content) -> some View {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: DesignSystem.Spacing.tabBarIconSize, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? DesignSystem.Colors.tabBarSelected : DesignSystem.Colors.tabBarUnselected)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
                
                content
                    .font(DesignSystem.Typography.tabBar)
                    .foregroundColor(isSelected ? DesignSystem.Colors.tabBarSelected : DesignSystem.Colors.tabBarUnselected)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

extension View {
    /// Apply tab bar item style
    func tabBarItem(isSelected: Bool, systemImage: String) -> some View {
        modifier(DesignSystem.TabBarItemStyle(isSelected: isSelected, systemImage: systemImage))
    }
}