/**
@fileoverview View model for chat functionality
@module ChatViewModel
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- Foundation
- Combine
- SwiftUI
Exports:
- ChatViewModel
/

import Foundation
import Combine
import SwiftUI

/// View model for managing chat conversations
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current messages in the conversation
    @Published var messages: [LLMChatMessage] = []
    
    /// Input message text
    @Published var messageText: String = ""
    
    /// Loading state
    @Published var isGenerating: Bool = false
    
    /// Error state
    @Published var error: Error? = nil
    
    /// Whether to use streaming responses
    @Published var useStreaming: Bool = true
    
    // MARK: - Private Properties
    
    /// LLM service for generating responses
    private let anthropicService = AnthropicService()
    
    /// Current LLM model to use
    private var model: LLMModel
    
    /// System prompt for the conversation
    private var systemPrompt: String?
    
    /// Subscription for API call status
    private var apiCallStatusSubscription: AnyCancellable?
    
    /// Subscription for streaming responses
    private var streamingResponseSubscription: AnyCancellable?
    
    /// Data storage provider
    private let dataProvider: DataProviderProtocol?
    
    /// Conversation ID for storage
    private var conversationId: UUID
    
    /// Cancellables set to store subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initialize with a model and optional system prompt
    init(
        model: LLMModel = .claudeSonnet,
        systemPrompt: String? = nil,
        conversationId: UUID = UUID(),
        dataProvider: DataProviderProtocol? = nil
    ) {
        self.model = model
        self.systemPrompt = systemPrompt
        self.conversationId = conversationId
        self.dataProvider = dataProvider
        
        setupSubscriptions()
        
        // Add system message if provided
        if let systemPrompt = systemPrompt, !systemPrompt.isEmpty {
            messages.append(.system(content: systemPrompt))
        }
        
        // Load conversation if it exists
        loadConversation()
    }
    
    // MARK: - Public Methods
    
    /// Send a message and generate a response
    func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty, !isGenerating else { return }
        
        // Create and add user message
        let userMessage = LLMChatMessage.user(content: trimmedText)
        messages.append(userMessage)
        
        // Clear input field
        messageText = ""
        
        // Add placeholder for assistant response if streaming
        var assistantMessage: LLMChatMessage?
        if useStreaming {
            assistantMessage = LLMChatMessage.streaming()
            messages.append(assistantMessage!)
        }
        
        // Save the updated conversation
        saveConversation()
        
        // Generate response
        isGenerating = true
        generateResponse(for: userMessage, streamingMessage: assistantMessage)
    }
    
    /// Cancel ongoing generation
    func cancelGeneration() {
        if isGenerating {
            anthropicService.cancelStreaming()
            isGenerating = false
            
            // Mark any streaming message as complete
            if let index = messages.firstIndex(where: { $0.isStreaming }) {
                messages[index].isStreaming = false
                messages[index].isComplete = true
                messages[index].content += " [Generation stopped]"
            }
        }
    }
    
    /// Clear the conversation
    func clearConversation() {
        cancelGeneration()
        
        // Keep system message if present
        let systemMessage = messages.first { $0.role == .system }
        messages = systemMessage.map { [$0] } ?? []
        
        // Delete saved conversation
        dataProvider?.deleteConversation(id: conversationId)
    }
    
    /// Change the model
    func changeModel(to newModel: LLMModel) {
        self.model = newModel
    }
    
    /// Update or set the system prompt
    func updateSystemPrompt(_ newPrompt: String) {
        if let index = messages.firstIndex(where: { $0.role == .system }) {
            messages[index].content = newPrompt
        } else if !newPrompt.isEmpty {
            messages.insert(.system(content: newPrompt), at: 0)
        }
        
        systemPrompt = newPrompt
        saveConversation()
    }
    
    // MARK: - Private Methods
    
    /// Set up subscriptions to API status and streaming responses
    private func setupSubscriptions() {
        // Subscribe to API call status
        apiCallStatusSubscription = anthropicService.apiCallStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                
                switch status {
                case .completed, .streamingCompleted:
                    self.isGenerating = false
                case .failed(let error):
                    self.isGenerating = false
                    self.error = error
                case .inProgress, .streaming:
                    self.isGenerating = true
                }
            }
        
        // Subscribe to streaming responses
        streamingResponseSubscription = anthropicService.streamingResponse
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.error = error
                        self?.isGenerating = false
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    self.handleStreamingResponse(response)
                }
            )
    }
    
    /// Generate a response for the given message
    private func generateResponse(for message: LLMChatMessage, streamingMessage: LLMChatMessage?) {
        // Get Claude model corresponding to the selected model
        let claudeModel: Claude3Model = {
            switch model.modelId {
            case "claude-3-opus-20240229", "claude-3-opus-20240307":
                return .opus
            case "claude-3-5-sonnet-20250307":
                return .sonnetPlus
            case "claude-3-haiku-20240307":
                return .haiku
            default:
                return .sonnet
            }
        }()
        
        // Get system prompt if any
        let systemMessage = messages.first { $0.role == .system }
        let sysPrompt = systemMessage?.content
        
        // Extract messages for the API excluding system message
        let apiMessages = messages.filter { $0.role != .system && !$0.isStreaming }
        
        anthropicService.generateText(
            prompt: message.content,
            model: claudeModel,
            systemPrompt: sysPrompt,
            streaming: useStreaming
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Handle non-streaming response
                    if !self.useStreaming {
                        let assistantMessage = LLMChatMessage.assistant(content: response)
                        self.messages.append(assistantMessage)
                        self.saveConversation()
                    }
                    
                case .failure(let error):
                    self.error = error
                    
                    // Add error message
                    let errorMessage = LLMChatMessage(
                        content: "Error generating response: \(error.localizedDescription)",
                        role: .system
                    )
                    self.messages.append(errorMessage)
                }
                
                self.isGenerating = false
            }
        }
    }
    
    /// Handle streaming response from the API
    private func handleStreamingResponse(_ response: StreamingResponse) {
        // Find the current streaming message if any
        guard let index = messages.firstIndex(where: { $0.isStreaming }) else {
            // If no streaming message exists and we get content, create one
            if !response.content.isEmpty || response.isComplete {
                let newMessage = LLMChatMessage.assistant(
                    content: response.content,
                    isStreaming: !response.isComplete
                )
                messages.append(newMessage)
                
                if response.isComplete {
                    saveConversation()
                }
            }
            return
        }
        
        // Update existing streaming message
        if response.type == .messageDelta || response.type == .contentBlock {
            // Append new content
            messages[index].content += response.content
            messages[index].isStreaming = !response.isComplete
            messages[index].isComplete = response.isComplete
            
            // If complete, save the conversation
            if response.isComplete {
                saveConversation()
            }
        } else if response.type == .messageStop || response.isComplete {
            // Mark as complete
            messages[index].isStreaming = false
            messages[index].isComplete = true
            
            // Save the conversation
            saveConversation()
        }
    }
    
    /// Save the current conversation
    private func saveConversation() {
        // Skip if no data provider
        guard let dataProvider = dataProvider else { return }
        
        // Convert messages to storable format
        let savableMessages = messages.filter { !$0.isStreaming }
        
        // Create conversation object
        let conversation = ChatConversation(
            id: conversationId,
            title: generateTitle(),
            messages: savableMessages,
            model: model,
            lastUpdated: Date()
        )
        
        // Save to storage
        dataProvider.saveConversation(conversation)
    }
    
    /// Load a conversation from storage
    private func loadConversation() {
        guard let dataProvider = dataProvider else { return }
        
        if let conversation = dataProvider.getConversation(id: conversationId) {
            messages = conversation.messages
            model = conversation.model
        }
    }
    
    /// Generate a title for the conversation based on content
    private func generateTitle() -> String {
        // Use first user message as title if available
        if let firstUserMessage = messages.first(where: { $0.role == .user }) {
            let content = firstUserMessage.content
            let maxLength = 30
            
            if content.count <= maxLength {
                return content
            } else {
                let truncated = String(content.prefix(maxLength))
                return "\(truncated)..."
            }
        }
        
        // Fallback to timestamp
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Conversation \(formatter.string(from: Date()))"
    }
}

/// Protocol for data storage providers
protocol DataProviderProtocol {
    func saveConversation(_ conversation: ChatConversation)
    func getConversation(id: UUID) -> ChatConversation?
    func deleteConversation(id: UUID)
    func getAllConversations() -> [ChatConversation]
}

/// Represents a storable chat conversation
struct ChatConversation: Identifiable, Codable {
    var id: UUID
    var title: String
    var messages: [LLMChatMessage]
    var model: LLMModel
    var lastUpdated: Date
}
