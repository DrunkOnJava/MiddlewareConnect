/**
 * @fileoverview Sidebar navigation view
 * @module SidebarView
 * 
 * Created: 2025-03-29
 * Last Modified: 2025-03-29
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - SidebarView struct
 */

import SwiftUI
import Combine

// Define Conversation model to resolve references
public class Conversation: Identifiable, ObservableObject {
    public let id: UUID
    @Published public var title: String
    @Published public var model: LLMModel
    @Published public var messages: [Message] = []
    public let createdAt: Date
    @Published public var lastUpdatedAt: Date
    @Published public var isPinned: Bool = false
    
    public init(
        id: UUID = UUID(),
        title: String = "New Chat",
        model: LLMModel = LLMModel.defaultModels[0],
        messages: [Message] = [],
        createdAt: Date = Date(),
        lastUpdatedAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.model = model
        self.messages = messages
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
        self.isPinned = isPinned
    }
}

// Define Message model to support Conversation
public struct Message: Identifiable {
    public let id: UUID
    public let content: String
    public let isUser: Bool
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

/// Sidebar navigation view for the main app
struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @State private var showNewChatSheet = false
    @State private var newChatTitle = ""
    
    var body: some View {
        List {
            // New chat button
            Button(action: {
                showNewChatSheet = true
            }) {
                Label("New Chat", systemImage: "plus.circle")
            }
            .padding(.vertical, 4)
            .sheet(isPresented: $showNewChatSheet) {
                NewChatView(isPresented: $showNewChatSheet)
            }
            
            // Chat section
            Section("Chats") {
                if appState.conversations.isEmpty {
                    Text("No conversations yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(appState.conversations) { conversation in
                        ConversationRowView(conversation: conversation)
                    }
                    .onDelete(perform: deleteConversations)
                }
            }
            
            // API Features section
            Section("API Features") {
                if appState.apiSettings.isValid {
                    let toggles = appState.apiSettings.featureToggles
                    
                    if toggles.enableVision {
                        NavigationLink(destination: Text("OCR Transcription View")) {
                            Label("OCR Transcription", systemImage: "text.viewfinder")
                        }
                    }
                    
                    if toggles.enableTools {
                        NavigationLink(destination: Text("Document Summarization View")) {
                            Label("Summarize Document", systemImage: "doc.text.magnifyingglass")
                        }
                    }
                    
                    if toggles.enableFunctionCalling {
                        NavigationLink(destination: Text("Markdown Converter View")) {
                            Label("Markdown Converter", systemImage: "arrow.2.squarepath")
                        }
                    }
                } else {
                    NavigationLink(destination: Text("API Settings View")) {
                        Label("Configure API", systemImage: "key")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Tools section
            Section("Tools") {
                NavigationLink(destination: Text("Text Chunker View")) {
                    Label("Text Chunker", systemImage: "scissors")
                }
                
                NavigationLink(destination: Text("PDF Combiner View")) {
                    Label("PDF Combiner", systemImage: "doc.on.doc")
                }
                
                NavigationLink(destination: Text("Token Counter View")) {
                    Label("Token Counter", systemImage: "number.circle")
                }
            }
        }
        .listStyle(SidebarListStyle())
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Spacer()
            }
            ToolbarItem(placement: .bottomBar) {
                Button(action: {
                    appState.showSettings.toggle()
                }) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
    }
    
    /// Delete conversations at specified offsets
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = appState.conversations[index]
            appState.deleteConversation(conversation)
        }
    }
}

/// New chat creation view
struct NewChatView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @State private var chatTitle = "New Chat"
    @State private var selectedModel: LLMModel?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chat Details")) {
                    TextField("Chat Title", text: $chatTitle)
                    
                    Picker("Model", selection: $selectedModel) {
                        ForEach(LLMModel.defaultModels) { model in
                            Text(model.displayName).tag(Optional(model))
                        }
                    }
                }
                
                Section {
                    Button("Create Chat") {
                        let _ = selectedModel ?? appState.selectedModel
                        let newConversation = appState.createNewConversation(title: chatTitle)
                        appState.selectConversation(newConversation)
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            selectedModel = appState.selectedModel
        }
    }
}

/// Conversation row view
struct ConversationRowView: View {
    var conversation: Conversation
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Button(action: {
            appState.selectConversation(conversation)
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(conversation.title)
                        .fontWeight(appState.activeConversation?.id == conversation.id ? .bold : .regular)
                    
                    Text(conversation.model.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if appState.activeConversation?.id == conversation.id {
                    Circle()
                        .fill(Color.blue) // Using standard color instead of model-specific color
                        .frame(width: 8, height: 8)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Extensions

extension AppState {
    /// Mock property for the list of conversations
    var conversations: [Conversation] {
        return [] // This would be implemented in the real AppState
    }
    
    /// Mock property for the currently active conversation
    var activeConversation: Conversation? {
        return nil // This would be implemented in the real AppState
    }
    
    /// Mock property for show settings toggle
    var showSettings: Bool {
        get { return false }
        set { /* This would be implemented in the real AppState */ }
    }
    
    /// Mock method to create a new conversation
    func createNewConversation(title: String) -> Conversation {
        return Conversation(title: title, model: selectedModel) // This would be implemented in the real AppState
    }
    
    /// Mock method to select a conversation
    func selectConversation(_ conversation: Conversation) {
        // This would be implemented in the real AppState
    }
    
    /// Mock method to delete a conversation
    func deleteConversation(_ conversation: Conversation) {
        // This would be implemented in the real AppState
    }
}