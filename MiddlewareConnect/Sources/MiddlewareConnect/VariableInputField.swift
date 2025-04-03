import SwiftUI
import Combine

/// A specialized input component for prompt template variables with validation and type inference
///
/// Designed to provide a robust interface for variable entry and validation,
/// supporting different data types and validation rules.
public struct VariableInputField: View {
    /// Represents the core data and validation model for a variable input
    public struct ViewModel: Identifiable {
        /// Unique identifier for the variable
        public let id: UUID
        
        /// Name of the variable
        public let name: String
        
        /// Description of the variable's purpose
        public let description: String
        
        /// Expected data type for the variable
        public let dataType: VariableType
        
        /// Current input value
        @Published public var value: String
        
        /// Default value for the variable
        public let defaultValue: String
        
        /// Validation requirements for the input
        public let validationRules: [ValidationRule]
        
        /// Whether the variable is required
        public let isRequired: Bool
        
        /// Creates a new variable input view model
        /// - Parameters:
        ///   - name: Name of the variable
        ///   - description: Brief explanation of the variable's purpose
        ///   - dataType: Expected data type
        ///   - defaultValue: Starting value for the input
        ///   - validationRules: Optional rules for validation
        ///   - isRequired: Whether a value must be provided
        public init(
            name: String,
            description: String,
            dataType: VariableType,
            defaultValue: String = "",
            validationRules: [ValidationRule] = [],
            isRequired: Bool = true
        ) {
            self.id = UUID()
            self.name = name
            self.description = description
            self.dataType = dataType
            self.value = defaultValue
            self.defaultValue = defaultValue
            self.validationRules = validationRules
            self.isRequired = isRequired
        }
        
        /// Validates the current input value against the rules
        /// - Returns: ValidationResult with status and errors
        public func validate() -> ValidationResult {
            // Check required fields
            if isRequired && value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return ValidationResult(isValid: false, errors: ["Value is required"])
            }
            
            // Type validation
            if !dataType.validate(value) {
                return ValidationResult(isValid: false, errors: ["Invalid \(dataType.description)"])
            }
            
            // Custom validation rules
            var errors: [String] = []
            
            for rule in validationRules {
                if !rule.validate(value) {
                    errors.append(rule.errorMessage)
                }
            }
            
            return ValidationResult(isValid: errors.isEmpty, errors: errors)
        }
    }
    
    /// Types of variables that can be entered
    public enum VariableType: Equatable, Codable {
        /// Plain text input
        case text
        
        /// Numeric input
        case number
        
        /// Boolean true/false
        case boolean
        
        /// Date value
        case date
        
        /// JSON formatted data
        case json
        
        /// Custom type with specific validation
        case custom(String)
        
        /// Human-readable description of the type
        public var description: String {
            switch self {
            case .text: return "Text"
            case .number: return "Number"
            case .boolean: return "Boolean"
            case .date: return "Date"
            case .json: return "JSON"
            case .custom(let name): return name
            }
        }
        
        /// Validates if a string matches the expected type
        /// - Parameter value: String value to validate
        /// - Returns: Boolean indicating if valid
        public func validate(_ value: String) -> Bool {
            switch self {
            case .text:
                return true
            case .number:
                return Double(value) != nil
            case .boolean:
                let lowercased = value.lowercased()
                return lowercased == "true" || lowercased == "false" || lowercased == "yes" || lowercased == "no" || lowercased == "1" || lowercased == "0"
            case .date:
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter.date(from: value) != nil
            case .json:
                guard let data = value.data(using: .utf8) else { return false }
                do {
                    _ = try JSONSerialization.jsonObject(with: data, options: [])
                    return true
                } catch {
                    return false
                }
            case .custom:
                // Custom validation would be implemented by the consumer
                return true
            }
        }
    }
    
    /// Rule for validating variable input
    public struct ValidationRule: Equatable, Codable {
        /// Name of the rule
        public let name: String
        
        /// Error message when validation fails
        public let errorMessage: String
        
        /// Validation logic
        private let validationClosure: (String) -> Bool
        
        /// Creates a new validation rule
        /// - Parameters:
        ///   - name: Identifying name for the rule
        ///   - errorMessage: Message to display on failure
        ///   - validation: Closure performing the validation
        public init(name: String, errorMessage: String, validation: @escaping (String) -> Bool) {
            self.name = name
            self.errorMessage = errorMessage
            self.validationClosure = validation
        }
        
        /// Validates the input string
        /// - Parameter value: String to validate
        /// - Returns: Boolean indicating if valid
        public func validate(_ value: String) -> Bool {
            return validationClosure(value)
        }
        
        // MARK: - Common Validation Rules
        
        /// Rule for minimum text length
        /// - Parameters:
        ///   - length: Minimum character count
        /// - Returns: ValidationRule
        public static func minLength(_ length: Int) -> ValidationRule {
            ValidationRule(
                name: "minLength",
                errorMessage: "Minimum length of \(length) characters required",
                validation: { $0.count >= length }
            )
        }
        
        /// Rule for maximum text length
        /// - Parameters:
        ///   - length: Maximum character count
        /// - Returns: ValidationRule
        public static func maxLength(_ length: Int) -> ValidationRule {
            ValidationRule(
                name: "maxLength",
                errorMessage: "Maximum length of \(length) characters exceeded",
                validation: { $0.count <= length }
            )
        }
        
        /// Rule for regex pattern matching
        /// - Parameters:
        ///   - pattern: Regular expression pattern
        ///   - message: Custom error message
        /// - Returns: ValidationRule
        public static func regex(pattern: String, message: String) -> ValidationRule {
            ValidationRule(
                name: "regex",
                errorMessage: message,
                validation: {
                    guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
                    let range = NSRange(location: 0, length: $0.utf16.count)
                    return regex.firstMatch(in: $0, options: [], range: range) != nil
                }
            )
        }
        
        /// Rule for minimum numeric value
        /// - Parameters:
        ///   - min: Minimum value
        /// - Returns: ValidationRule
        public static func minValue(_ min: Double) -> ValidationRule {
            ValidationRule(
                name: "minValue",
                errorMessage: "Value must be at least \(min)",
                validation: {
                    guard let value = Double($0) else { return false }
                    return value >= min
                }
            )
        }
        
        /// Rule for maximum numeric value
        /// - Parameters:
        ///   - max: Maximum value
        /// - Returns: ValidationRule
        public static func maxValue(_ max: Double) -> ValidationRule {
            ValidationRule(
                name: "maxValue",
                errorMessage: "Value must be at most \(max)",
                validation: {
                    guard let value = Double($0) else { return false }
                    return value <= max
                }
            )
        }
        
        // MARK: - Equatable
        
        public static func == (lhs: ValidationRule, rhs: ValidationRule) -> Bool {
            return lhs.name == rhs.name && lhs.errorMessage == rhs.errorMessage
        }
        
        // MARK: - Codable
        
        public enum CodingKeys: String, CodingKey {
            case name, errorMessage
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decode(String.self, forKey: .name)
            errorMessage = try container.decode(String.self, forKey: .errorMessage)
            
            // Default implementation for decoded rules
            validationClosure = { _ in true }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(errorMessage, forKey: .errorMessage)
        }
    }
    
    /// Result of a validation operation
    public struct ValidationResult {
        /// Whether the validation passed
        public let isValid: Bool
        
        /// List of error messages if validation failed
        public let errors: [String]
    }
    
    // MARK: - View Properties
    
    /// View model for the variable
    @ObservedObject private var viewModel: ObservableViewModel
    
    /// Visual configuration for the input field
    private let configuration: InputConfiguration
    
    /// Validation publisher for reactive validation
    @State private var validationResult: ValidationResult?
    
    /// Visual configuration settings
    public struct InputConfiguration {
        /// Color scheme for the component
        let colorScheme: ColorScheme
        
        /// Typography settings
        let typography: Typography
        
        /// Placeholder text when empty
        let placeholder: String
        
        /// Creates a default configuration
        public static let `default` = InputConfiguration(
            colorScheme: .init(primary: .blue, secondary: .gray, error: .red),
            typography: .init(labelFont: .headline, inputFont: .body, errorFont: .caption),
            placeholder: "Enter value..."
        )
    }
    
    /// Color configuration for component appearance
    public struct ColorScheme {
        /// Primary accent color
        let primary: Color
        
        /// Secondary, supporting color
        let secondary: Color
        
        /// Error indicator color
        let error: Color
        
        /// Creates a new color scheme
        public init(primary: Color, secondary: Color, error: Color) {
            self.primary = primary
            self.secondary = secondary
            self.error = error
        }
    }
    
    /// Typography configuration
    public struct Typography {
        /// Font for labels
        let labelFont: Font
        
        /// Font for input text
        let inputFont: Font
        
        /// Font for error messages
        let errorFont: Font
        
        /// Creates a new typography configuration
        public init(labelFont: Font, inputFont: Font, errorFont: Font) {
            self.labelFont = labelFont
            self.inputFont = inputFont
            self.errorFont = errorFont
        }
    }
    
    /// Observable wrapper for the view model
    private class ObservableViewModel: ObservableObject {
        /// Underlying variable view model
        private let variableViewModel: ViewModel
        
        /// Publisher for the input value
        @Published var value: String {
            didSet {
                variableViewModel.value = value
            }
        }
        
        /// Initializes with a variable view model
        init(variableViewModel: ViewModel) {
            self.variableViewModel = variableViewModel
            self.value = variableViewModel.value
        }
        
        /// Validates the current input
        func validate() -> ValidationResult {
            return variableViewModel.validate()
        }
        
        /// Accessor for the variable view model
        var model: ViewModel {
            return variableViewModel
        }
    }
    
    /// Initializes a new variable input field
    /// - Parameters:
    ///   - viewModel: Data model for the variable
    ///   - configuration: Visual configuration
    public init(
        viewModel: ViewModel,
        configuration: InputConfiguration = .default
    ) {
        self._viewModel = ObservedObject(wrappedValue: ObservableViewModel(variableViewModel: viewModel))
        self.configuration = configuration
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            HStack {
                Text(viewModel.model.name)
                    .font(configuration.typography.labelFont)
                    .foregroundColor(configuration.colorScheme.primary)
                
                if viewModel.model.isRequired {
                    Text("*")
                        .font(configuration.typography.labelFont)
                        .foregroundColor(configuration.colorScheme.error)
                }
                
                Spacer()
                
                // Type indicator
                Text(viewModel.model.dataType.description)
                    .font(.caption)
                    .foregroundColor(configuration.colorScheme.secondary)
                    .padding(4)
                    .background(configuration.colorScheme.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Description
            if !viewModel.model.description.isEmpty {
                Text(viewModel.model.description)
                    .font(.caption)
                    .foregroundColor(configuration.colorScheme.secondary)
            }
            
            // Input field
            inputField()
            
            // Validation errors
            if let result = validationResult, !result.isValid {
                ForEach(result.errors, id: \.self) { error in
                    Text(error)
                        .font(configuration.typography.errorFont)
                        .foregroundColor(configuration.colorScheme.error)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 1)
        .onChange(of: viewModel.value) { _ in
            validateInput()
        }
        .onAppear {
            validateInput()
        }
    }
    
    /// Creates the appropriate input field based on type
    @ViewBuilder
    private func inputField() -> some View {
        switch viewModel.model.dataType {
        case .text, .json, .custom:
            if viewModel.model.validationRules.contains(where: { $0.name == "maxLength" && Int($0.errorMessage.components(separatedBy: " ")[3]) ?? 0 > 100 }) {
                // Multi-line for longer text
                TextEditor(text: $viewModel.value)
                    .font(configuration.typography.inputFont)
                    .frame(minHeight: 100)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(borderColor(), lineWidth: 1)
                    )
            } else {
                // Single line for shorter text
                TextField(configuration.placeholder, text: $viewModel.value)
                    .font(configuration.typography.inputFont)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(borderColor(), lineWidth: 1)
                    )
            }
            
        case .number:
            TextField(configuration.placeholder, text: $viewModel.value)
                .font(configuration.typography.inputFont)
                .keyboardType(.decimalPad)
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(borderColor(), lineWidth: 1)
                )
            
        case .boolean:
            Toggle(isOn: Binding(
                get: { viewModel.value.lowercased() == "true" || viewModel.value.lowercased() == "yes" || viewModel.value == "1" },
                set: { viewModel.value = $0 ? "true" : "false" }
            )) {
                Text("Enabled")
                    .font(configuration.typography.inputFont)
            }
            .padding(8)
            
        case .date:
            DatePicker(
                configuration.placeholder,
                selection: Binding(
                    get: {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        return formatter.date(from: viewModel.value) ?? Date()
                    },
                    set: {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        viewModel.value = formatter.string(from: $0)
                    }
                ),
                displayedComponents: .date
            )
            .font(configuration.typography.inputFont)
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(borderColor(), lineWidth: 1)
            )
        }
    }
    
    /// Performs validation and updates the result
    private func validateInput() {
        validationResult = viewModel.validate()
    }
    
    /// Determines the border color based on validation state
    private func borderColor() -> Color {
        if let result = validationResult {
            return result.isValid ? configuration.colorScheme.primary : configuration.colorScheme.error
        }
        return configuration.colorScheme.secondary
    }
}

// MARK: - Preview Support
#if DEBUG
struct VariableInputField_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Text variable
            VariableInputField(
                viewModel: .init(
                    name: "Document Title",
                    description: "Enter the title of the document",
                    dataType: .text,
                    validationRules: [.minLength(3), .maxLength(50)]
                )
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Text Variable")
            
            // Number variable
            VariableInputField(
                viewModel: .init(
                    name: "Temperature",
                    description: "Controls randomness (0.0 to 1.0)",
                    dataType: .number,
                    defaultValue: "0.7",
                    validationRules: [.minValue(0), .maxValue(1)]
                )
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Number Variable")
            
            // Boolean variable
            VariableInputField(
                viewModel: .init(
                    name: "Advanced Mode",
                    description: "Enable advanced processing options",
                    dataType: .boolean,
                    defaultValue: "false"
                )
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Boolean Variable")
        }
    }
}
#endif
