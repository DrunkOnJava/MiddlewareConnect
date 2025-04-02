            Form {
                Section(header: Text("Feedback Type")) {
                    Picker("Type", selection: $feedbackType) {
                        Text("Feature Request").tag(0)
                        Text("Bug Report").tag(1)
                        Text("General Feedback").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Details")) {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 150)
                    
                    Toggle("Include Device Information", isOn: $includeDeviceInfo)
                }
                
                Section {
                    Button(action: {
                        // Simulate sending feedback
                        showConfirmation = true
                    }) {
                        Text("Submit Feedback")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showConfirmation) {
                Alert(
                    title: Text("Thank You"),
                    message: Text("Your feedback has been submitted. We appreciate your input!"),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
        }
    }
}

/// Privacy policy modal
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Privacy Policy")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Last Updated: March 27, 2025")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Introduction")
                            .font(.headline)
                        
                        Text("This Privacy Policy explains how LLM Buddy collects, uses, and discloses your information when you use our mobile application.")
                            .font(.body)
                        
                        Text("Information Collection")
                            .font(.headline)
                        
                        Text("We do not collect any personal information without your explicit consent. Your API keys are stored securely on your device and are never sent to our servers.")
                            .font(.body)
                        
                        Text("Data Usage")
                            .font(.headline)
                        
                        Text("Any data you process through the app remains on your device unless you explicitly use API features that require sending data to third-party services like OpenAI or Anthropic.")
                            .font(.body)
                    }
                    
                    Group {
                        Text("Changes to This Policy")
                            .font(.headline)
                        
                        Text("We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.")
                            .font(.body)
                        
                        Text("Contact Us")
                            .font(.headline)
                        
                        Text("If you have any questions about this Privacy Policy, please contact us at privacy@llmbuddy.app")
                            .font(.body)
                    }
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Status Notifications

/// API status notification view
struct ApiStatusNotificationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    Text("API Key Required")
                        .font(DesignSystem.Typography.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
                
                Text("Some features require an API key to function. Please add your API key in settings.")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Button(action: {
                    // Show API settings modal
                    navCoordinator.showApiSettings = true
                    
                    // Dismiss this notification
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Text("Add API Key")
                        .font(DesignSystem.Typography.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(DesignSystem.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
            .padding()
            .background(DesignSystem.Colors.background)
            .cornerRadius(16)
            .shadow(
                color: DesignSystem.Shadows.medium.color,
                radius: DesignSystem.Shadows.medium.radius,
                x: DesignSystem.Shadows.medium.x,
                y: DesignSystem.Shadows.medium.y
            )
            .padding()
        }
    }
}
