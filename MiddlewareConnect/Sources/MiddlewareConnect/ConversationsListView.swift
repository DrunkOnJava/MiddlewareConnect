/**
@fileoverview View for managing conversations
@module ConversationsListView
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- SwiftUI
- Combine
Notes:
- Displays a list of saved conversations
- Allows creating, opening, and deleting conversations
/

import SwiftUI
import Combine

/// Conversation list view
struct ConversationsListView: View {
    // MARK: - Properties
    
    @EnvironmentObject var appState: AppState
    @State private var conversations: [ChatConversation] = []
    @State private var selectedConversation: ChatConversation?
    @State private var showNewChatSheet: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            List {
                // New chat button
                Button(action: { showNewChatSheet = true }) {
                    Label("New Chat", systemImage: "plus.circle.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                        .font(DesignSystem.Typography.headline)
                }
                .padding(.vertical, 8)
                
                // Recent conversations
                if !conversations.isEmpty {
                    Section(header: Text("Recent Conversations")) {
                        ForEach(conversations) { conversation in
                            NavigationLink(
                                destination: ChatTabView()
                                    .environmentObject(appState),
                                tag: conversation.id,
                                selection: .constant(selectedConversation?.id)
                            ) {
                                ConversationRowView(conversation: conversation)
                            }
                        }
                        .onDelete(perform: deleteConversations)
                    }
                } else {
                    Section {
                        Text("No saved conversations")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            .refreshable {
                loadConversations()
            }
            .onAppear {
                loadConversations()
                subscribeToUpdates()
            }
            .sheet(isPresented: $showNewChatSheet) {
                NewChatSheet(isPresented: $showNewChatSheet)
            }
        }
    }
    
    // MARK: - Methods
    
    /// Load conversations from data provider
    private func loadConversations() {
        conversations = ChatDataProvider.shared.getAllConversations()
    }
    
    /// Subscribe to conversation updates
    private func subscribeToUpdates() {
        ChatDataProvider.shared.conversationsPublisher
            .receive(on: DispatchQueue.main)
            .sink { updatedConversations in
                self.conversations = updatedConversations
            }
            .store(in: &cancellables)
    }
    
    /// Delete conversations at specified offsets
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversationId = conversations[index].id
            ChatDataProvider.shared.deleteConversation(id: conversationId)
        }
    }
}

/// Row view for a conversation
struct ConversationRowView: View {
    let conversation: ChatConversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title
            Text(conversation.title)
                .font(DesignSystem.Typography.headline)
                .lineLimit(1)
            
            // Preview
            Text(previewText)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .lineLimit(1)
            
            // Date and model
            HStack {
                Text(formattedDate)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
                
                Spacer()
                
                Text(conversation.model.name)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.tertiaryText)
            }
        }
        .padding(.vertical, 4)
    }
    
    /// Get preview text from the last message
    private var previewText: String {
        if let lastMessage = conversation.messages.last {
            return lastMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "Empty conversation"
    }
    
    /// Format the date
    private var formattedDate: String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(conversation.lastUpdated) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: conversation.lastUpdated))"
        } else if Calendar.current.isDateInYesterday(conversation.lastUpdated) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "Yesterday, \(formatter.string(from: conversation.lastUpdated))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: conversation.lastUpdated)
        }
    }
}

/// Sheet for creating a new chat
struct NewChatSheet: View {
    @Binding var isPresented: Bool
    @State private var systemPrompt: String = ""
    @State private var selectedModel: LLMModel = .claudeSonnet
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Model")) {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(LLMModel.defaultModels) { model in
                            Text(model.name)
                                .tag(model)
                        }
                    }
                }
                
                Section(header: Text("System Prompt"), footer: Text("Optional instructions for how the AI should behave.")) {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 150)
                        .padding(4)
                }
                
                Section {
                    Button(action: createNewChat) {
                        Text("Start Chat")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Chat")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
    
    /// Create a new chat conversation
    private func createNewChat() {
        // Create a new conversation
        let id = UUID()
        
        var messages: [LLMChatMessage] = []
        
        // Add system message if provided
        if !systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append(LLMChatMessage.system(content: systemPrompt))
        }
        
        // Add welcome message
        messages.append(LLMChatMessage.assistant(content: "Hello! How can I assist you today?"))
        
        // Create conversation
        let conversation = ChatConversation(
            id: id,
            title: "New Conversation",
            messages: messages,
            model: selectedModel,
            lastUpdated: Date()
        )
        
        // Save to provider
        ChatDataProvider.shared.saveConversation(conversation)
        
        // Close sheet
        isPresented = false
    }
}

struct ConversationsListView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationsListView()
            .environmentObject(AppState())
    }
}
