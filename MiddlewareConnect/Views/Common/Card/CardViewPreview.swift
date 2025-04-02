import SwiftUI

// MARK: - Preview

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CardView(title: "Standard Card", icon: "doc.text") {
                Text("This is a standard card with a title and icon.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            CardView(title: "Elevated Card", icon: "star.fill", style: .elevated) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This is an elevated card with a shadow.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text("It stands out from the rest of the content.")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            CardView(title: "Bordered Card", style: .bordered) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(DesignSystem.Colors.info)
                    
                    Text("This is a bordered card with a border.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text)
                }
            }
            
            CardView(title: "Interactive Card", icon: "hand.tap", style: .interactive, action: {
                print("Card tapped!")
            }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This card is tappable with hover effects.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Text("Hover over me and click to see the interactions!")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            CardView {
                Text("This is a card without a title or icon.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text)
            }
        }
        .padding()
        .background(DesignSystem.Colors.secondaryBackground)
        .previewLayout(.sizeThatFits)
        
        // Dark mode preview
        VStack(spacing: 20) {
            CardView(title: "Dark Mode Card", icon: "moon.fill") {
                Text("This shows how cards look in dark mode.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            CardView(title: "Interactive Dark Mode", icon: "sparkles", style: .interactive, action: {
                print("Dark mode card tapped!")
            }) {
                Text("Interactive cards work in dark mode too!")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text)
            }
        }
        .padding()
        .background(DesignSystem.Colors.secondaryBackground)
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}