/**
 * @fileoverview Unit tests for TextChunker
 * @module TextChunkerTests
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - XCTest
 * - LLMServiceProvider
 * 
 * Tests:
 * - Different chunking strategies
 * - Edge cases
 * - Error handling
 */

import XCTest
@testable import LLMServiceProvider

final class TextChunkerTests: XCTestCase {
    
    // MARK: - Properties
    
    /// TextChunker instance
    private var textChunker: TextChunker!
    
    /// Test text
    private let testText = """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore
    magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
    consequat.

    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
    Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

    Curabitur pretium tincidunt lacus. Nulla gravida orci a odio. Nullam varius, turpis et commodo pharetra, est
    eros bibendum elit, nec luctus magna felis sollicitudin mauris. Integer in mauris eu nibh euismod gravida.
    """
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        textChunker = TextChunker(maxChunkSize: 100)
    }
    
    override func tearDown() {
        textChunker = nil
        super.tearDown()
    }
    
    // MARK: - Fixed Size Chunking Tests
    
    func testFixedSizeChunking() throws {
        // Test chunking by fixed size
        let chunkSize = 50
        let chunks = try textChunker.chunkText(testText, strategy: .fixed(chunkSize))
        
        XCTAssertFalse(chunks.isEmpty, "Should return non-empty chunks")
        
        // Verify chunk sizes are reasonable
        for chunk in chunks {
            let chunkTokenCount = TokenCounter.shared.countTokens(chunk)
            XCTAssertLessThanOrEqual(chunkTokenCount, chunkSize, "Each chunk should be at most the specified size")
        }
    }
    
    func testFixedSizeWithSmallLimit() throws {
        // Test with very small chunk size
        let chunkSize = 5
        let chunks = try textChunker.chunkText(testText, strategy: .fixed(chunkSize))
        
        XCTAssertFalse(chunks.isEmpty, "Should return non-empty chunks")
        
        // Check if we have many small chunks
        XCTAssertGreaterThan(chunks.count, 5, "Small chunk size should result in many chunks")
    }
    
    func testFixedSizeWithHugeLimit() throws {
        // Test with very large chunk size
        let chunkSize = 10000
        let chunks = try textChunker.chunkText(testText, strategy: .fixed(chunkSize))
        
        XCTAssertEqual(chunks.count, 1, "Huge chunk size should result in a single chunk")
        XCTAssertEqual(chunks.first, testText, "The single chunk should contain the entire text")
    }
    
    // MARK: - Paragraph Chunking Tests
    
    func testParagraphChunking() throws {
        // Test chunking by paragraph
        let chunks = try textChunker.chunkText(testText, strategy: .paragraph)
        
        // Verify we get the expected number of paragraphs
        XCTAssertEqual(chunks.count, 3, "Should split into 3 paragraphs")
    }
    
    func testParagraphChunkingWithSingleParagraph() throws {
        // Test with text that has no paragraph breaks
        let singleParagraphText = "This is a single paragraph without any line breaks. It should be treated as one chunk when using paragraph chunking strategy."
        
        let chunks = try textChunker.chunkText(singleParagraphText, strategy: .paragraph)
        
        XCTAssertEqual(chunks.count, 1, "Single paragraph should result in one chunk")
        XCTAssertEqual(chunks.first, singleParagraphText, "The chunk should match the input text")
    }
    
    // MARK: - Sentence Chunking Tests
    
    func testSentenceChunking() throws {
        // Test chunking by sentence
        let chunks = try textChunker.chunkText(testText, strategy: .sentence)
        
        // Verify we get multiple sentence chunks
        XCTAssertGreaterThan(chunks.count, 3, "Should split into multiple sentences")
        
        // Check if sentences end with proper punctuation
        for chunk in chunks {
            let trimmed = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let lastChar = trimmed.last!
                XCTAssertTrue([".","!","?"].contains(lastChar), "Sentence should end with proper punctuation")
            }
        }
    }
    
    // MARK: - Semantic Chunking Tests
    
    func testSemanticChunking() throws {
        // Test chunking by semantic boundaries
        let chunks = try textChunker.chunkText(testText, strategy: .semantic)
        
        XCTAssertFalse(chunks.isEmpty, "Semantic chunking should return non-empty chunks")
        
        // This is more of a smoke test since semantic chunking is complex
        // More specific assertions would depend on the semantic algorithm used
    }
    
    // MARK: - Sliding Window Tests
    
    func testSlidingWindowChunking() throws {
        // Test chunking with sliding window
        let size = 50
        let overlap = 10
        let chunks = try textChunker.chunkText(testText, strategy: .sliding(size, overlap))
        
        XCTAssertFalse(chunks.isEmpty, "Sliding window chunking should return non-empty chunks")
        
        // Verify we have overlapping chunks
        if chunks.count > 1 {
            let firstChunk = chunks[0]
            let secondChunk = chunks[1]
            
            // The first part of the second chunk should appear at the end of the first chunk
            let firstChunkSuffix = String(firstChunk.suffix(overlap * 2)) // Using approximation since tokens != characters
            let secondChunkPrefix = String(secondChunk.prefix(overlap * 2))
            
            // Check that there's some overlap between chunks
            XCTAssertTrue(
                firstChunkSuffix.contains(secondChunkPrefix) || secondChunkPrefix.contains(firstChunkSuffix),
                "Adjacent chunks should have some overlap"
            )
        }
    }
    
    func testInvalidSlidingWindowParameters() {
        // Test that invalid sliding window parameters throw an error
        let size = 10
        let overlap = 15 // Overlap > size is invalid
        
        XCTAssertThrowsError(try textChunker.chunkText(testText, strategy: .sliding(size, overlap))) { error in
            XCTAssertTrue(error is LLMError, "Should throw LLMError")
            if let llmError = error as? LLMError {
                switch llmError {
                case .invalidParameter(let name, _):
                    XCTAssertEqual(name, "overlap", "Should indicate the overlap parameter is invalid")
                default:
                    XCTFail("Should throw invalidParameter error")
                }
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyText() throws {
        // Test with empty text
        let emptyText = ""
        
        // Test with different strategies
        let fixedChunks = try textChunker.chunkText(emptyText, strategy: .fixed(10))
        let paragraphChunks = try textChunker.chunkText(emptyText, strategy: .paragraph)
        let sentenceChunks = try textChunker.chunkText(emptyText, strategy: .sentence)
        
        XCTAssertEqual(fixedChunks.count, 0, "Empty text should result in no fixed-size chunks")
        XCTAssertEqual(paragraphChunks.count, 0, "Empty text should result in no paragraph chunks")
        XCTAssertEqual(sentenceChunks.count, 0, "Empty text should result in no sentence chunks")
    }
    
    func testVeryLargeText() throws {
        // Test with very large text (simulated)
        let largeText = String(repeating: testText, count: 10)
        
        // Use a small chunk size to test chunking behavior
        let chunks = try textChunker.chunkText(largeText, strategy: .fixed(20))
        
        XCTAssertGreaterThan(chunks.count, 10, "Large text should result in many chunks")
    }
    
    // MARK: - Performance Tests
    
    func testChunkingPerformance() throws {
        // Simple performance test
        let largeText = String(repeating: testText, count: 100)
        
        measure {
            do {
                _ = try textChunker.chunkText(largeText, strategy: .fixed(100))
            } catch {
                XCTFail("Chunking failed with error: \(error)")
            }
        }
    }
}
