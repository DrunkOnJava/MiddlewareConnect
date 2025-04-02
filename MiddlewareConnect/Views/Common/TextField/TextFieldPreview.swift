import SwiftUI

// MARK: - Preview

struct CustomTextField_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Basic Fields
            VStack(spacing: 20) {
                Text("Basic Fields")
                    .font(DesignSystem.Typography.title2)
                    .padding(.bottom, 8)
                
                CustomTextField(
                    title: "Username",
                    placeholder: "Enter your username",
                    text: .constant(""),
                    icon: "person",
                    helpText: "Your account username"
                )
                
                CustomTextField(
                    title: "Password",
                    placeholder: "Enter your password",
                    text: .constant("password123"),
                    icon: "lock",
                    isSecure: true,
                    helpText: "At least 8 characters recommended"
                )
                
                CustomTextField(
                    title: "Email",
                    placeholder: "Enter your email",
                    text: .constant("user@example.com"),
                    icon: "envelope",
                    keyboardType: .emailAddress,
                    autocapitalization: .none,
                    successMessage: "Email format is valid"
                )
                
                CustomTextField(
                    title: "API Key",
                    placeholder: "Enter your API key",
                    text: .constant("sk-1234567890abcdef"),
                    icon: "key",
                    keyboardType: .asciiCapable,
                    autocapitalization: .none,
                    autocorrection: .no,
                    clearable: true
                )
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Basic Fields")
            
            // Field States
            VStack(spacing: 20) {
                Text("Field States")
                    .font(DesignSystem.Typography.title2)
                    .padding(.bottom, 8)
                
                CustomTextField(
                    title: "Normal State",
                    placeholder: "This is the default state",
                    text: .constant(""),
                    icon: "doc.text",
                    helpText: "Helper text appears below"
                )
                
                CustomTextField(
                    title: "Focused State",
                    placeholder: "This field has focus",
                    text: .constant("Focused field"),
                    icon: "selection.pin.in.out",
                    fieldState: .focused
                )
                
                CustomTextField(
                    title: "Success State",
                    placeholder: "This input is valid",
                    text: .constant("Valid input"),
                    icon: "checkmark.seal",
                    successMessage: "Your input is valid and has been saved"
                )
                
                CustomTextField(
                    title: "Error State",
                    placeholder: "This input has errors",
                    text: .constant("Invalid input"),
                    icon: "exclamationmark.triangle",
                    errorMessage: "Please check your input and try again"
                )
                
                CustomTextField(
                    title: "Clearable Field",
                    placeholder: "Type something to clear",
                    text: .constant("Click the X to clear this"),
                    icon: "trash",
                    clearable: true
                )
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Field States")
            
            // Special Fields
            VStack(spacing: 20) {
                Text("Special Fields")
                    .font(DesignSystem.Typography.title2)
                    .padding(.bottom, 8)
                
                CustomTextField(
                    title: "Password with Visibility Toggle",
                    placeholder: "Enter secure information",
                    text: .constant("ThisIsSecret!"),
                    icon: "lock.shield",
                    isSecure: true,
                    helpText: "Click the eye icon to reveal/hide"
                )
                
                CustomTextField(
                    title: "Number Field",
                    placeholder: "Enter a number",
                    text: .constant("42"),
                    icon: "number",
                    keyboardType: .numberPad,
                    helpText: "Numeric keyboard will appear"
                )
                
                CustomTextField(
                    title: "Search Field",
                    placeholder: "Search...",
                    text: .constant(""),
                    icon: "magnifyingglass",
                    keyboardType: .default,
                    autocapitalization: .none,
                    autocorrection: .no,
                    clearable: true
                )
                
                CustomTextField(
                    title: "",  // No title
                    placeholder: "Minimal field without title",
                    text: .constant(""),
                    clearable: true
                )
            }
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Special Fields")
            
            // Dark Mode
            VStack(spacing: 20) {
                Text("Dark Mode Fields")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.text)
                    .padding(.bottom, 8)
                
                CustomTextField(
                    title: "Text Field",
                    placeholder: "Enter text",
                    text: .constant(""),
                    icon: "text.cursor",
                    helpText: "This is how fields look in dark mode"
                )
                
                CustomTextField(
                    title: "Error State",
                    placeholder: "This input has errors",
                    text: .constant("Dark mode error"),
                    icon: "exclamationmark.triangle",
                    errorMessage: "Error messages are more visible in dark mode"
                )
                
                CustomTextField(
                    title: "Success State",
                    placeholder: "This input is valid",
                    text: .constant("Dark mode success"),
                    icon: "checkmark.seal",
                    successMessage: "Success messages adapt to dark theme"
                )
            }
            .padding()
            .background(DesignSystem.Colors.background)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Dark Mode Fields")
            .preferredColorScheme(.dark)
        }
    }
}