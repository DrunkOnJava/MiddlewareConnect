/**
 * @fileoverview Text Chunker for breaking large documents into manageable pieces
 * @module TextChunker
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * - NaturalLanguage
 * 
 * Exports:
 * - TextChunker
 * - ChunkingStrategy
 * 
 * Notes:
 * - Provides various strategies for chunking text
 * - Optimized for document processing workflows
 */

import Foundation
import NaturalLanguage

/// Errors that can occur during LLM tool operations
public enum LLMError: Error {
    case invalidTokenization
    case invalidChunkingStrategy
    case contextWindowOverflow(needed: Int, available: Int)
    case invalidPromptTemplate
    case invalidParameter(name: String, reason: String)
    
    var localizedDescription: String {
        switch self {
        case .invalidTokenization:
            return "Failed to tokenize text."
        case .invalidChunkingStrategy:
            return "Invalid chunking strategy."
        case .contextWindowOverflow(let needed, let available):
            return "Context window overflow: needed \(needed) tokens, but only \(available) available."
        case .invalidPromptTemplate:
            return "Invalid prompt template format."
        case .invalidParameter(let name, let reason):
            return "Invalid parameter '\(name)': \(reason)"
        }
    }
}

/// Strategies for chunking text
public enum ChunkingStrategy {
    case fixed(Int)         // Fixed chunk size in tokens
    case paragraph          // Chunk by paragraphs
    case sentence           // Chunk by sentences
    case semantic           // Chunk by semantic boundaries
    case sliding(Int, Int)  // Sliding window with size and overlap
}

/// A service for chunking text into manageable pieces
public class TextChunker {
    // MARK: - Properties
    
    /// The maximum size of each chunk in tokens
    public var maxChunkSize: Int
    
    /// The token counter
    private let tokenCounter: TokenCounter
    
    // MARK: - Initialization
    
    /// Initializes a new TextChunker
    /// - Parameters:
    ///   - maxChunkSize: The maximum size of each chunk in tokens
    ///   - tokenCounter: The token counter to use
    public init(maxChunkSize: Int = 1000, tokenCounter: TokenCounter = TokenCounter.shared) {
        self.maxChunkSize = maxChunkSize
        self.tokenCounter = tokenCounter
    }
    
    // MARK: - Chunking
    
    /// Chunks text using a specified strategy
    /// - Parameters:
    ///   - text: The text to chunk
    ///   - strategy: The chunking strategy to use
    /// - Returns: An array of text chunks
    /// - Throws: LLMError if chunking fails
    public func chunkText(_ text: String, strategy: ChunkingStrategy) throws -> [String] {
        switch strategy {
        case .fixed(let size):
            return try chunkByFixedSize(text, size: size)
        case .paragraph:
            return chunkByParagraph(text)
        case .sentence:
            return chunkBySentence(text)
        case .semantic:
            return try chunkBySemantic(text)
        case .sliding(let size, let overlap):
            return try chunkBySlidingWindow(text, size: size, overlap: overlap)
        }
    }
    
    /// Chunks text by fixed token size
    /// - Parameters:
    ///   - text: The text to chunk
    ///   - size: The chunk size in tokens
    /// - Returns: An array of text chunks
    /// - Throws: LLMError if chunking fails
    private func chunkByFixedSize(_ text: String, size: Int) throws -> [String] {
        let actualSize = min(size, maxChunkSize)
        
        var chunks: [String] = []
        var currentChunk = ""
        var currentTokenCount = 0
        
        // Split text into sentences for more natural boundaries
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0 + "." }
        
        for sentence in sentences {
            let sentenceTokens = tokenCounter.countTokens(sentence)
            
            if sentenceTokens > actualSize {
                // If a single sentence is too large, split by words
                let words = sentence.components(separatedBy: .whitespacesAndNewlines)
                var wordChunk = ""
                var wordTokenCount = 0
                
                for word in words {
                    let wordTokens = tokenCounter.countTokens(word)
                    
                    if wordTokenCount + wordTokens <= actualSize {
                        wordChunk += word + " "
                        wordTokenCount += wordTokens
                    } else {
                        if !wordChunk.isEmpty {
                            chunks.append(wordChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                        wordChunk = word + " "
                        wordTokenCount = wordTokens
                    }
                }
                
                if !wordChunk.isEmpty {
                    chunks.append(wordChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            } else if currentTokenCount + sentenceTokens <= actualSize {
                currentChunk += sentence + " "
                currentTokenCount += sentenceTokens
            } else {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                currentChunk = sentence + " "
                currentTokenCount = sentenceTokens
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return chunks
    }
    
    /// Chunks text by paragraph
    /// - Parameter text: The text to chunk
    /// - Returns: An array of text chunks
    private func chunkByParagraph(_ text: String) -> [String] {
        var chunks: [String] = []
        var currentChunk = ""
        var currentTokenCount = 0
        
        // Split text into paragraphs
        let paragraphs = text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for paragraph in paragraphs {
            let paragraphTokens = tokenCounter.countTokens(paragraph)
            
            if paragraphTokens > maxChunkSize {
                // If a single paragraph is too large, split it by sentences
                do {
                    let subChunks = try chunkBySentence(paragraph)
                    chunks.append(contentsOf: subChunks)
                } catch {
                    // If sentence chunking fails, use fixed size chunking
                    do {
                        let subChunks = try chunkByFixedSize(paragraph, size: maxChunkSize)
                        chunks.append(contentsOf: subChunks)
                    } catch {
                        // In case of failure, just add the whole paragraph
                        chunks.append(paragraph)
                    }
                }
            } else if currentTokenCount + paragraphTokens <= maxChunkSize {
                currentChunk += paragraph + "\n\n"
                currentTokenCount += paragraphTokens
            } else {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                currentChunk = paragraph + "\n\n"
                currentTokenCount = paragraphTokens
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return chunks
    }
    
    /// Chunks text by sentence
    /// - Parameter text: The text to chunk
    /// - Returns: An array of text chunks
    private func chunkBySentence(_ text: String) -> [String] {
        var chunks: [String] = []
        var currentChunk = ""
        var currentTokenCount = 0
        
        // Use NLTokenizer for sentence tokenization
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        tokenizer.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .tokenType, options: []) { _, tokenRange in
            let sentence = String(text[tokenRange])
            let sentenceTokens = tokenCounter.countTokens(sentence)
            
            if sentenceTokens > maxChunkSize {
                // If a single sentence is too large, split by fixed size
                do {
                    let subChunks = try chunkByFixedSize(sentence, size: maxChunkSize)
                    chunks.append(contentsOf: subChunks)
                } catch {
                    // In case of failure, just add the whole sentence
                    chunks.append(sentence)
                }
            } else if currentTokenCount + sentenceTokens <= maxChunkSize {
                currentChunk += sentence + " "
                currentTokenCount += sentenceTokens
            } else {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                currentChunk = sentence + " "
                currentTokenCount = sentenceTokens
            }
            
            return true
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return chunks
    }
    
    /// Chunks text by semantic boundaries
    /// - Parameter text: The text to chunk
    /// - Returns: An array of text chunks
    /// - Throws: LLMError if chunking fails
    private func chunkBySemantic(_ text: String) throws -> [String] {
        // In a real implementation, this would use a more sophisticated semantic analysis
        // For now, we'll chunk by paragraphs and try to keep related paragraphs together
        
        // First, chunk by paragraph
        let paragraphChunks = chunkByParagraph(text)
        
        // Then, try to combine related paragraphs
        var semanticChunks: [String] = []
        var currentChunk = ""
        var currentTokenCount = 0
        
        for paragraph in paragraphChunks {
            let paragraphTokens = tokenCounter.countTokens(paragraph)
            
            if currentTokenCount + paragraphTokens <= maxChunkSize {
                currentChunk += paragraph + "\n\n"
                currentTokenCount += paragraphTokens
            } else {
                if !currentChunk.isEmpty {
                    semanticChunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                currentChunk = paragraph + "\n\n"
                currentTokenCount = paragraphTokens
            }
        }
        
        if !currentChunk.isEmpty {
            semanticChunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        return semanticChunks
    }
    
    /// Chunks text using a sliding window
    /// - Parameters:
    ///   - text: The text to chunk
    ///   - size: The window size in tokens
    ///   - overlap: The overlap between windows in tokens
    /// - Returns: An array of text chunks
    /// - Throws: LLMError if chunking fails
    private func chunkBySlidingWindow(_ text: String, size: Int, overlap: Int) throws -> [String] {
        if overlap >= size {
            throw LLMError.invalidParameter(name: "overlap", reason: "Overlap must be less than window size")
        }
        
        let actualSize = min(size, maxChunkSize)
        let actualOverlap = min(overlap, actualSize - 1)
        
        // First, split text into sentences
        var sentences: [String] = []
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range])
            sentences.append(sentence)
            return true
        }
        
        // Create sliding windows
        var chunks: [String] = []
        var currentTokenCount = 0
        var currentSentences: [String] = []
        
        for sentence in sentences {
            let sentenceTokens = tokenCounter.countTokens(sentence)
            
            if currentTokenCount + sentenceTokens <= actualSize {
                currentSentences.append(sentence)
                currentTokenCount += sentenceTokens
            } else {
                if !currentSentences.isEmpty {
                    chunks.append(currentSentences.joined(separator: " "))
                    
                    // Remove sentences from the beginning until overlap is satisfied
                    while currentTokenCount > actualOverlap {
                        if let firstSentence = currentSentences.first {
                            let firstTokens = tokenCounter.countTokens(firstSentence)
                            currentSentences.removeFirst()
                            currentTokenCount -= firstTokens
                        } else {
                            break
                        }
                    }
                }
                
                currentSentences.append(sentence)
                currentTokenCount += sentenceTokens
            }
        }
        
        if !currentSentences.isEmpty {
            chunks.append(currentSentences.joined(separator: " "))
        }
        
        return chunks
    }
}
