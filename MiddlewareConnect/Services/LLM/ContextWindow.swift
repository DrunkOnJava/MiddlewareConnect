/**
 * @fileoverview Context Window management for LLM interactions
 * @module ContextWindow
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * 
 * Exports:
 * - ContextWindow
 * - ContextItem
 * 
 * Notes:
 * - Manages the LLM context window efficiently
 * - Handles context prioritization and truncation
 */

import Foundation
import Combine

/// A class for managing the context window
public class ContextWindow: ObservableObject {
    // MARK: - Properties
    
    /// The maximum size of the context window in tokens
    public let maxContextSize: Int
    
    /// The current token count
    @Published private(set) public var currentTokenCount: Int = 0
    
    /// The reserved tokens for the system message and response
    @Published public var reservedTokens: Int
    
    /// The token counter
    private let tokenCounter: TokenCounter
    
    /// The context items
    @Published private(set) var contextItems: [ContextItem] = []
    
    /// Publisher for context window changes
    private let contextChangedSubject = PassthroughSubject<Void, Never>()
    public var contextChanged: AnyPublisher<Void, Never> {
        return contextChangedSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    /// Initializes a new ContextWindow
    /// - Parameters:
    ///   - modelName: The model name
    ///   - reservedTokens: The reserved tokens for system message and response
    ///   - tokenCounter: The token counter to use
    public init(
        modelName: String = "claude-3-sonnet",
        reservedTokens: Int = 2000,
        tokenCounter: TokenCounter = TokenCounter.shared
    ) {
        self.maxContextSize = tokenCounter.getTokenLimit(forModel: modelName)
        self.reservedTokens = reservedTokens
        self.tokenCounter = tokenCounter
    }
    
    // MARK: - Context Management
    
    /// A context item
    public struct ContextItem: Identifiable {
        /// The unique identifier
        public let id: UUID
        
        /// The item text
        public let text: String
        
        /// The item type (e.g., "message", "document", "summary")
        public let type: String
        
        /// The token count
        public let tokenCount: Int
        
        /// The priority (higher priority items are kept longer)
        public let priority: Int
        
        /// The creation timestamp
        public let timestamp: Date
        
        /// Creates a new context item
        /// - Parameters:
        ///   - text: The item text
        ///   - type: The item type
        ///   - tokenCount: The token count
        ///   - priority: The priority
        public init(
            text: String,
            type: String,
            tokenCount: Int,
            priority: Int,
            timestamp: Date = Date()
        ) {
            self.id = UUID()
            self.text = text
            self.type = type
            self.tokenCount = tokenCount
            self.priority = priority
            self.timestamp = timestamp
        }
    }
    
    /// Adds an item to the context window
    /// - Parameters:
    ///   - text: The item text
    ///   - type: The item type
    ///   - priority: The priority
    /// - Returns: The available context size after adding the item
    /// - Throws: LLMError if the item cannot be added
    @discardableResult
    public func addItem(_ text: String, type: String, priority: Int = 1) throws -> Int {
        let tokenCount = tokenCounter.countTokens(text)
        
        // Check if the item would fit in the context window
        let availableTokens = maxContextSize - currentTokenCount - reservedTokens
        
        if tokenCount > availableTokens {
            // Try to make room for the item
            try makeRoom(for: tokenCount)
        }
        
        // Check again
        let newAvailableTokens = maxContextSize - currentTokenCount - reservedTokens
        
        if tokenCount > newAvailableTokens {
            throw LLMError.contextWindowOverflow(needed: tokenCount, available: newAvailableTokens)
        }
        
        // Add the item
        let item = ContextItem(
            text: text,
            type: type,
            tokenCount: tokenCount,
            priority: priority
        )
        
        contextItems.append(item)
        currentTokenCount += tokenCount
        
        // Notify about the change
        contextChangedSubject.send()
        
        return newAvailableTokens - tokenCount
    }
    
    /// Makes room for a new item by removing low-priority items
    /// - Parameter tokenCount: The token count needed
    /// - Throws: LLMError if room cannot be made
    private func makeRoom(for tokenCount: Int) throws {
        // Sort items by priority (ascending) and then by timestamp (oldest first)
        let sortedItems = contextItems.sorted { item1, item2 in
            if item1.priority == item2.priority {
                return item1.timestamp < item2.timestamp
            }
            return item1.priority < item2.priority
        }
        
        // Calculate how many tokens we need to free
        let neededTokens = tokenCount - (maxContextSize - currentTokenCount - reservedTokens)
        
        if neededTokens <= 0 {
            // We already have enough room
            return
        }
        
        var freedTokens = 0
        var itemsToRemove: [UUID] = []
        
        // Remove items until we have enough room or run out of items
        for item in sortedItems {
            if freedTokens >= neededTokens {
                break
            }
            
            freedTokens += item.tokenCount
            itemsToRemove.append(item.id)
        }
        
        // Remove the items
        contextItems.removeAll { itemsToRemove.contains($0.id) }
        currentTokenCount -= freedTokens
        
        // Notify about the change
        contextChangedSubject.send()
        
        // Check if we made enough room
        if freedTokens < neededTokens {
            throw LLMError.contextWindowOverflow(needed: tokenCount, available: maxContextSize - currentTokenCount - reservedTokens)
        }
    }
    
    /// Clears the context window
    public func clear() {
        contextItems.removeAll()
        currentTokenCount = 0
        
        // Notify about the change
        contextChangedSubject.send()
    }
    
    /// Gets the available context size
    /// - Returns: The available context size in tokens
    public func getAvailableContextSize() -> Int {
        return maxContextSize - currentTokenCount - reservedTokens
    }
    
    /// Gets all context items
    /// - Returns: The context items
    public func getContextItems() -> [ContextItem] {
        return contextItems
    }
    
    /// Gets the context items of a specific type
    /// - Parameter type: The item type
    /// - Returns: The context items
    public func getContextItems(ofType type: String) -> [ContextItem] {
        return contextItems.filter { $0.type == type }
    }
    
    /// Removes a context item
    /// - Parameter id: The item ID
    /// - Returns: True if the item was removed, false otherwise
    @discardableResult
    public func removeItem(id: UUID) -> Bool {
        guard let index = contextItems.firstIndex(where: { $0.id == id }) else {
            return false
        }
        
        let item = contextItems[index]
        contextItems.remove(at: index)
        currentTokenCount -= item.tokenCount
        
        // Notify about the change
        contextChangedSubject.send()
        
        return true
    }
    
    /// Generates a combined context string
    /// - Returns: The combined context
    public func generateCombinedContext() -> String {
        return contextItems.map { $0.text }.joined(separator: "\n\n")
    }
    
    /// Generates a structured context string for Claude
    /// - Returns: The structured context string
    public func generateStructuredContext() -> String {
        // Group items by type
        let groupedItems = Dictionary(grouping: contextItems) { $0.type }
        
        var result = ""
        
        // Add the messages first
        if let messages = groupedItems["message"] {
            let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
            
            for message in sortedMessages {
                // Parse the message to get role and content
                if let separatorRange = message.text.range(of: ": ") {
                    let role = String(message.text[..<separatorRange.lowerBound])
                    let content = String(message.text[separatorRange.upperBound...])
                    
                    result += "\(role): \(content)\n\n"
                } else {
                    result += message.text + "\n\n"
                }
            }
        }
        
        // Add documents
        if let documents = groupedItems["document"] {
            result += "Context Documents:\n\n"
            
            for document in documents {
                result += document.text + "\n\n"
            }
        }
        
        // Add summaries
        if let summaries = groupedItems["summary"] {
            result += "Summaries:\n\n"
            
            for summary in summaries {
                result += summary.text + "\n\n"
            }
        }
        
        // Add other types
        for (type, items) in groupedItems {
            if type == "message" || type == "document" || type == "summary" {
                continue
            }
            
            result += "\(type.capitalized):\n\n"
            
            for item in items {
                result += item.text + "\n\n"
            }
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
