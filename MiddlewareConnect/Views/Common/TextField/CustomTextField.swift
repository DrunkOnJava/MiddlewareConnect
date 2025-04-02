import SwiftUI

/// A custom text field component that follows the app's design system
struct CustomTextField: View {
    // MARK: - Properties
    
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
    @State var isFocused: Bool = false
    @State var isTextVisible: Bool = false
    
    // MARK: - Initialization
    
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
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
            // Title
            titleView()
            
            // Text Field
            ZStack(alignment: .leading) {
                textFieldBackground()
                
                HStack(spacing: DesignSystem.Spacing.small) {
                    // Leading icon
                    leadingIconView()
                    
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
                    stateIconView()
                    
                    // Clear button
                    clearButton()
                    
                    // Toggle secure entry
                    securityToggleButton()
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
            messageView()
        }
    }
}