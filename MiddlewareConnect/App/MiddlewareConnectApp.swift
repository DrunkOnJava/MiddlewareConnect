/**
 * @fileoverview Main application entry point
 * @module MiddlewareConnectApp
 *
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 *
 * Dependencies:
 * - SwiftUI
 *
 * Exports:
 * - MiddlewareConnectApp
 */

import SwiftUI
import Foundation
import Combine

// Forward declarations of view types
// The actual implementations are in separate files in the Views directory,
// but we need to declare them here so they're in scope for MainContentView

// MARK: - View Type Declarations

struct ConversationsView: View {
    var body: some View {
        Text("ConversationsView")
            .font(.title)
            .padding()
    }
}

struct ToolsView: View {
    var body: some View {
        Text("ToolsView")
            .font(.title)
            .padding()
    }
}

struct AnalysisView: View {
    var body: some View {
        Text("AnalysisView")
            .font(.title)
            .padding()
    }
}

struct SettingsView: View {
    var body: some View {
        Text("SettingsView")
            .font(.title)
            .padding()
    }
}

// MARK: - Models and Support Types

/// LLMModel reference for .claudeSonnet
enum LLMModel: String, Codable {
    case claudeSonnet = "claude_sonnet"
}

/// Message role for chat messages
enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

/// LLMChatMessage structure for chat messages
struct LLMChatMessage: Identifiable, Codable {
    let id: UUID
    var content: String
    let role: MessageRole
    
    static func system(content: String) -> LLMChatMessage {
        LLMChatMessage(id: UUID(), content: content, role: .system)
    }
    
    static func assistant(content: String) -> LLMChatMessage {
        LLMChatMessage(id: UUID(), content: content, role: .assistant)
    }
}

/// ChatConversation structure for storing conversations
struct ChatConversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [LLMChatMessage]
    var model: LLMModel
    var lastUpdated: Date
}

/// AppState class for managing application state
class AppState: ObservableObject {
    @Published var enableHapticFeedback: Bool = true
    @Published var savePromptHistory: Bool = true
    @Published var maxPromptHistoryItems: Int = 100
    @Published var defaultTemperature: Double = 0.7
    @Published var defaultMaxTokens: Int = 2000
    
    func saveSettings() {
        // Placeholder for saving settings
    }
}

/// ChatDataProvider for managing chat data
class ChatDataProvider {
    static let shared = ChatDataProvider()
    
    func saveConversation(_ conversation: ChatConversation) {
        // Placeholder for saving conversation
    }
}

// MARK: - Main Content Views
// Note: The implementation of the view components (ConversationsView, ToolsView, AnalysisView, SettingsView)
// has been moved to separate files in the Views directory

/// MainContentView implementation directly in this file
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
    }
}

// MARK: - Main App Definition

/// Main application entry point
@main
struct MiddlewareConnectApp: App {
    // State objects available throughout the app
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environmentObject(appState)
                .onAppear {
                    // Configure app on first launch
                    checkFirstLaunch()
                }
        }
    }
    
    /// Check if this is the first launch and setup accordingly
    private func checkFirstLaunch() {
        let defaults = UserDefaults.standard
        let hasLaunchedBefore = defaults.bool(forKey: "hasLaunchedBefore")
        
        if !hasLaunchedBefore {
            // First launch setup
            setupFirstLaunch()
            
            // Mark as launched
            defaults.set(true, forKey: "hasLaunchedBefore")
        }
    }
    
    /// Setup actions on first launch
    private func setupFirstLaunch() {
        // Initialize any default settings
        appState.enableHapticFeedback = true
        appState.savePromptHistory = true
        appState.maxPromptHistoryItems = 100
        appState.defaultTemperature = 0.7
        appState.defaultMaxTokens = 2000
        
        // Save settings
        appState.saveSettings()
        
        // Create welcome conversation on first launch
        createWelcomeConversation()
    }
    
    /// Create a welcome conversation with instructions
    private func createWelcomeConversation() {
        // Create messages for the welcome conversation
        var messages: [LLMChatMessage] = []
        
        // System message
        let systemMessage = LLMChatMessage.system(content: "You are Claude, a helpful AI assistant created by Anthropic. You are polite, friendly, and aim to provide informative and thoughtful responses while being honest about limitations.")
        messages.append(systemMessage)
        
        // Welcome message
        let welcomeMessage = LLMChatMessage.assistant(content: """
        # Welcome to MiddlewareConnect!
        
        I'm Claude, your AI assistant. This app provides powerful tools to help you work with large language models effectively.
        
        ## Getting Started
        
        1. **Add your API key** in Settings to access Claude's capabilities
        2. **Try a conversation** by typing a message below
        3. **Explore the Tools tab** for document processing features
        4. **Check the Analysis tab** for token usage and cost optimization
        
        What would you like to do first?
        """)
        messages.append(welcomeMessage)
        
        // Create and save the conversation
        let conversation = ChatConversation(
            id: UUID(),
            title: "Welcome to MiddlewareConnect",
            messages: messages,
            model: .claudeSonnet,
            lastUpdated: Date()
        )
        
        ChatDataProvider.shared.saveConversation(conversation)
    }
}
