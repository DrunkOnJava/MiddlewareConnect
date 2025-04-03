/**
 * @fileoverview Main content view for the app
 * @module MainContentView
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - MainContentView
 */

import SwiftUI

/// Main content view containing the tab navigation
struct MainContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Chats tab
            ConversationsView()
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(0)
            
            // Tools tab
            ToolsView()
                .tabItem {
                    Label("Tools", systemImage: "hammer")
                }
                .tag(1)
            
            // Analysis tab
            AnalysisView()
                .tabItem {
                    Label("Analysis", systemImage: "chart.bar")
                }
                .tag(2)
            
            // Settings tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .onAppear {
            // Configure appearance
            UITabBar.appearance().backgroundColor = UIColor.systemBackground
        }
    }
}

// Preview
struct MainContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainContentView()
            .environmentObject(AppState())
    }
}

// Placeholder views for tabs
struct ConversationsView: View {
    var body: some View {
        NavigationView {
            Text("Conversations View")
                .navigationTitle("Chats")
        }
    }
}

struct ToolsView: View {
    var body: some View {
        NavigationView {
            Text("Tools View")
                .navigationTitle("Tools")
        }
    }
}

struct AnalysisView: View {
    var body: some View {
        NavigationView {
            Text("Analysis View")
                .navigationTitle("Analysis")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Text("Settings View")
                .navigationTitle("Settings")
        }
    }
}
