import SwiftUI

// MARK: - Preview

struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Button Styles Preview
            VStack(spacing: 20) {
                Text("Button Styles")
                    .font(DesignSystem.Typography.title2)
                
                CustomButton(
                    title: "Primary Button",
                    icon: "arrow.right",
                    style: .primary,
                    action: {}
                )
                
                CustomButton(
                    title: "Secondary Button",
                    icon: "doc",
                    style: .secondary,
                    action: {}
                )
                
                CustomButton(
                    title: "Destructive Button",
                    icon: "trash",
                    style: .destructive,
                    action: {}
                )
                
                CustomButton(
                    title: "Text Button",
                    icon: "link",
                    style: .text,
                    action: {}
                )
                
                HStack(spacing: 20) {
                    CustomButton(
                        title: "Icon",
                        icon: "star.fill",
                        style: .icon,
                        action: {}
                    )
                    
                    CustomButton(
                        title: "Icon",
                        icon: "bell.fill",
                        style: .icon,
                        action: {}
                    )
                    
                    CustomButton(
                        title: "Icon",
                        icon: "heart.fill",
                        style: .icon,
                        action: {}
                    )
                }
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Button Styles")
            
            // Button Sizes Preview
            VStack(spacing: 20) {
                Text("Button Sizes")
                    .font(DesignSystem.Typography.title2)
                
                CustomButton(
                    title: "Small Button",
                    icon: "arrow.right",
                    style: .primary,
                    size: .small,
                    action: {}
                )
                
                CustomButton(
                    title: "Medium Button (Default)",
                    icon: "arrow.right",
                    style: .primary,
                    size: .medium,
                    action: {}
                )
                
                CustomButton(
                    title: "Large Button",
                    icon: "arrow.right",
                    style: .primary,
                    size: .large,
                    action: {}
                )
                
                CustomButton(
                    title: "Full Width Button",
                    icon: "arrow.right",
                    style: .primary,
                    fullWidth: true,
                    action: {}
                )
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Button Sizes")
            
            // Button States Preview
            VStack(spacing: 20) {
                Text("Button States")
                    .font(DesignSystem.Typography.title2)
                
                CustomButton(
                    title: "Normal Button",
                    icon: "arrow.right",
                    style: .primary,
                    action: {}
                )
                
                CustomButton(
                    title: "Loading Button",
                    style: .primary,
                    isLoading: true,
                    action: {}
                )
                
                CustomButton(
                    title: "Disabled Button",
                    icon: "xmark",
                    style: .primary,
                    isDisabled: true,
                    action: {}
                )
                
                CustomButton(
                    title: "Disabled Secondary",
                    icon: "xmark",
                    style: .secondary,
                    isDisabled: true,
                    action: {}
                )
                
                Text("Hover your cursor over buttons to see hover effects")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Button States")
            
            // Dark Mode Preview
            VStack(spacing: 20) {
                Text("Dark Mode Buttons")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.text)
                
                CustomButton(
                    title: "Primary Dark Mode",
                    icon: "arrow.right",
                    style: .primary,
                    action: {}
                )
                
                CustomButton(
                    title: "Secondary Dark Mode",
                    icon: "doc",
                    style: .secondary,
                    action: {}
                )
                
                CustomButton(
                    title: "Text Dark Mode",
                    icon: "link",
                    style: .text,
                    action: {}
                )
                
                HStack(spacing: 20) {
                    CustomButton(
                        title: "Icon",
                        icon: "star.fill",
                        style: .icon,
                        action: {}
                    )
                    
                    CustomButton(
                        title: "Icon",
                        icon: "moon.fill",
                        style: .icon,
                        action: {}
                    )
                }
            }
            .padding()
            .background(DesignSystem.Colors.background)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Dark Mode Buttons")
            .preferredColorScheme(.dark)
        }
    }
}