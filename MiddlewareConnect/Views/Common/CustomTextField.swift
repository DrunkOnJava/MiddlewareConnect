import SwiftUI

/// A custom text field component that follows the app's design system
struct CustomTextField: View {
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
    
    let title: String
    let placeholder: String
    let icon: String?
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let autocapitalization: UITextAutocapitalizationType
    let autocorrection: UITextAutocorrectionType
    let helpText: String?
    let errorMessage: String?
    let successMessage: String?
    let fieldState: FieldState
    let clearable: Bool
    
    @Binding var text: String
    @State private var isFocused: Bool = false
    @State private var isTextVisible: Bool = false
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        icon: String? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: UITextAutocapitalizationType = .sentences,
        autocorrection: UITextAutocorrectionType = .default,
        helpText: String? = nil,
        errorMessage: String? = nil,
        successMessage: String? = nil,
        fieldState: FieldState = .normal,
        clearable: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.autocapitalization = autocapitalization
        self.autocorrection = autocorrection
        self.helpText = helpText
        self.errorMessage = errorMessage
        self.successMessage = successMessage
        self.fieldState = fieldState
        self.clearable = clearable
        self._isTextVisible = State(initialValue: !isSecure)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
            // Title
            if !title.isEmpty {
                Text(title)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .animation(nil, value: text) // Prevent title from animating
            }
            
            // Text Field
            ZStack(alignment: .leading) {
                textFieldBackground
                
                HStack(spacing: DesignSystem.Spacing.small) {
                    // Leading icon
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(iconColor)
                            .frame(width: 20)
                    }
                    
                    // TextField or SecureField
                    ZStack(alignment: .leading) {
                        if isSecure && !isTextVisible {
                            SecureField("", text: $text)
                                .placeholder(when: text.isEmpty) {
                                    Text(placeholder)
                                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                                }
                                .keyboardType(keyboardType)
                                .autocapitalization(autocapitalization)
                                .disableAutocorrection(autocorrection == .no)
                                .onTapGesture {
                                    withAnimation {
                                        isFocused = true
                                    }
                                }
                        } else {
                            TextField("", text: $text)
                                .placeholder(when: text.isEmpty) {
                                    Text(placeholder)
                                        .foregroundColor(DesignSystem.Colors.tertiaryText)
                                }
                                .keyboardType(keyboardType)
                                .autocapitalization(autocapitalization)
                                .disableAutocorrection(autocorrection == .no)
                                .onTapGesture {
                                    withAnimation {
                                        isFocused = true
                                    }
                                }
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    // State icon (success/error)
                    if let stateIcon = currentFieldState.icon {
                        Image(systemName: stateIcon)
                            .foregroundColor(currentFieldState.color)
                            .transition(.opacity)
                    }
                    
                    // Clear button
                    if clearable && !text.isEmpty {
                        Button(action: {
                            withAnimation {
                                text = ""
                                DesignSystem.hapticFeedback(.light)
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                        .transition(.opacity)
                    }
                    
                    // Toggle secure entry
                    if isSecure {
                        Button(action: {
                            withAnimation {
                                isTextVisible.toggle()
                                DesignSystem.hapticFeedback(.light)
                            }
                        }) {
                            Image(systemName: isTextVisible ? "eye.slash" : "eye")
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.medium)
            }
            .background(DesignSystem.Colors.secondaryBackground)
            .cornerRadius(DesignSystem.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(currentFieldState.color, lineWidth: borderWidth)
            )
            .animation(.easeInOut(duration: 0.2), value: text)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .onAppear {
                // Set initial state
                if !isSecure {
                    isTextVisible = true
                }
            }
            .onChange(of: text) { _ in
                if !isFocused {
                    withAnimation {
                        isFocused = true
                    }
                }
            }
            
            // Helper/Error/Success Message
            if let message = currentMessage {
                Text(message)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(messageColor)
                    .padding(.horizontal, DesignSystem.Spacing.small)
                    .animation(.easeInOut(duration: 0.2), value: currentMessage)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentFieldState: FieldState {
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
    
    private var currentMessage: String? {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            return errorMessage
        } else if let successMessage = successMessage, !successMessage.isEmpty {
            return successMessage
        } else if let helpText = helpText, !helpText.isEmpty {
            return helpText
        }
        return nil
    }
    
    private var messageColor: Color {
        if errorMessage != nil && !errorMessage!.isEmpty {
            return DesignSystem.Colors.error
        } else if successMessage != nil && !successMessage!.isEmpty {
            return DesignSystem.Colors.success
        } else {
            return DesignSystem.Colors.tertiaryText
        }
    }
    
    private var iconColor: Color {
        if isFocused {
            return DesignSystem.Colors.primary
        } else {
            return DesignSystem.Colors.secondaryText
        }
    }
    
    private var borderWidth: CGFloat {
        if currentFieldState == .focused || 
           currentFieldState == .error || 
           currentFieldState == .success {
            return 2
        } else {
            return 1
        }
    }
    
    private var textFieldBackground: some View {
        DesignSystem.Colors.secondaryBackground
            .cornerRadius(DesignSystem.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(currentFieldState.color, lineWidth: borderWidth)
            )
    }
}

// MARK: - Helper Extensions

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

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
