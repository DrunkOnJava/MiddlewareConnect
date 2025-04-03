/**
@fileoverview Settings View
@module SettingsView
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- SwiftUI
- Combine
Exports:
- SettingsView
Notes:
- Manages application settings and preferences
- Handles API key storage and validation
- Controls model preferences and other settings
/

import SwiftUI
import Combine

/// Settings view for application configuration
struct SettingsView: View {
    // MARK: - Properties
    
    /// Dismiss action
    @Environment(\.presentationMode) var presentationMode
    
    /// API key
    @State private var apiKey = ""
    
    /// Show API key
    @State private var showAPIKey = false
    
    /// Cloud sync enabled
    @State private var cloudSyncEnabled = true
    
    /// Selected model
    @State private var selectedModel = Claude3Model.sonnet
    
    /// Default system prompt
    @State private var systemPrompt = SystemPrompts.assistant
    
    /// Is validating API key
    @State private var isValidating = false
    
    /// API key valid
    @State private var isAPIKeyValid = false
    
    /// API service
    private let anthropicService = AnthropicService()
    
    /// Cloud service
    private let cloudService = CloudStorageManager.shared
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // API key section
                Section(header: Text("API Authentication"),
                        footer: apiKeyFooter) {
                    
                    HStack {
                        if showAPIKey {
                            TextField("Enter your Claude API key", text: $apiKey)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
                            SecureField("Enter your Claude API key", text: $apiKey)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        Button(action: {
                            showAPIKey.toggle()
                        }) {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: validateAPIKey) {
                        if isValidating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Text("Validate API Key")
                        }
                    }
                    .disabled(apiKey.isEmpty || isValidating)
                }
                
                // Model preferences
                Section(header: Text("Model Preferences")) {
                    Picker("Default Model", selection: $selectedModel) {
                        ForEach(Claude3Model.allCases) { model in
                            HStack {
                                Text(model.displayName)
                                Spacer()
                                Text(model.description)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }.tag(model)
                        }
                    }
                    .pickerStyle(NavigationLinkPickerStyle())
                    
                    NavigationLink(destination: SystemPromptEditor(systemPrompt: $systemPrompt)) {
                        VStack(alignment: .leading) {
                            Text("Default System Prompt")
                            Text(systemPrompt.prefix(50) + "...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Sync settings
                Section(header: Text("Synchronization")) {
                    Toggle("iCloud Synchronization", isOn: $cloudSyncEnabled)
                        .onChange(of: cloudSyncEnabled) { newValue in
                            cloudService.useICloud = newValue
                        }
                    
                    if cloudSyncEnabled {
                        Button(action: syncNow) {
                            Text("Sync Now")
                        }
                    }
                }
                
                // Advanced settings
                Section(header: Text("Advanced Settings")) {
                    NavigationLink(destination: AdvancedSettingsView()) {
                        Text("Advanced Settings")
                    }
                    
                    NavigationLink(destination: ContextSettingsView()) {
                        Text("Context Window Management")
                    }
                    
                    Button(action: clearCache) {
                        Text("Clear Cache")
                            .foregroundColor(.red)
                    }
                }
                
                // About section
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    Link(destination: URL(string: "https://www.anthropic.com/claude")!) {
                        HStack {
                            Text("About Claude")
                            Spacer()
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com/username/MiddlewareConnect")!) {
                        HStack {
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "link")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveSettings()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                loadSettings()
            }
        }
    }
    
    /// API key footer view
    private var apiKeyFooter: some View {
        Group {
            if isAPIKeyValid {
                Label("API key validated successfully", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if !apiKey.isEmpty {
                Label("API key not validated", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            } else {
                Text("Enter your API key from Anthropic Console")
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Methods
    
    /// Loads settings
    private func loadSettings() {
        // Load API key
        if let storedAPIKey = KeychainService.shared.retrieveAPIKey(for: .anthropic) {
            apiKey = storedAPIKey
            isAPIKeyValid = true
        }
        
        // Load cloud sync preference
        cloudSyncEnabled = cloudService.useICloud
        
        // Load model preference
        if let modelString = UserDefaults.standard.string(for: .defaultModelKey),
           let model = Claude3Model(rawValue: modelString) {
            selectedModel = model
        }
        
        // Load system prompt
        if let storedPrompt = UserDefaults.standard.string(for: .systemPromptKey) {
            systemPrompt = storedPrompt
        }
    }
    
    /// Saves settings
    private func saveSettings() {
        // Save API key if valid
        if isAPIKeyValid {
            KeychainService.shared.storeAPIKey(apiKey, for: .anthropic)
        }
        
        // Save cloud sync preference
        cloudService.useICloud = cloudSyncEnabled
        
        // Save model preference
        UserDefaults.standard.set(selectedModel.rawValue, for: .defaultModelKey)
        
        // Save system prompt
        UserDefaults.standard.set(systemPrompt, for: .systemPromptKey)
    }
    
    /// Validates the API key
    private func validateAPIKey() {
        guard !apiKey.isEmpty else { return }
        
        isValidating = true
        
        // Store API key temporarily for validation
        KeychainService.shared.storeAPIKey(apiKey, for: .anthropic)
        
        anthropicService.validateAPIKey { result in
            DispatchQueue.main.async {
                isValidating = false
                
                switch result {
                case .success(let isValid):
                    isAPIKeyValid = isValid
                case .failure:
                    isAPIKeyValid = false
                }
            }
        }
    }
    
    /// Syncs data now
    private func syncNow() {
        Task {
            do {
                try await cloudService.synchronize()
            } catch {
                print("Error syncing: \(error.localizedDescription)")
            }
        }
    }
    
    /// Clears the cache
    private func clearCache() {
        // Clear PDF service cache
        PDFService.shared.cleanupTempFiles()
        
        // Clear context window
        LLMServiceProvider.shared.clearContext()
    }
}

/// System prompt editor
struct SystemPromptEditor: View {
    // MARK: - Properties
    
    /// System prompt binding
    @Binding var systemPrompt: String
    
    /// Predefined prompts
    private let predefinedPrompts = [
        ("General Assistant", SystemPrompts.assistant),
        ("Technical Writer", SystemPrompts.technicalWriter),
        ("Creative Writer", SystemPrompts.creativeWriter),
        ("Programmer", SystemPrompts.programmer),
        ("Document Analyzer", SystemPrompts.documentAnalyzer),
        ("Meeting Assistant", SystemPrompts.meetingAssistant)
    ]
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("System prompt defines Claude's behavior. Select a predefined prompt or create your own.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            // Predefined prompts
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(predefinedPrompts, id: \.0) { name, prompt in
                        Button(action: {
                            systemPrompt = prompt
                        }) {
                            Text(name)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    systemPrompt == prompt ?
                                        Color.blue : Color(.systemGray5)
                                )
                                .foregroundColor(
                                    systemPrompt == prompt ?
                                        Color.white : Color.primary
                                )
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Prompt editor
            TextEditor(text: $systemPrompt)
                .font(.body)
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding()
        }
        .navigationTitle("System Prompt")
    }
}

/// Advanced settings view
struct AdvancedSettingsView: View {
    // MARK: - Properties
    
    /// Temperature
    @State private var temperature = 0.7
    
    /// Top P
    @State private var topP = 1.0
    
    /// Max tokens
    @State private var maxTokens = 1000
    
    // MARK: - Body
    
    var body: some View {
        Form {
            Section(header: Text("Generation Parameters"),
                    footer: Text("These parameters control how Claude generates responses.")) {
                
                VStack {
                    HStack {
                        Text("Temperature: \(String(format: "%.1f", temperature))")
                        Spacer()
                    }
                    
                    Slider(value: $temperature, in: 0...1) {
                        Text("Temperature")
                    }
                }
                
                VStack {
                    HStack {
                        Text("Top P: \(String(format: "%.1f", topP))")
                        Spacer()
                    }
                    
                    Slider(value: $topP, in: 0...1) {
                        Text("Top P")
                    }
                }
                
                Stepper("Max Tokens: \(maxTokens)", value: $maxTokens, in: 100...4000, step: 100)
            }
            
            Section(header: Text("Developer Options"),
                    footer: Text("Advanced options for developers.")) {
                
                Toggle("Debug Mode", isOn: .constant(false))
                Toggle("Console Logging", isOn: .constant(false))
                Toggle("Memory Profiling", isOn: .constant(false))
            }
        }
        .navigationTitle("Advanced Settings")
        .onAppear {
            loadSettings()
        }
        .onDisappear {
            saveSettings()
        }
    }
    
    // MARK: - Methods
    
    /// Loads settings
    private func loadSettings() {
        temperature = UserDefaults.standard.double(for: .temperatureKey, defaultValue: 0.7)
        topP = UserDefaults.standard.double(for: .topPKey, defaultValue: 1.0)
        maxTokens = UserDefaults.standard.integer(for: .maxTokensKey, defaultValue: 1000)
    }
    
    /// Saves settings
    private func saveSettings() {
        UserDefaults.standard.set(temperature, for: .temperatureKey)
        UserDefaults.standard.set(topP, for: .topPKey)
        UserDefaults.standard.set(maxTokens, for: .maxTokensKey)
    }
}

/// Context settings view
struct ContextSettingsView: View {
    // MARK: - Properties
    
    /// Reserved tokens
    @State private var reservedTokens = 2000
    
    /// LLM service
    private let llmService = LLMServiceProvider.shared
    
    // MARK: - Body
    
    var body: some View {
        Form {
            Section(header: Text("Context Window Settings"),
                    footer: Text("Control how much of the context window is reserved for system message and model response.")) {
                
                Stepper("Reserved Tokens: \(reservedTokens)", value: $reservedTokens, in: 1000...8000, step: 500)
                    .onChange(of: reservedTokens) { newValue in
                        updateReservedTokens(newValue)
                    }
                
                HStack {
                    Text("Available Context")
                    Spacer()
                    Text("\(llmService.getAvailableContextSize()) tokens")
                }
                
                Button(action: {
                    llmService.clearContext()
                }) {
                    Text("Clear Context Window")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Context Settings")
        .onAppear {
            loadSettings()
        }
    }
    
    // MARK: - Methods
    
    /// Loads context settings
    private func loadSettings() {
        reservedTokens = 2000 // Replace with actual setting retrieval
    }
    
    /// Updates reserved tokens
    private func updateReservedTokens(_ value: Int) {
        // Update the context window reserved tokens
    }
}

// MARK: - Extensions

/// UserDefaults extension for settings
extension UserDefaults {
    /// Keys
    enum Keys {
        static let defaultModelKey = "defaultModel"
        static let systemPromptKey = "systemPrompt"
        static let temperatureKey = "temperature"
        static let topPKey = "topP"
        static let maxTokensKey = "maxTokens"
    }
    
    /// Sets a string value for a key
    /// - Parameters:
    ///   - value: The string value
    ///   - key: The key
    func set(_ value: String, for key: Keys) {
        set(value, forKey: key.rawValue)
    }
    
    /// Gets a string value for a key
    /// - Parameter key: The key
    /// - Returns: The string value
    func string(for key: Keys) -> String? {
        return string(forKey: key.rawValue)
    }
    
    /// Sets a double value for a key
    /// - Parameters:
    ///   - value: The double value
    ///   - key: The key
    func set(_ value: Double, for key: Keys) {
        set(value, forKey: key.rawValue)
    }
    
    /// Gets a double value for a key
    /// - Parameters:
    ///   - key: The key
    ///   - defaultValue: The default value
    /// - Returns: The double value
    func double(for key: Keys, defaultValue: Double = 0) -> Double {
        return double(forKey: key.rawValue)
    }
    
    /// Sets an integer value for a key
    /// - Parameters:
    ///   - value: The integer value
    ///   - key: The key
    func set(_ value: Int, for key: Keys) {
        set(value, forKey: key.rawValue)
    }
    
    /// Gets an integer value for a key
    /// - Parameters:
    ///   - key: The key
    ///   - defaultValue: The default value
    /// - Returns: The integer value
    func integer(for key: Keys, defaultValue: Int = 0) -> Int {
        let value = integer(forKey: key.rawValue)
        return value == 0 ? defaultValue : value
    }
}

/// Make Keys RawRepresentable
extension UserDefaults.Keys: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "defaultModel":
            self = .defaultModelKey
        case "systemPrompt":
            self = .systemPromptKey
        case "temperature":
            self = .temperatureKey
        case "topP":
            self = .topPKey
        case "maxTokens":
            self = .maxTokensKey
        default:
            return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .defaultModelKey:
            return "defaultModel"
        case .systemPromptKey:
            return "systemPrompt"
        case .temperatureKey:
            return "temperature"
        case .topPKey:
            return "topP"
        case .maxTokensKey:
            return "maxTokens"
        }
    }
}

/// Preview provider
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
