import SwiftUI

/// A simple placeholder view for features that are under development
func placeholderView(title: String) -> some View {
    VStack {
        Text(title)
            .font(DesignSystem.Typography.title)
            .padding()
        
        Text("This feature is coming soon")
            .foregroundColor(DesignSystem.Colors.secondaryText)
        
        Spacer()
            .frame(height: 40)
        
        Image(systemName: "hammer.fill")
            .font(.system(size: 60))
            .foregroundColor(DesignSystem.Colors.secondaryText)
            .opacity(0.5)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DesignSystem.Colors.background)
}