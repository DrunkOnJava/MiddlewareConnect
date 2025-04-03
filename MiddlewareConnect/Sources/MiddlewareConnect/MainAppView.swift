/**
@fileoverview Main application view
@module MainAppView
Created: 2025-03-29
Last Modified: 2025-03-30
Dependencies:
- SwiftUI
Exports:
- MainAppView struct
/

import SwiftUI

/// Main application view that sets up the navigation structure
public struct MainAppView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    @State private var showApiStatusNotification = false
    
    public init() {
        // Default initializer needed for public struct
    }
    
    public var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationTitle("LLM Buddy")
        } detail: {
            ContentView()
        }
        .onAppear {
            // Check if API key is configured
            if !appState.apiSettings.isValid {
                // Show API status notification after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showApiStatusNotification = true
                }
            }
        }
        .overlay(
            Group {
                if showApiStatusNotification && !appState.apiSettings.isValid {
                    VStack {
                        Spacer()
                        
                        ApiStatusNotificationView(isPresented: $showApiStatusNotification)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom)
                    }
                    .animation(.easeInOut, value: showApiStatusNotification)
                }
            }
        )
        .sheet(item: $navCoordinator.activeSheet) { sheet in
            switch sheet {
            case .newConversation:
                Text("New Conversation View")
            case .modelSelection:
                Text("Model Selection View")
            case .settings:
                Text("Settings View")
            case .exportConversation(let id):
                Text("Export Conversation View for \(id)")
            case .importConversation:
                Text("Import Conversation View")
            }
        }
        .fullScreenCover(item: $navCoordinator.activeFullscreenCover) { cover in
            switch cover {
            case .onboarding:
                Text("Onboarding View")
            case .authentication:
                Text("Authentication View")
            case .welcomeTour:
                Text("Welcome Tour View")
            }
        }
        .alert(item: $navCoordinator.activeAlert) { alert in
            switch alert {
            case .error(let message):
                return Alert(
                    title: Text("Error"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            case .confirmation(let message, let action):
                return Alert(
                    title: Text("Confirmation"),
                    message: Text(message),
                    primaryButton: .default(Text("Yes"), action: action),
                    secondaryButton: .cancel(Text("No"))
                )
            case .deleteConfirmation(let message, let action):
                return Alert(
                    title: Text("Delete"),
                    message: Text(message),
                    primaryButton: .destructive(Text("Delete"), action: action),
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
        }
    }
}

// MARK: - Preview
struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
            .environmentObject(AppState())
            .environmentObject(NavigationCoordinator())
    }
}

// MARK: - Supporting Views
struct SidebarView: View {
    var body: some View {
        List {
            NavigationLink(destination: Text("Home")) {
                Label("Home", systemImage: "house.fill")
            }
            
            NavigationLink(destination: Text("Conversations")) {
                Label("Conversations", systemImage: "bubble.left.and.bubble.right.fill")
            }
            
            NavigationLink(destination: Text("Tools")) {
                Label("Tools", systemImage: "wrench.and.screwdriver.fill")
            }
            
            NavigationLink(destination: Text("Settings")) {
                Label("Settings", systemImage: "gear")
            }
        }
        .listStyle(SidebarListStyle())
    }
}

// MARK: - API Status Notification
struct ApiStatusNotificationView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var navCoordinator: NavigationCoordinator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("API Key Required")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Text("Some features require an API key. Please add your API key in settings.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                // Show API settings modal
                navCoordinator.showApiSettings = true
                
                // Dismiss this notification
                withAnimation {
                    isPresented = false
                }
            }) {
                Text("Add API Key")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding()
    }
}
