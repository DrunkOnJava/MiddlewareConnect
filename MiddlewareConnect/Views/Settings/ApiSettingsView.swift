import SwiftUI

/**
 * API Settings view
 * Allows users to configure their API keys for different LLM providers
 */
struct ApiSettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var apiKey: String = ""
    @State private var isValidating: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var showSuccessMessage: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("API Key", text: $apiKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.password)
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(appState.apiSettings.isValid ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(appState.apiSettings.isValid ? "Valid" : "Not Configured")
                                .foregroundColor(appState.apiSettings.isValid ? .secondary : .red)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("API Key")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your API key is stored securely on your device and never sent to our servers.")
                        
                        if let provider = appState.selectedModel.provider {
                            switch provider {
                            case .anthropic:
                                Text("Get an API key at [anthropic.com](https://www.anthropic.com/)")
                            case .openai:
                                Text("Get an API key at [openai.com](https://platform.openai.com/)")
                            case .mistral:
                                Text("Get an API key at [mistral.ai](https://mistral.ai/)")
                            default:
                                EmptyView()
                            }
                        }
                    }
                }
                
                if appState.apiSettings.isValid {
                    Section {
                        HStack {
                            Text("Total API Requests")
                            Spacer()
                            Text("\(appState.apiSettings.usageStats.totalRequests)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Remaining Credits")
                            Spacer()
                            Text("\(appState.apiSettings.usageStats.remainingCredits)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(appState.apiSettings.usageStats.formattedLastUpdated)
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Usage Statistics")
                    } footer: {
                        Text("Usage statistics are updated approximately every 24 hours.")
                    }
                }
                
                Section {
                    Button(action: saveApiKey) {
                        if isValidating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save API Key")
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(apiKey.isEmpty || isValidating)
                    
                    if appState.apiSettings.isValid {
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Text("Delete API Key")
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("API Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                apiKey = appState.apiSettings.apiKey
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete API Key"),
                    message: Text("Are you sure you want to delete your API key? This will disable all API-dependent features."),
                    primaryButton: .destructive(Text("Delete")) {
                        appState.deleteApiKey()
                        apiKey = ""
                    },
                    secondaryButton: .cancel()
                )
            }
            .overlay {
                if showSuccessMessage {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("API Key Saved Successfully")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 3)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showSuccessMessage = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveApiKey() {
        guard !apiKey.isEmpty else { return }
        
        isValidating = true
        
        // Save the key first
        appState.saveApiKey(apiKey)
        
        // Display success message
        withAnimation {
            showSuccessMessage = true
        }
        
        // Give a short delay to show validation is happening
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isValidating = false
            dismiss()
        }
    }
}
