import SwiftUI

/// Chat interface tab
public struct ChatTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var messageText: String = ""
    @State private var messages: [LLMChatMessage] = []
    @State private var isGenerating: Bool = false
    
    public var body: some View {
        VStack {
            // Chat header
            ChatHeaderView(modelName: appState.selectedModel.displayName)
            
            // Messages
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if messages.isEmpty {
                            EmptyChatView()
                        } else {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: messages) { _ in
                    // Scroll to the bottom when messages change
                    if let lastMessage = messages.last {
                        withAnimation {
                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input area
            HStack {
                // Message input field
                TextField("Type a message...", text: $messageText)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .padding(.leading, 10)
                    .disabled(isGenerating)
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(isGenerating ? Color.gray : Color.blue)
                        .cornerRadius(20)
                }
                .padding(.trailing, 10)
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
            }
            .padding(.vertical, 10)
        }
        .navigationTitle("Chat")
        .onAppear {
            // Add a welcome message if there are no messages
            if messages.isEmpty {
                messages.append(LLMChatMessage(content: "Hello! How can I assist you today?", isUser: false))
            }
        }
    }
    
    /// Send a message
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Add the user message
        let userMessage = LLMChatMessage(content: trimmedText, isUser: true)
        messages.append(userMessage)
        
        // Clear the input field
        messageText = ""
        
        // Simulate LLM response
        isGenerating = true
        
        // In a real app, this would call an LLM API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let responseMessage = LLMChatMessage(content: "This is a placeholder response. In a real implementation, this would integrate with a real LLM API.", isUser: false)
            messages.append(responseMessage)
            isGenerating = false
        }
    }
}

/// Chat header view
struct ChatHeaderView: View {
    let modelName: String
    
    var body: some View {
        HStack {
            // Model icon
            Image(systemName: "brain")
                .font(.system(size: 18))
                .foregroundColor(.purple)
            
            // Model name
            Text(modelName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // New chat button
            Button(action: {
                // In a real app, this would start a new chat
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
            .padding(.trailing, 8)
            
            // Settings button
            Button(action: {
                // In a real app, this would show chat settings
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .bottom
        )
    }
}

/// Message bubble view
struct MessageBubble: View {
    let message: LLMChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 2) {
                // Message content
                Text(message.content)
                    .padding(12)
                    .background(message.isUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
                    .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)
                
                // Timestamp
                Text(timeString(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
    
    /// Format a timestamp
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Empty chat view with welcome message
struct EmptyChatView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.7))
            
            Text("Start a conversation")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Type a message below to begin chatting with the AI assistant.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}
