/**
 * @fileoverview Text chunking service for splitting large texts
 * @module TextChunker
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * 
 * Exports:
 * - TextChunker
 * - ChunkingStrategy
 * - ChunkingResult
 * 
 * Notes:
 * - Provides text chunking functionality for processing large documents
 * - Offers different chunking strategies optimized for different LLM use cases
 * - Includes overlap options to maintain context between chunks
 */

import Foundation

/// Chunking strategies for different types of text
public enum ChunkingStrategy {
    /// Split by character count
    case characters(count: Int)
    
    /// Split by word count
    case words(count: Int)
    
    /// Split by sentence
    case sentences(count: Int)
    
    /// Split by paragraph
    case paragraphs(count: Int)
    
    /// Split by semantic chunks (requires NLP)
    case semantic(tokenLimit: Int)
    
    /// Get a description of the strategy
    public var description: String {
        switch self {
        case .characters(let count):
            return "Characters: \(count) per chunk"
        case .words(let count):
            return "Words: \(count) per chunk"
        case .sentences(let count):
            return "Sentences: \(count) per chunk"
        case .paragraphs(let count):
            return "Paragraphs: \(count) per chunk"
        case .semantic(let tokenLimit):
            return "Semantic: ~\(tokenLimit) tokens per chunk"
        }
    }
}

/// Result of a chunking operation
public struct ChunkingResult {
    /// The chunked text segments
    public let chunks: [String]
    
    /// The strategy used
    public let strategy: ChunkingStrategy
    
    /// The overlap used
    public let overlap: Int
    
    /// Whether to preserve partial units (words, sentences, etc.)
    public let preservePartialUnits: Bool
    
    /// Total original text length
    public let originalLength: Int
    
    /// Initialize a new chunking result
    public init(chunks: [String], strategy: ChunkingStrategy, overlap: Int, preservePartialUnits: Bool, originalLength: Int) {
        self.chunks = chunks
        self.strategy = strategy
        self.overlap = overlap
        self.preservePartialUnits = preservePartialUnits
        self.originalLength = originalLength
    }
    
    /// Get statistics about the chunking
    public var statistics: [String: Any] {
        return [
            "chunkCount": chunks.count,
            "averageChunkLength": chunks.isEmpty ? 0 : chunks.reduce(0) { $0 + $1.count } / chunks.count,
            "minChunkLength": chunks.min(by: { $0.count < $1.count })?.count ?? 0,
            "maxChunkLength": chunks.max(by: { $0.count < $1.count })?.count ?? 0,
            "strategy": strategy.description,
            "overlap": overlap,
            "preservePartialUnits": preservePartialUnits,
            "originalLength": originalLength
        ]
    }
}

/// Service for chunking text for LLM processing
public class TextChunker {
    // MARK: - Properties
    
    /// Shared instance
    public static let shared = TextChunker()
    
    /// Token counter for estimating chunk sizes
    private let tokenCounter = TokenCounter.shared
    
    // MARK: - Methods
    
    /// Chunk text using a specific strategy
    /// - Parameters:
    ///   - text: The text to chunk
    ///   - strategy: Chunking strategy to use
    ///   - overlap: Number of units to overlap between chunks (optional)
    ///   - preservePartialUnits: Whether to preserve partial units at chunk boundaries
    /// - Returns: ChunkingResult with the chunks and metadata
    public func chunkText(_ text: String, 
                         strategy: ChunkingStrategy, 
                         overlap: Int = 0, 
                         preservePartialUnits: Bool = true) -> ChunkingResult {
        
        // Return empty result for empty text
        guard !text.isEmpty else {
            return ChunkingResult(chunks: [], strategy: strategy, overlap: overlap, preservePartialUnits: preservePartialUnits, originalLength: 0)
        }
        
        let chunks: [String]
        
        // Use different chunking methods based on strategy
        switch strategy {
        case .characters(let count):
            chunks = chunkByCharacters(text: text, chunkSize: count, overlap: overlap)
            
        case .words(let count):
            chunks = chunkByWords(text: text, chunkSize: count, overlap: overlap, preservePartialUnits: preservePartialUnits)
            
        case .sentences(let count):
            chunks = chunkBySentences(text: text, chunkSize: count, overlap: overlap)
            
        case .paragraphs(let count):
            chunks = chunkByParagraphs(text: text, chunkSize: count, overlap: overlap)
            
        case .semantic(let tokenLimit):
            chunks = chunkSemantically(text: text, tokenLimit: tokenLimit, overlap: overlap)
        }
        
        return ChunkingResult(
            chunks: chunks,
            strategy: strategy,
            overlap: overlap,
            preservePartialUnits: preservePartialUnits,
            originalLength: text.count
        )
    }
    
    /// Chunk text for a specific LLM model
    /// - Parameters:
    ///   - text: The text to chunk
    ///   - model: The LLM model to chunk for
    ///   - overlapPercentage: Percentage of chunk to overlap (0-100)
    /// - Returns: ChunkingResult with the chunks and metadata
    public func chunkForModel(_ text: String, model: LLMModel, overlapPercentage: Int = 10) -> ChunkingResult {
        // Calculate token limit based on model context window
        // We use 90% of the context window to leave room for the prompt and response
        let tokenLimit = Int(Double(model.maxContextLength) * 0.9)
        
        // Use semantic chunking if we can estimate tokens accurately
        let strategy = ChunkingStrategy.semantic(tokenLimit: tokenLimit)
        
        // Calculate overlap based on percentage
        let overlap = max(1, (tokenLimit * overlapPercentage) / 100)
        
        return chunkText(text, strategy: strategy, overlap: overlap, preservePartialUnits: true)
    }
    
    // MARK: - Private Methods
    
    /// Chunk text by character count
    private func chunkByCharacters(text: String, chunkSize: Int, overlap: Int) -> [String] {
        guard chunkSize > 0 else { return [text] }
        
        var chunks: [String] = []
        var startIndex = text.startIndex
        
        while startIndex < text.endIndex {
            let endDistance = min(chunkSize, text.distance(from: startIndex, to: text.endIndex))
            let endIndex = text.index(startIndex, offsetBy: endDistance)
            
            let chunk = String(text[startIndex..<endIndex])
            chunks.append(chunk)
            
            if endIndex >= text.endIndex {
                break
            }
            
            // Calculate the next start index with overlap
            let overlapDistance = min(overlap, endDistance)
            startIndex = text.index(endIndex, offsetBy: -overlapDistance)
        }
        
        return chunks
    }
    
    /// Chunk text by word count
    private func chunkByWords(text: String, chunkSize: Int, overlap: Int, preservePartialUnits: Bool) -> [String] {
        guard chunkSize > 0 else { return [text] }
        
        // Split text into words
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard !words.isEmpty else { return [text] }
        
        var chunks: [String] = []
        var currentIndex = 0
        
        while currentIndex < words.count {
            let endIndex = min(currentIndex + chunkSize, words.count)
            let chunkWords = Array(words[currentIndex..<endIndex])
            
            // Join the words back into a string
            let chunk = chunkWords.joined(separator: " ")
            chunks.append(chunk)
            
            if endIndex >= words.count {
                break
            }
            
            // Calculate the next start index with overlap
            let overlapCount = min(overlap, chunkSize)
            currentIndex = endIndex - overlapCount
        }
        
        return chunks
    }
    
    /// Chunk text by sentence count
    private func chunkBySentences(text: String, chunkSize: Int, overlap: Int) -> [String] {
        guard chunkSize > 0 else { return [text] }
        
        // Split text into sentences using natural language processing
        let sentences = splitIntoSentences(text)
        guard !sentences.isEmpty else { return [text] }
        
        var chunks: [String] = []
        var currentIndex = 0
        
        while currentIndex < sentences.count {
            let endIndex = min(currentIndex + chunkSize, sentences.count)
            let chunkSentences = Array(sentences[currentIndex..<endIndex])
            
            // Join the sentences into a chunk
            let chunk = chunkSentences.joined(separator: " ")
            chunks.append(chunk)
            
            if endIndex >= sentences.count {
                break
            }
            
            // Calculate the next start index with overlap
            let overlapCount = min(overlap, chunkSize)
            currentIndex = endIndex - overlapCount
        }
        
        return chunks
    }
    
    /// Chunk text by paragraph count
    private func chunkByParagraphs(text: String, chunkSize: Int, overlap: Int) -> [String] {
        guard chunkSize > 0 else { return [text] }
        
        // Split text into paragraphs
        let paragraphs = text.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !paragraphs.isEmpty else { return [text] }
        
        var chunks: [String] = []
        var currentIndex = 0
        
        while currentIndex < paragraphs.count {
            let endIndex = min(currentIndex + chunkSize, paragraphs.count)
            let chunkParagraphs = Array(paragraphs[currentIndex..<endIndex])
            
            // Join the paragraphs into a chunk
            let chunk = chunkParagraphs.joined(separator: "\n\n")
            chunks.append(chunk)
            
            if endIndex >= paragraphs.count {
                break
            }
            
            // Calculate the next start index with overlap
            let overlapCount = min(overlap, chunkSize)
            currentIndex = endIndex - overlapCount
        }
        
        return chunks
    }
    
    /// Chunk text semantically based on token limits
    private func chunkSemantically(text: String, tokenLimit: Int, overlap: Int) -> [String] {
        // This is a simplified implementation that estimates token count
        // A more advanced implementation would use actual tokenizers and semantic understanding
        
        // Split text into paragraphs first
        let paragraphs = text.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !paragraphs.isEmpty else { return [text] }
        
        var chunks: [String] = []
        var currentChunk: [String] = []
        var currentTokenCount = 0
        
        // Use a dummy model for token estimation
        let dummyModel = LLMModel(id: "claude3-sonnet", name: "Claude 3 Sonnet", maxContextLength: 200000, provider: "anthropic")
        
        // Process each paragraph
        for paragraph in paragraphs {
            let paragraphTokens = tokenCounter.countTokens(text: paragraph, model: dummyModel)
            
            // If the paragraph alone exceeds token limit, split it further
            if paragraphTokens > tokenLimit {
                // If we have accumulated content, add it as a chunk
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk.joined(separator: "\n\n"))
                    currentChunk = []
                    currentTokenCount = 0
                }
                
                // Split the paragraph by sentences
                let sentences = splitIntoSentences(paragraph)
                var sentenceChunk: [String] = []
                var sentenceTokenCount = 0
                
                for sentence in sentences {
                    let sentenceTokens = tokenCounter.countTokens(text: sentence, model: dummyModel)
                    
                    // If adding this sentence would exceed the token limit, add the current chunk and start a new one
                    if sentenceTokenCount + sentenceTokens > tokenLimit && !sentenceChunk.isEmpty {
                        chunks.append(sentenceChunk.joined(separator: " "))
                        
                        // Calculate overlap
                        if overlap > 0 {
                            let overlapSentences = min(overlap, sentenceChunk.count)
                            sentenceChunk = Array(sentenceChunk.suffix(overlapSentences))
                            sentenceTokenCount = tokenCounter.countTokens(text: sentenceChunk.joined(separator: " "), model: dummyModel)
                        } else {
                            sentenceChunk = []
                            sentenceTokenCount = 0
                        }
                    }
                    
                    // Add the sentence to the current chunk
                    sentenceChunk.append(sentence)
                    sentenceTokenCount += sentenceTokens
                }
                
                // Add any remaining sentence chunk
                if !sentenceChunk.isEmpty {
                    chunks.append(sentenceChunk.joined(separator: " "))
                }
            }
            // If adding this paragraph would exceed the token limit, add the current chunk and start a new one
            else if currentTokenCount + paragraphTokens > tokenLimit && !currentChunk.isEmpty {
                chunks.append(currentChunk.joined(separator: "\n\n"))
                
                // Calculate overlap
                if overlap > 0 {
                    let overlapParagraphs = min(overlap, currentChunk.count)
                    currentChunk = Array(currentChunk.suffix(overlapParagraphs))
                    currentTokenCount = tokenCounter.countTokens(text: currentChunk.joined(separator: "\n\n"), model: dummyModel)
                } else {
                    currentChunk = []
                    currentTokenCount = 0
                }
                
                // Add the current paragraph
                currentChunk.append(paragraph)
                currentTokenCount += paragraphTokens
            }
            else {
                // Add the paragraph to the current chunk
                currentChunk.append(paragraph)
                currentTokenCount += paragraphTokens
            }
        }
        
        // Add any remaining chunk
        if !currentChunk.isEmpty {
            chunks.append(currentChunk.joined(separator: "\n\n"))
        }
        
        return chunks
    }
    
    /// Split text into sentences
    private func splitIntoSentences(_ text: String) -> [String] {
        // Simple sentence splitting logic
        // A more advanced implementation would use natural language processing
        let sentenceDelimiters = CharacterSet(charactersIn: ".!?")
        var sentences: [String] = []
        
        // Split by potential sentence endings
        let components = text.components(separatedBy: sentenceDelimiters)
        
        // Reconstruct sentences with their delimiters
        var currentIndex = text.startIndex
        
        for component in components {
            if component.isEmpty {
                continue
            }
            
            let startIndex = currentIndex
            let componentRange = text.range(of: component, range: startIndex..<text.endIndex)
            
            guard let range = componentRange else {
                continue
            }
            
            // Find the end of this sentence (including the delimiter)
            var endIndex = range.upperBound
            
            // If we're not at the end of the text, include the delimiter
            if endIndex < text.endIndex {
                endIndex = text.index(after: endIndex)
            }
            
            // Extract the sentence
            let sentence = String(text[startIndex..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !sentence.isEmpty {
                sentences.append(sentence)
            }
            
            currentIndex = endIndex
        }
        
        return sentences
    }
}
