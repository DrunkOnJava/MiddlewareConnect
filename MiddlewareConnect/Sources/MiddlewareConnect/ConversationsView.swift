/**
@fileoverview Conversations View
@module ConversationsView
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- SwiftUI
- Combine
Exports:
- ConversationsView
- ChatView
Notes:
- Manages conversation list and chat interactions
- Integrates with LLM service for message handling
/

import SwiftUI
import Combine

/// Main conversations view
struct ConversationsView: View {
    // MARK: - Properties
    
    /// View model
    @StateObject private var viewModel = ConversationsViewModel()
    
    /// Selected conversation
    @State private var selectedConversation: Conversation?
    
    /// Show new conversation sheet
    @State private var showingNewConversation = false
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad: Split view
                splitView
            } else {
                // iPhone: Navigation stack
                masterView
            }
        }
        .navigationTitle("Conversations")
        .navigationBarItems(trailing: newConversationButton)
        .sheet(isPresented: $showingNewConversation) {
            NewConversationView(onCreate: { title in
                viewModel.createConversation(title: title) { conversation in
                    selectedConversation = conversation
                    showingNewConversation = false
                }
            })
        }
        .onAppear {
            viewModel.loadConversations()
        }
    }
    
    /// Split view for iPad
    private var splitView: some View {
        HStack(spacing: 0) {
            // Master view
            List {
                ForEach(viewModel.conversations) { conversation in
                    ConversationCell(conversation: conversation)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedConversation = conversation
                        }
                        .background(
                            selectedConversation?.id == conversation.id ?
                                Color(.systemGray5) : Color.clear
                        )
                }
                .onDelete { indexSet in
                    viewModel.deleteConversations(at: indexSet) { deletedIds in
                        if let selectedId = selectedConversation?.id,
                           deletedIds.contains(selectedId) {
                            selectedConversation = nil
                        }
                    }
                }
            }
            .frame(width: 300)
            .background(Color(.systemGroupedBackground))
            
            // Detail view
            if let conversation = selectedConversation {
                ChatView(conversation: conversation, viewModel: viewModel)
            } else {
                emptyDetailView
            }
        }
    }
    
    /// Master view for iPhone
    private var masterView: some View {
        List {
            ForEach(viewModel.conversations) { conversation in
                NavigationLink(
                    destination: ChatView(conversation: conversation, viewModel: viewModel)
                ) {
                    ConversationCell(conversation: conversation)
                }
            }
            .onDelete { indexSet in
                viewModel.deleteConversations(at: indexSet)
            }
        }
    }
    
    /// Empty detail view
    private var emptyDetailView: some View {
        VStack {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 72))
                .foregroundColor(.gray)
            
            Text("Select a conversation or create a new one")
                .font(.headline)
                .foregroundColor(.gray)
                .padding()
            
            Button(action: {
                showingNewConversation = true
            }) {
                Text("Start New Conversation")
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// New conversation button
    private var newConversationButton: some View {
        Button(action: {
            showingNewConversation = true
        }) {
            Image(systemName: "square.and.pencil")
        }
    }
}

/// Chat view for a single conversation
struct ChatView: View {
    // MARK: - Properties
    
    /// Conversation
    let conversation: Conversation
    
    /// View model
    @ObservedObject var viewModel: ConversationsViewModel
    
    /// Message text
    @State private var messageText = ""
    
    /// Scroll proxy
    @Namespace private var bottomID
    
    /// Focus state for text field
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.getMessages(for: conversation.id)) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Anchor view for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id(bottomID)
                    }
                    .padding()
                }
                .onChange(of: viewModel.getMessages(for: conversation.id).count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // Thinking indicator
            if viewModel.isProcessing {
                HStack {
                    Text("Claude is thinking")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    ProgressView()
                        .scaleEffect(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
            }
            
            // Message input
            HStack {
                TextField("Type a message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .disabled(viewModel.isProcessing)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(canSendMessage ? .blue : .gray)
                }
                .disabled(!canSendMessage)
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                Divider()
                    .frame(height: 1)
                    .background(Color(.systemGray5)),
                alignment: .top
            )
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        viewModel.clearConversation(conversation: conversation)
                    }) {
                        Label("Clear Conversation", systemImage: "trash")
                    }
                    
                    Button(action: {
                        // Share conversation
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    /// Can send message
    private var canSendMessage: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isProcessing
    }
    
    // MARK: - Methods
    
    /// Sends a message
    private func sendMessage() {
        guard canSendMessage else { return }
        
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        
        viewModel.sendMessage(content: message, in: conversation)
    }
    
    /// Scrolls to the bottom of the messages
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo(bottomID, anchor: .bottom)
        }
    }
}

/// Conversation cell
struct ConversationCell: View {
    // MARK: - Properties
    
    /// Conversation
    let conversation: Conversation
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
                .lineLimit(1)
            
            Text(lastMessagePreview)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(1)
            
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
    
    /// Last message preview
    private var lastMessagePreview: String {
        if let lastMessage = conversation.messages.last {
            return lastMessage.content
        } else {
            return "No messages"
        }
    }
    
    /// Formatted date
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: conversation.updatedAt, relativeTo: Date())
    }
}

/// New conversation view
struct NewConversationView: View {
    // MARK: - Properties
    
    /// Conversation title
    @State private var title = ""
    
    /// On create callback
    let onCreate: (String) -> Void
    
    /// Dismiss action
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Conversation Details")) {
                    TextField("Title", text: $title)
                }
                
                Section {
                    Button(action: createConversation) {
                        Text("Create")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("New Conversation")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // MARK: - Methods
    
    /// Creates a new conversation
    private func createConversation() {
        guard !title.isEmpty else { return }
        onCreate(title)
    }
}

/// Conversations view model
class ConversationsViewModel: ObservableObject {
    // MARK: - Properties
    
    /// Conversations
    @Published private(set) var conversations: [Conversation] = []
    
    /// Messages by conversation ID
    @Published private(set) var messagesByConversation: [String: [Message]] = [:]
    
    /// Is processing
    @Published private(set) var isProcessing = false
    
    /// Database service
    private let databaseService = DatabaseService.shared
    
    /// LLM service
    private let llmService = LLMServiceProvider.shared
    
    /// Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        // Subscribe to status changes
        llmService.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isProcessing = status == .processing
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Methods
    
    /// Loads all conversations
    func loadConversations() {
        Task {
            do {
                // Get conversations from database
                let dbConversations = try await databaseService.conversationRepository.fetchAll()
                
                // Create view models
                let conversationModels = dbConversations.map { dbConversation in
                    Conversation(
                        id: dbConversation.id,
                        title: dbConversation.title,
                        createdAt: dbConversation.createdAt,
                        updatedAt: dbConversation.updatedAt,
                        messages: dbConversation.messages.map { dbMessage in
                            Message(
                                id: dbMessage.id,
                                role: MessageRole(rawValue: dbMessage.role) ?? .user,
                                content: dbMessage.content,
                                timestamp: dbMessage.createdAt
                            )
                        }
                    )
                }
                
                // Update state
                DispatchQueue.main.async {
                    self.conversations = conversationModels.sorted { $0.updatedAt > $1.updatedAt }
                    
                    // Organize messages by conversation ID
                    for conversation in conversationModels {
                        self.messagesByConversation[conversation.id] = conversation.messages
                    }
                }
            } catch {
                print("Error loading conversations: \(error.localizedDescription)")
            }
        }
    }
    
    /// Creates a new conversation
    /// - Parameters:
    ///   - title: The conversation title
    ///   - completion: Callback with the created conversation
    func createConversation(title: String, completion: ((Conversation) -> Void)? = nil) {
        let id = UUID().uuidString
        let now = Date()
        
        let conversation = Database.Conversation(
            id: id,
            title: title,
            createdAt: now,
            updatedAt: now,
            messages: []
        )
        
        Task {
            do {
                let createdConversation = try await databaseService.conversationRepository.create(conversation)
                
                let viewModel = Conversation(
                    id: createdConversation.id,
                    title: createdConversation.title,
                    createdAt: createdConversation.createdAt,
                    updatedAt: createdConversation.updatedAt,
                    messages: []
                )
                
                DispatchQueue.main.async {
                    self.conversations.insert(viewModel, at: 0)
                    self.messagesByConversation[viewModel.id] = []
                    completion?(viewModel)
                }
            } catch {
                print("Error creating conversation: \(error.localizedDescription)")
            }
        }
    }
    
    /// Deletes conversations
    /// - Parameters:
    ///   - indexSet: The index set of conversations to delete
    ///   - completion: Callback with the deleted conversation IDs
    func deleteConversations(at indexSet: IndexSet, completion: (([String]) -> Void)? = nil) {
        let conversationsToDelete = indexSet.map { conversations[$0] }
        let conversationIds = conversationsToDelete.map { $0.id }
        
        Task {
            do {
                for id in conversationIds {
                    try await databaseService.conversationRepository.delete(id: id)
                }
                
                DispatchQueue.main.async {
                    self.conversations.remove(atOffsets: indexSet)
                    
                    for id in conversationIds {
                        self.messagesByConversation.removeValue(forKey: id)
                    }
                    
                    completion?(conversationIds)
                }
            } catch {
                print("Error deleting conversations: \(error.localizedDescription)")
            }
        }
    }
    
    /// Clears a conversation
    /// - Parameter conversation: The conversation to clear
    func clearConversation(conversation: Conversation) {
        Task {
            do {
                // Get the conversation from the database
                let dbConversation = try await databaseService.conversationRepository.fetch(id: conversation.id)
                
                // Remove all messages
                var updatedConversation = dbConversation
                updatedConversation.messages = []
                
                // Update the conversation
                let result = try await databaseService.conversationRepository.update(updatedConversation)
                
                DispatchQueue.main.async {
                    self.messagesByConversation[conversation.id] = []
                    
                    // Update the conversation in the list
                    if let index = self.conversations.firstIndex(where: { $0.id == conversation.id }) {
                        self.conversations[index].messages = []
                    }
                }
            } catch {
                print("Error clearing conversation: \(error.localizedDescription)")
            }
        }
    }
    
    /// Sends a message in a conversation
    /// - Parameters:
    ///   - content: The message content
    ///   - conversation: The conversation
    func sendMessage(content: String, in conversation: Conversation) {
        // Create user message
        let userMessageId = UUID().uuidString
        let userMessage = Message(
            id: userMessageId,
            role: .user,
            content: content,
            timestamp: Date()
        )
        
        // Add user message to UI immediately
        DispatchQueue.main.async {
            if var messages = self.messagesByConversation[conversation.id] {
                messages.append(userMessage)
                self.messagesByConversation[conversation.id] = messages
            } else {
                self.messagesByConversation[conversation.id] = [userMessage]
            }
        }
        
        // Add message to database
        let dbUserMessage = Database.Conversation.Message(
            id: userMessageId,
            role: "user",
            content: content,
            createdAt: Date()
        )
        
        Task {
            do {
                // Add user message to database
                let updatedConversation = try await databaseService.conversationRepository.addMessage(
                    conversationId: conversation.id,
                    message: dbUserMessage
                )
                
                // Use LLM service to get response
                llmService.sendMessage(content) { [weak self] result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let responseText):
                        // Create assistant message
                        let assistantMessageId = UUID().uuidString
                        let assistantMessage = Message(
                            id: assistantMessageId,
                            role: .assistant,
                            content: responseText,
                            timestamp: Date()
                        )
                        
                        // Add assistant message to UI
                        DispatchQueue.main.async {
                            if var messages = self.messagesByConversation[conversation.id] {
                                messages.append(assistantMessage)
                                self.messagesByConversation[conversation.id] = messages
                            } else {
                                self.messagesByConversation[conversation.id] = [assistantMessage]
                            }
                        }
                        
                        // Add message to database
                        let dbAssistantMessage = Database.Conversation.Message(
                            id: assistantMessageId,
                            role: "assistant",
                            content: responseText,
                            createdAt: Date()
                        )
                        
                        Task {
                            do {
                                // Add assistant message to database
                                _ = try await self.databaseService.conversationRepository.addMessage(
                                    conversationId: conversation.id,
                                    message: dbAssistantMessage
                                )
                                
                                // Update the conversation in the list
                                if let index = self.conversations.firstIndex(where: { $0.id == conversation.id }) {
                                    DispatchQueue.main.async {
                                        self.conversations[index].updatedAt = Date()
                                        
                                        // Re-sort conversations
                                        self.conversations.sort { $0.updatedAt > $1.updatedAt }
                                    }
                                }
                            } catch {
                                print("Error adding assistant message: \(error.localizedDescription)")
                            }
                        }
                        
                    case .failure(let error):
                        print("Error getting response: \(error.localizedDescription)")
                    }
                }
                
            } catch {
                print("Error adding user message: \(error.localizedDescription)")
            }
        }
    }
    
    /// Gets messages for a conversation
    /// - Parameter conversationId: The conversation ID
    /// - Returns: The messages
    func getMessages(for conversationId: String) -> [Message] {
        return messagesByConversation[conversationId] ?? []
    }
}

/// Conversation model
struct Conversation: Identifiable, Equatable {
    /// Identifier
    var id: String
    
    /// Title
    var title: String
    
    /// Creation date
    var createdAt: Date
    
    /// Last update date
    var updatedAt: Date
    
    /// Messages
    var messages: [Message]
    
    /// Equatable
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Preview provider
struct ConversationsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ConversationsView()
        }
    }
}
