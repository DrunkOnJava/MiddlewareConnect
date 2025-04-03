import SwiftUI
import Combine
import Foundation

/// Chat interface tab
public struct ChatTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: ChatViewModel
    @State private var showSettingsSheet: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    public init() {
        // Initialize with default view model and data provider
        let viewModel = ChatViewModel(
            conversationId: UUID(),
            dataProvider: ChatDataProvider.shared
        )
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack {
            // Chat header
            ChatHeaderView(
                modelName: appState.selectedModel.displayName,
                onNewChat: { viewModel.clearConversation() },
                onShowSettings: { showSettingsSheet = true }
            )
            
            // Messages
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.messages.isEmpty {
                            EmptyChatView()
                        } else {
                            ForEach(viewModel.messages) { message in
                                ChatBubbleView(
                                    role: message.role,
                                    timestamp: message.timestamp,
                                    isStreaming: message.isStreaming,
                                    actions: getChatActions(for: message),
                                    onActionTriggered: { handleAction($0, for: message) }
                                ) {
                                    if message.isStreaming {
                                        StreamingResponseView(
                                            text: message.content,
                                            isStreaming: true
                                        )
                                    } else {
                                        Text(message.content)
                                    }
                                }
                                .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { _ in
                    // Scroll to the bottom when messages change
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input area with message composer
            MessageComposerView(
                text: $viewModel.messageText,
                isGenerating: viewModel.isGenerating,
                onSend: viewModel.sendMessage,
                onCancel: viewModel.cancelGeneration
            )
        }
        .navigationTitle("Chat")
        .onChange(of: viewModel.error) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showSettingsSheet) {
            ChatSettingsView(viewModel: viewModel)
        }
        .onAppear {
            // Initialize with current model from AppState
            viewModel.changeModel(to: appState.selectedModel)
            
            // Add a welcome message if there are no messages
            if viewModel.messages.isEmpty {
                let welcomeMessage = LLMChatMessage.assistant(content: "Hello! How can I assist you today?")
                viewModel.messages.append(welcomeMessage)
            }
        }
    }
    
    /// Get available actions for a specific message
    private func getChatActions(for message: LLMChatMessage) -> [ChatMessageAction] {
        var actions: [ChatMessageAction] = []
        
        // All messages can be copied
        actions.append(.copy)
        
        // Assistant messages can be regenerated if they're the last one
        if message.role == .assistant, 
           message == viewModel.messages.last(where: { $0.role == .assistant }),
           !viewModel.isGenerating {
            actions.append(.regenerate)
        }
        
        // User and assistant messages can be deleted
        if message.role != .system {
            actions.append(.delete)
        }
        
        return actions
    }
    
    /// Handle action for a message
    private func handleAction(_ action: ChatMessageAction, for message: LLMChatMessage) {
        switch action.title {
        case "Copy":
            UIPasteboard.general.string = message.content
            // Could show a toast notification here
            
        case "Regenerate":
            // Find the last user message
            if let lastUserMessage = viewModel.messages.last(where: { $0.role == .user }) {
                // Remove messages after this user's message
                viewModel.messages = viewModel.messages.filter { msg in
                    if msg.role == .assistant && msg.timestamp > lastUserMessage.timestamp {
                        return false
                    }
                    return true
                }
                
                // Regenerate response
                viewModel.sendMessage()
            }
            
        case "Delete":
            viewModel.messages.removeAll { $0.id == message.id }
            
        default:
            break
        }
    }
}

/// Chat header view
struct ChatHeaderView: View {
    let modelName: String
    var onNewChat: () -> Void
    var onShowSettings: () -> Void
    
    var body: some View {
        HStack {
            // Model icon
            Image(systemName: "brain")
                .font(.system(size: 18))
                .foregroundColor(DesignSystem.Colors.primary)
            
            // Model name
            Text(modelName)
                .font(.subheadline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
            
            Spacer()
            
            // New chat button
            Button(action: onNewChat) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
            .accessibilityLabel("New Chat")
            
            // Settings button
            Button(action: onShowSettings) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18))
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Chat Settings")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(DesignSystem.Colors.background)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .bottom
        )
    }
}

/// Message composer view for input
struct MessageComposerView: View {
    @Binding var text: String
    var isGenerating: Bool
    var onSend: () -> Void
    var onCancel: () -> Void
    
    @State private var textFieldHeight: CGFloat = 40
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                // Message input field with auto-resizing
                ZStack(alignment: .leading) {
                    Text(text.isEmpty ? "Type a message..." : text)
                        .foregroundColor(.clear)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(GeometryReader { geometry in
                            Color.clear.preference(
                                key: ViewHeightKey.self,
                                value: geometry.size.height
                            )
                        })
                    
                    TextEditor(text: $text)
                        .frame(height: max(40, textFieldHeight))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 0)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .focused($isFocused)
                        .disabled(isGenerating)
                }
                .onPreferenceChange(ViewHeightKey.self) { height in
                    // Limit max height
                    textFieldHeight = min(height + 16, 120)
                }
                .padding(2)
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(DesignSystem.Colors.secondaryText.opacity(0.2), lineWidth: 1)
                )
                .padding(.leading, 10)
                
                // Send or Cancel button
                if isGenerating {
                    Button(action: onCancel) {
                        Image(systemName: "stop.fill")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    .transition(.opacity)
                    .padding(.trailing, 10)
                    .animation(.easeInOut, value: isGenerating)
                    .accessibilityLabel("Cancel Generation")
                } else {
                    Button(action: onSend) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                        DesignSystem.Colors.secondary.opacity(0.5) : 
                                        DesignSystem.Colors.primary)
                            .clipShape(Circle())
                    }
                    .transition(.opacity)
                    .padding(.trailing, 10)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .animation(.easeInOut, value: isGenerating)
                    .accessibilityLabel("Send Message")
                }
            }
            .padding(.vertical, 8)
        }
    }
}

/// Chat settings view
struct ChatSettingsView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var systemPrompt: String = ""
    @State private var useStreaming: Bool = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Response Options")) {
                    Toggle("Use Streaming", isOn: $useStreaming)
                        .onChange(of: useStreaming) { newValue in
                            viewModel.useStreaming = newValue
                        }
                }
                
                Section(header: Text("System Prompt"), footer: Text("Set instructions for how the AI should behave throughout the conversation.")) {
                    TextEditor(text: $systemPrompt)
                        .frame(height: 150)
                        .padding(4)
                }
            }
            .navigationTitle("Chat Settings")
            .navigationBarItems(trailing: Button("Done") {
                viewModel.updateSystemPrompt(systemPrompt)
                dismiss()
            })
            .onAppear {
                // Load current system prompt
                if let systemMessage = viewModel.messages.first(where: { $0.role == .system }) {
                    systemPrompt = systemMessage.content
                }
                
                // Load current streaming setting
                useStreaming = viewModel.useStreaming
            }
        }
    }
}

/// Height measurement preference key
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Empty chat view with welcome message
struct EmptyChatView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.secondary.opacity(0.7))
            
            Text("Start a conversation")
                .font(DesignSystem.Typography.title2)
                .fontWeight(.medium)
            
            Text("Type a message below to begin chatting with the AI assistant.")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}
