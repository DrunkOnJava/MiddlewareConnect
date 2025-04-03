import SwiftUI

/// View for managing LLM model settings
struct ModelSettingsView: View {
    // MARK: - Properties
    
    @EnvironmentObject var appState: AppState
    @Environment(\\.dismiss) var dismiss
    
    /// The selected model
    @State private var selectedModel: LLMModel = .claudeSonnet
    
    /// Whether to show the success message
    @State private var showingSuccessMessage = false
    
    /// The success message
    @State private var successMessage = ""
    
    // MARK: - Initialization
    
    init() {
        // Initialize from UserDefaults for preview support
        // The actual value will be updated in onAppear from appState
        if let savedModelString = UserDefaults.standard.string(forKey: "selected_model"),
           let savedModel = LLMModel(rawValue: savedModelString) {
            _selectedModel = State(initialValue: savedModel)
        } else {
            // Default to Claude Sonnet if no saved value
            _selectedModel = State(initialValue: .claudeSonnet)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Form {
            Section(header: Text("LLM Model Selection")) {
                Picker("Select Model", selection: $selectedModel) {
                    ForEach(LLMModel.allCases, id: \.self) { model in
                        Text(model.displayName)
                            .tag(model)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                .onChange(of: selectedModel) { newValue in
                    saveModelSelection(model: newValue)
                }
                
                HStack {
                    Text("Provider")
                    Spacer()
                    Text(selectedModel.provider.rawValue.capitalized)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("API Key Management")) {
                NavigationLink(destination: Text("API Key management will be implemented here")) {
                    Text("Manage API Keys")
                }
            }
            
            Section(header: Text("About Models")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Claude 3.7 Sonnet")
                        .font(.headline)
                    Text("Anthropic's Claude 3.7 Sonnet model offers a great balance of intelligence and speed. Perfect for document summarization and analysis.")
                        .font(.footnote)
                    
                    Divider()
                    
                    Text("ChatGPT-4o")
                        .font(.headline)
                    Text("OpenAI's GPT-4o model with multimodal capabilities. Excellent for tasks requiring complex reasoning and image analysis.")
                        .font(.footnote)
                    
                    Divider()
                    
                    Text("Gemini 2.0")
                        .font(.headline)
                    Text("Google's most advanced multimodal AI model. Designed for complex reasoning tasks across text, images, audio, and more.")
                        .font(.footnote)
                }
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Model Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            // Update the selected model from AppState
            selectedModel = appState.selectedModel
        }
        .overlay(
            successOverlay
        )
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        Group {
            if showingSuccessMessage {
                VStack {
                    Spacer()
                    
                    Text(successMessage)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                    
                    Spacer()
                        .frame(height: 100)
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: showingSuccessMessage)
                .onAppear {
                    // Hide the success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showingSuccessMessage = false
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Save the model selection
    /// - Parameter model: The selected model
    private func saveModelSelection(model: LLMModel) {
        // Save the model selection to UserDefaults
        UserDefaults.standard.set(model.rawValue, forKey: "selected_model")
        
        // Update the AppState
        appState.selectedModel = model
        
        // Show a success message
        showSuccess(message: "Model changed to \(model.displayName)")
    }
    
    /// Show a success message
    /// - Parameter message: The message to show
    private func showSuccess(message: String) {
        successMessage = message
        withAnimation {
            showingSuccessMessage = true
        }
    }
}