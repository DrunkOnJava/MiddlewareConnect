import SwiftUI
import Combine

/// Represents a message in a conversation
struct Message: Identifiable, Equatable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}

/// A view that displays a conversation with streaming capabilities
struct ConversationView: View {
    /// The array of messages in the conversation
    @Binding var messages: [Message]
    
    /// The current input text
    @Binding var inputText: String
    
    /// Whether a response is currently streaming
    @Binding var isStreaming: Bool
    
    /// Publisher for streaming responses
    var streamingPublisher: AnyPublisher<StreamingResponse, Never>?
    
    /// Current streaming text
    @State private var streamingText: String = ""
    
    /// Callback when user sends a message
    var onSendMessage: (() -> Void)?
    
    /// Callback when a message action is triggered
    var onMessageAction: ((Message, ChatMessageAction) -> Void)?
    
    /// Controls whether to scroll to bottom when streaming
    @State private var shouldScrollToBottom: Bool = false
    
    /// ID for the latest message (for scrolling)
    @State private var lastMessageID: UUID?
    
    /// Scroll view reader for automatic scrolling
    @Namespace private var bottomID
    
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            ChatBubbleView(
                                role: message.role,
                                timestamp: message.timestamp,
                                actions: getChatActionsFor(message: message)
                            ) {
                                Text(message.content)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .id(message.id)
                            .transition(.opacity)
                        }
                        
                        // Streaming message (if active)
                        if isStreaming {
                            ChatBubbleView(
                                role: .assistant,
                                timestamp: Date(),
                                isStreaming: true
                            ) {
                                StreamingResponseView(
                                    text: streamingText,
                                    isStreaming: isStreaming
                                )
                            }
                            .id("streaming")
                            .transition(.opacity)
                        }
                        
                        // Empty view for scrolling to bottom
                        Color.clear
                            .frame(height: 1)
                            .id(bottomID)
                    }
                    .padding(.vertical, 16)
                }
                .onChange(of: shouldScrollToBottom) { _ in
                    withAnimation {
                        scrollView.scrollTo(bottomID)
                    }
                }
                .onChange(of: messages) { newMessages in
                    // When messages change, scroll to bottom
                    if let lastMessage = newMessages.last, lastMessage.id != lastMessageID {
                        lastMessageID = lastMessage.id
                        withAnimation {
                            scrollView.scrollTo(bottomID)
                        }
                    }
                }
                .onChange(of: streamingText) { _ in
                    // Scroll while streaming (but not too frequently)
                    if isStreaming && streamingText.count % 50 == 0 {
                        withAnimation {
                            scrollView.scrollTo(bottomID)
                        }
                    }
                }
                .onChange(of: isStreaming) { streaming in
                    if streaming {
                        // When streaming starts, scroll to bottom
                        withAnimation {
                            scrollView.scrollTo(bottomID)
                        }
                    } else if !streamingText.isEmpty {
                        // When streaming ends, add the final message
                        if let last = messages.last, last.role != .assistant {
                            messages.append(Message(
                                role: .assistant,
                                content: streamingText,
                                timestamp: Date()
                            ))
                        }
                        
                        // Reset streaming text
                        streamingText = ""
                        
                        // Scroll to the new message
                        withAnimation {
                            scrollView.scrollTo(bottomID)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                // Text input
                ZStack(alignment: .topLeading) {
                    if inputText.isEmpty {
                        Text("Type a message...")
                            .foregroundColor(DesignSystem.Colors.tertiaryText)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .disabled(true)
                    }
                    
                    TextEditor(text: $inputText)
                        .padding(4)
                        .frame(minHeight: 40, maxHeight: 120)
                        .opacity(inputText.isEmpty ? 0.25 : 1)
                }
                .frame(minHeight: 40)
                .padding(8)
                .background(DesignSystem.Colors.secondaryBackground)
                .cornerRadius(DesignSystem.Radius.medium)
                
                // Send button
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(canSendMessage ? DesignSystem.Colors.primary : DesignSystem.Colors.secondaryText)
                }
                .disabled(!canSendMessage)
            }
            .padding(12)
        }
        .onAppear {
            setupStreamingSubscription()
        }
        .onDisappear {
            cancellables.forEach { $0.cancel() }
            cancellables.removeAll()
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSendMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isStreaming
    }
    
    // MARK: - Actions
    
    /// Sends the current input as a message
    private func sendMessage() {
        guard canSendMessage else { return }
        
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Create new message
        let newMessage = Message(
            role: .user,
            content: trimmedText,
            timestamp: Date()
        )
        
        // Add to messages
        messages.append(newMessage)
        
        // Clear input
        inputText = ""
        
        // Notify parent
        onSendMessage?()
        
        // Provide haptic feedback
        DesignSystem.hapticFeedback(.medium)
        
        // Trigger scroll to bottom
        shouldScrollToBottom = true
    }
    
    /// Sets up the subscription to the streaming publisher
    private func setupStreamingSubscription() {
        // Clear previous subscriptions
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // Set up new subscription if available
        streamingPublisher?
            .receive(on: DispatchQueue.main)
            .sink { response in
                // Accumulate streaming text
                if !response.isComplete {
                    streamingText += response.content
                } else {
                    // Add complete message when streaming finishes
                    isStreaming = false
                }
            }
            .store(in: &cancellables)
    }
    
    /// Returns the available actions for a message
    private func getChatActionsFor(message: Message) -> [ChatMessageAction] {
        var actions: [ChatMessageAction] = []
        
        // All messages can be copied
        actions.append(.copy)
        
        if message.role == .assistant {
            // Assistant messages can be regenerated
            actions.append(.regenerate)
        }
        
        // All messages can be deleted
        actions.append(.delete)
        
        return actions
    }
}

// MARK: - Preview

struct ConversationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Sample conversation
            VStack {
                ConversationView(
                    messages: .constant([
                        Message(role: .user, content: "What is quantum computing?", timestamp: Date().addingTimeInterval(-120)),
                        Message(role: .assistant, content: "Quantum computing is a type of computing that uses quantum-mechanical phenomena, such as superposition and entanglement, to perform operations on data. Unlike classical computers that use bits as the smallest unit of data (either a 0 or a 1), quantum computers use quantum bits or qubits, which can exist in multiple states simultaneously.", timestamp: Date().addingTimeInterval(-100)),
                        Message(role: .user, content: "Can you explain it more simply?", timestamp: Date().addingTimeInterval(-60))
                    ]),
                    inputText: .constant(""),
                    isStreaming: .constant(true),
                    streamingPublisher: Just(StreamingResponse(content: "Sure! Think of classical computers like light switches - they're either on or off. Quantum computers are more like dimmers that can be on, off, or any brightness in between, all at the same time. This gives them unique abilities to solve certain problems much faster.")).eraseToAnyPublisher()
                )
            }
            .frame(height: 600)
            .previewDisplayName("Conversation with Streaming")
            
            // Empty conversation
            VStack {
                ConversationView(
                    messages: .constant([]),
                    inputText: .constant(""),
                    isStreaming: .constant(false)
                )
            }
            .frame(height: 600)
            .previewDisplayName("Empty Conversation")
            
            // Dark mode
            VStack {
                ConversationView(
                    messages: .constant([
                        Message(role: .system, content: "This is a simulation of dark mode", timestamp: Date().addingTimeInterval(-180)),
                        Message(role: .user, content: "How does dark mode look?", timestamp: Date().addingTimeInterval(-120)),
                        Message(role: .assistant, content: "Dark mode looks great! The contrast is adjusted to be easier on the eyes while maintaining readability.", timestamp: Date().addingTimeInterval(-100))
                    ]),
                    inputText: .constant("It does look good!"),
                    isStreaming: .constant(false)
                )
            }
            .frame(height: 600)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
