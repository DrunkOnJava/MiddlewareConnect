/**
@fileoverview Main Tab Navigation
@module MainTabView
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- SwiftUI
Exports:
- MainTabView
Notes:
- Primary navigation structure for the application
- Manages transitions between major functional areas
/

import SwiftUI

/// Main tab navigation view for the application
struct MainTabView: View {
    // MARK: - Properties
    
    /// Selected tab
    @State private var selectedTab = 0
    
    /// API service
    @ObservedObject private var llmService = LLMServiceProvider.shared
    
    /// Show settings
    @State private var showingSettings = false
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Chat tab
            NavigationView {
                ConversationsView()
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(0)
            
            // Documents tab
            NavigationView {
                DocumentAnalysisView()
            }
            .tabItem {
                Label("Documents", systemImage: "doc.text.magnifyingglass")
            }
            .tag(1)
            
            // Tools tab
            NavigationView {
                ToolsView()
            }
            .tabItem {
                Label("Tools", systemImage: "hammer")
            }
            .tag(2)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            validateAPIKey()
        }
        .overlay(
            Group {
                if !hasValidAPIKey {
                    APIKeyPromptView {
                        validateAPIKey()
                    }
                    .transition(.opacity)
                }
            }
        )
    }
    
    // MARK: - Methods
    
    /// Check if there's a valid API key
    @State private var hasValidAPIKey = false
    @State private var isValidating = false
    
    /// Validates the API key
    private func validateAPIKey() {
        guard !isValidating else { return }
        
        isValidating = true
        
        llmService.validateAPIKey { result in
            isValidating = false
            
            DispatchQueue.main.async {
                switch result {
                case .success(let isValid):
                    self.hasValidAPIKey = isValid
                    
                    if !isValid {
                        showingSettings = true
                    }
                case .failure:
                    self.hasValidAPIKey = false
                    showingSettings = true
                }
            }
        }
    }
}

/// API key prompt view
struct APIKeyPromptView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Content
            VStack(spacing: 20) {
                Image(systemName: "key.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)
                
                Text("API Key Required")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("To use MiddlewareConnect, you need to add your Claude API key in Settings.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: onContinue) {
                    Text("Add API Key")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
            .frame(width: 300)
            .shadow(radius: 10)
        }
    }
}

/// Preview provider
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
