/**
@fileoverview View model for managing conversations with LLMs
@module ConversationViewModel
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- Foundation
- Combine
- SwiftUI
/

import Foundation
import Combine
import SwiftUI

/// View model for managing active conversations
class ConversationViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current conversation title
    @Published var title: String
    
    /// Current conversation ID
    let conversationId: UUID
    
    /// Model being used
    @Published var model: LLMModel
    
    /// Input message text
    @Published var messageText: String = ""
    
    /// Whether the LLM is currently generating text
    @Published var isGenerating: Bool = false
    
    /// Error message if any
    @Published var errorMessage: String? = nil
    
    /// Messages in the current conversation
    @Published var messages: [LLMChatMessage] = []
    
    /// Whether to use streaming responses
    @Published var useStreaming: Bool = true
    
    // MARK: - Private Properties
    
    /// Data provider for persistence
    private let dataProvider: DataProviderProtocol
    
    /// Anthropic service for Claude API
    private let anthropicService = AnthropicService()
    
    /// Subscription for API status
    private var apiStatusSubscription: AnyCancellable?
    
    /// Subscription for streaming responses
    private var streamingSubscription: AnyCancellable?
    
    /// Set of cancellables for memory management
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize with an existing conversation or create a new one
    init(
        conversationId: UUID = UUID(),
        title: String = "New Conversation",
        model: LLMModel = .claudeSonnet,
        dataProvider: DataProviderProtocol = ChatDataProvider.shared
    ) {
        self.conversationId = conversationId
        self.title = title
        self.model = model
        self.dataProvider = dataProvider
        
        loadConversation()
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Send a message to the LLM
    func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isGenerating else { return }
        
        // Create user message
        let userMessage = LLMChatMessage.user(content: trimmedText)
        messages.append(userMessage)
        
        // Clear input field
        messageText = ""
        
        // Generate new title if this is the first user message
        if title == "New Conversation" && messages.count == 1 {
            generateTitle(from: trimmedText)
        }
        
        // Add placeholder for streaming response
        if useStreaming {
            let streamingMessage = LLMChatMessage.streaming()
            messages.append(streamingMessage)
        }
        
        // Save conversation
        saveConversation()
        
        // Generate response based on the model provider
        switch model.provider {
        case .anthropic:
            generateAnthropicResponse(to: userMessage)
        case .openAI, .google, .meta, .localModel, .customAPI:
            // Not implemented yet - fallback to fake response
            generatePlaceholderResponse(to: userMessage)
        }
    }
    
    /// Update the system prompt
    func updateSystemPrompt(_ prompt: String) {
        // Remove any existing system message
        messages.removeAll { $0.role == .system }
        
        // Add new system message if not empty
        if !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let systemMessage = LLMChatMessage.system(content: prompt)
            messages.insert(systemMessage, at: 0)
            saveConversation()
        }
    }
    
    /// Clear the conversation
    func clearConversation() {
        // Stop any ongoing generation
        cancelGeneration()
        
        // Keep system message if present
        let systemMessage = messages.first { $0.role == .system }
        
        // Reset messages
        messages = []
        
        // Re-add system message if present
        if let systemMessage = systemMessage {
            messages = [systemMessage]
        }
        
        // Reset title
        title = "New Conversation"
        
        // Save changes
        saveConversation()
    }
    
    /// Cancel the current generation
    func cancelGeneration() {
        if isGenerating {
            anthropicService.cancelStreaming()
            
            // Update any streaming message
            if let index = messages.firstIndex(where: { $0.isStreaming }) {
                messages[index].isStreaming = false
                messages[index].isComplete = true
                
                // Add cancelled note if content is empty
                if messages[index].content.isEmpty {
                    messages[index].content = "[Generation cancelled]"
                }
            }
        }
    }
    
    /// Generate a title from the first user message
    func generateTitle(from message: String) {
        // Extract first 30 chars or first sentence
        let maxLength = 30
        if message.count <= maxLength {
            title = message
        } else {
            // Try to find first sentence or just truncate
            if let endOfSentence = message.firstIndex(of: ".") {
                let distance = message.distance(from: message.startIndex, to: endOfSentence)
                if distance <= maxLength {
                    title = String(message[..<endOfSentence])
                } else {
                    title = String(message.prefix(maxLength)) + "..."
                }
            } else {
                title = String(message.prefix(maxLength)) + "..."
            }
        }
        
        saveConversation()
    }
    
    // MARK: - Private Methods
    
    /// Set up subscriptions to services
    private func setupSubscriptions() {
        // Subscribe to API status updates
        apiStatusSubscription = anthropicService.apiCallStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                
                switch status {
                case .inProgress, .streaming:
                    self.isGenerating = true
                case .completed, .streamingCompleted:
                    self.isGenerating = false
                case .failed(let error):
                    self.isGenerating = false
                    self.handleError(error)
                }
            }
        
        // Subscribe to streaming responses
        streamingSubscription = anthropicService.streamingResponse
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    self?.handleStreamingResponse(response)
                }
            )
    }
    
    /// Handle streaming response updates
    private func handleStreamingResponse(_ response: StreamingResponse) {
        // Find the current streaming message
        guard let index = messages.firstIndex(where: { $0.isStreaming }) else {
            // If no streaming message exists but we have content or completion
            if !response.content.isEmpty || response.isComplete {
                let newMessage = LLMChatMessage(
                    content: response.content,
                    role: .assistant,
                    isStreaming: !response.isComplete,
                    isComplete: response.isComplete
                )
                messages.append(newMessage)
                
                if response.isComplete {
                    saveConversation()
                }
            }
            return
        }
        
        // Update the streaming message based on response type
        switch response.type {
        case .messageDelta, .contentBlock:
            // Append content
            messages[index].content += response.content
            
        case .messageStop:
            // Mark as complete
            messages[index].isStreaming = false
            messages[index].isComplete = true
            saveConversation()
            
        case .messageStart:
            // Reset content at message start if needed
            if messages[index].content.isEmpty && response.content.isEmpty {
                // Do nothing - just starting
            } else if !response.content.isEmpty {
                // Replace with initial content
                messages[index].content = response.content
            }
            
        case .error:
            // Handle error in streaming
            messages[index].isStreaming = false
            messages[index].isComplete = true
            
            if let error = response.error {
                handleError(error)
            }
            
        case .unknown:
            // Unknown event type - just log
            print("Unknown streaming event type received")
        }
        
        // If complete, save the conversation
        if response.isComplete {
            saveConversation()
        }
    }
    
    /// Generate a response using Anthropic's Claude API
    private func generateAnthropicResponse(to message: LLMChatMessage) {
        // Get system prompt if any
        let systemPrompt = messages.first { $0.role == .system }?.content
        
        // Convert to Claude model
        let claudeModel: Claude3Model
        switch model.modelId {
        case "claude-3-opus-20240307":
            claudeModel = .opus
        case "claude-3-5-sonnet-20250307":
            claudeModel = .sonnetPlus
        case "claude-3-haiku-20240307":
            claudeModel = .haiku
        default:
            claudeModel = .sonnet
        }
        
        // Make the API call
        anthropicService.generateText(
            prompt: message.content,
            model: claudeModel,
            systemPrompt: systemPrompt,
            streaming: useStreaming
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let text):
                    // For non-streaming responses, add the complete message
                    if !self.useStreaming {
                        let assistantMessage = LLMChatMessage.assistant(content: text)
                        self.messages.append(assistantMessage)
                        self.saveConversation()
                    }
                    
                case .failure(let error):
                    self.handleError(error)
                }
            }
        }
    }
    
    /// Generate a placeholder response for unimplemented models
    private func generatePlaceholderResponse(to message: LLMChatMessage) {
        // Simulate typing delay
        isGenerating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // If streaming, update the last message
            if self.useStreaming, let index = self.messages.lastIndex(where: { $0.isStreaming }) {
                self.messages[index].content = "This model integration is not yet implemented. This is a placeholder response."
                self.messages[index].isStreaming = false
                self.messages[index].isComplete = true
            } else {
                // Otherwise add a new message
                let assistantMessage = LLMChatMessage.assistant(
                    content: "This model integration is not yet implemented. This is a placeholder response."
                )
                self.messages.append(assistantMessage)
            }
            
            self.isGenerating = false
            self.saveConversation()
        }
    }
    
    /// Handle errors during response generation
    private func handleError(_ error: Error) {
        // Set error message
        errorMessage = error.localizedDescription
        
        // If there's a streaming message, mark it complete with error
        if let index = messages.firstIndex(where: { $0.isStreaming }) {
            messages[index].isStreaming = false
            messages[index].isComplete = true
            
            // Add error message if content is empty
            if messages[index].content.isEmpty {
                messages[index].content = "[Error: \(error.localizedDescription)]"
            }
        } else {
            // Add system message with error
            let errorMessage = LLMChatMessage(
                content: "Error: \(error.localizedDescription)",
                role: .system
            )
            messages.append(errorMessage)
        }
        
        // Save conversation with error state
        saveConversation()
    }
    
    /// Load the conversation from storage
    private func loadConversation() {
        if let conversation = dataProvider.getConversation(id: conversationId) {
            title = conversation.title
            messages = conversation.messages
            model = conversation.model
        }
    }
    
    /// Save the conversation to storage
    private func saveConversation() {
        // Filter out streaming messages for storage
        let savableMessages = messages.filter { !$0.isStreaming }
        
        let conversation = ChatConversation(
            id: conversationId,
            title: title,
            messages: savableMessages,
            model: model,
            lastUpdated: Date()
        )
        
        dataProvider.saveConversation(conversation)
    }
}
