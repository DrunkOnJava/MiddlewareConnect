/**
 * @fileoverview Unit tests for TokenCounter
 * @module TokenCounterTests
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - XCTest
 * - LLMServiceProvider
 * 
 * Tests:
 * - Basic token counting
 * - Edge cases
 * - Limit validation
 * - Token estimation
 */

import XCTest
@testable import LLMServiceProvider

final class TokenCounterTests: XCTestCase {
    
    // MARK: - Properties
    
    /// TokenCounter instance
    private var tokenCounter: TokenCounter!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        tokenCounter = TokenCounter.shared
    }
    
    override func tearDown() {
        tokenCounter = nil
        super.tearDown()
    }
    
    // MARK: - Basic Token Counting Tests
    
    func testEmptyStringTokenCount() {
        // Test that an empty string returns 0 tokens
        let text = ""
        let count = tokenCounter.countTokens(text)
        
        XCTAssertEqual(count, 0, "Empty string should have 0 tokens")
    }
    
    func testBasicTokenCounting() {
        // Test basic token counting
        let text = "This is a simple test."
        let count = tokenCounter.countTokens(text)
        
        // This is a rough approximation, adjust based on expected algorithm
        XCTAssertGreaterThan(count, 0, "Token count should be greater than 0")
        XCTAssertLessThanOrEqual(count, 10, "Token count should be reasonable for a short sentence")
    }
    
    func testLongTextTokenCounting() {
        // Test token counting for longer text
        let text = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore
        magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
        consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """
        
        let count = tokenCounter.countTokens(text)
        
        // Verify we get a reasonable count for longer text
        XCTAssertGreaterThan(count, 50, "Long text should have many tokens")
        XCTAssertLessThan(count, 500, "Token count should be reasonable for paragraph text")
    }
    
    // MARK: - Edge Case Tests
    
    func testNonEnglishText() {
        // Test token counting for non-English text
        let text = "こんにちは世界" // "Hello world" in Japanese
        let count = tokenCounter.countTokens(text)
        
        // Non-English text may have different token patterns
        XCTAssertGreaterThan(count, 0, "Non-English text should have tokens")
    }
    
    func testSpecialCharacters() {
        // Test token counting with special characters
        let text = "!@#$%^&*()"
        let count = tokenCounter.countTokens(text)
        
        XCTAssertGreaterThan(count, 0, "Special characters should be tokenized")
    }
    
    func testCodeSnippet() {
        // Test token counting with code
        let text = """
        func hello() {
            print("Hello, world!")
            return 42
        }
        """
        
        let count = tokenCounter.countTokens(text)
        
        // Code should be tokenized properly
        XCTAssertGreaterThan(count, 10, "Code snippet should have reasonable token count")
    }
    
    // MARK: - Model Limit Tests
    
    func testGetTokenLimit() {
        // Test getting token limits for different models
        let haikuLimit = tokenCounter.getTokenLimit(forModel: "claude-3-haiku")
        let sonnetLimit = tokenCounter.getTokenLimit(forModel: "claude-3-sonnet")
        let opusLimit = tokenCounter.getTokenLimit(forModel: "claude-3-opus")
        
        XCTAssertGreaterThan(haikuLimit, 0, "Haiku model should have a token limit")
        XCTAssertGreaterThan(sonnetLimit, 0, "Sonnet model should have a token limit")
        XCTAssertGreaterThan(opusLimit, 0, "Opus model should have a token limit")
        
        // Upper models should have same or higher limits than lower ones
        XCTAssertGreaterThanOrEqual(sonnetLimit, haikuLimit, "Sonnet should have at least as many tokens as Haiku")
        XCTAssertGreaterThanOrEqual(opusLimit, sonnetLimit, "Opus should have at least as many tokens as Sonnet")
    }
    
    func testUnknownModelDefaultsToLowestLimit() {
        // Test that unknown model names default to the lowest limit
        let unknownModel = "unknown-model"
        let unknownLimit = tokenCounter.getTokenLimit(forModel: unknownModel)
        let haikuLimit = tokenCounter.getTokenLimit(forModel: "claude-3-haiku")
        
        XCTAssertEqual(unknownLimit, haikuLimit, "Unknown model should default to lowest limit")
    }
    
    // MARK: - Estimation Tests
    
    func testEstimateResponseTokens() {
        // Test response token estimation
        let promptTokens = 100
        let estimated = tokenCounter.estimateResponseTokens(promptTokens: promptTokens)
        
        XCTAssertGreaterThan(estimated, 0, "Estimated response tokens should be greater than 0")
        XCTAssertLessThanOrEqual(estimated, promptTokens * 2, "Estimation should be reasonable")
    }
    
    func testZeroPromptTokensEstimation() {
        // Test estimation with 0 prompt tokens
        let promptTokens = 0
        let estimated = tokenCounter.estimateResponseTokens(promptTokens: promptTokens)
        
        XCTAssertGreaterThanOrEqual(estimated, 0, "Estimated response tokens should be non-negative")
    }
    
    func testLargePromptTokensEstimation() {
        // Test estimation with very large prompt
        let promptTokens = 10000
        let estimated = tokenCounter.estimateResponseTokens(promptTokens: promptTokens)
        
        XCTAssertGreaterThan(estimated, 0, "Estimated response tokens should be greater than 0")
        XCTAssertLessThanOrEqual(estimated, 4000, "Estimation should cap at maximum response length")
    }
}
