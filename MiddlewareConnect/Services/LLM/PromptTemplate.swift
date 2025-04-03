/**
 * @fileoverview Prompt Templates for LLM interactions
 * @module PromptTemplate
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - Foundation
 * 
 * Exports:
 * - PromptTemplate
 * - SystemPrompts
 * 
 * Notes:
 * - Template system for generating consistent prompts
 * - Includes variable substitution and token estimation
 */

import Foundation

/// A class for managing prompt templates
public class PromptTemplate {
    // MARK: - Properties
    
    /// The template string with placeholders
    public let template: String
    
    /// The token counter
    private let tokenCounter: TokenCounter
    
    // MARK: - Initialization
    
    /// Initializes a new PromptTemplate
    /// - Parameters:
    ///   - template: The template string with placeholders
    ///   - tokenCounter: The token counter to use
    public init(template: String, tokenCounter: TokenCounter = TokenCounter.shared) {
        self.template = template
        self.tokenCounter = tokenCounter
    }
    
    // MARK: - Template Rendering
    
    /// Renders the template with the provided parameters
    /// - Parameter parameters: The parameters to use
    /// - Returns: The rendered template
    /// - Throws: LLMError if rendering fails
    public func render(with parameters: [String: String]) throws -> String {
        var result = template
        
        // Replace all placeholders
        for (key, value) in parameters {
            let placeholder = "{{\(key)}}"
            result = result.replacingOccurrences(of: placeholder, with: value)
        }
        
        // Check if any placeholders remain
        let placeholderRegex = try NSRegularExpression(pattern: "\\{\\{[^\\}]+\\}\\}", options: [])
        let range = NSRange(location: 0, length: result.utf16.count)
        
        if placeholderRegex.firstMatch(in: result, options: [], range: range) != nil {
            throw LLMError.invalidPromptTemplate
        }
        
        return result
    }
    
    /// Estimates the token count of the rendered template
    /// - Parameter parameters: The parameters to use
    /// - Returns: The estimated token count
    /// - Throws: LLMError if estimation fails
    public func estimateTokenCount(with parameters: [String: String]) throws -> Int {
        let rendered = try render(with: parameters)
        return tokenCounter.countTokens(rendered)
    }
}

/// A collection of system prompts for common tasks
public struct SystemPrompts {
    // Common system prompts
    
    /// General assistant prompt
    public static let assistant = """
    You are Claude, a helpful AI assistant. You provide accurate, helpful information and assist users with their tasks in a friendly and professional manner.
    """
    
    /// Summarization prompt
    public static let summarization = """
    You are an expert at summarizing information. Your task is to condense the provided text while preserving the key points and main ideas. Focus on being concise, accurate, and objective.
    """
    
    /// Technical writer prompt
    public static let technicalWriter = """
    You are a technical writing expert. Your task is to explain complex technical concepts clearly and precisely, using appropriate terminology while remaining accessible to the intended audience.
    """
    
    /// Programmer prompt
    public static let programmer = """
    You are an expert programmer with deep knowledge of software development best practices. Your task is to provide clean, efficient, and well-documented code that solves the user's problem.
    """
    
    /// Document analyzer prompt
    public static let documentAnalyzer = """
    You are an expert document analyzer. Your task is to examine the provided document and extract key information, identify main themes, and analyze content. Focus on being thorough and objective in your analysis.
    """
    
    /// Meeting assistant prompt
    public static let meetingAssistant = """
    You are a meeting assistant. Your task is to help organize, document, and improve meetings. You can help create agendas, take notes, summarize discussions, extract action items, and provide follow-up reminders.
    """
    
    /// Creative writer prompt
    public static let creativeWriter = """
    You are a creative writing assistant. Your task is to help generate engaging, original content with a strong voice and narrative style. You can help with brainstorming, drafting, and refining creative content.
    """
}

/// A collection of prompt templates for common tasks
public struct PromptTemplates {
    /// A basic chat template
    public static let chat = """
    System: {{system}}
    
    User: {{user}}
    
    Assistant:
    """
    
    /// A document summarization template
    public static let summarize = """
    System: You are a helpful AI assistant. Summarize the following text concisely.
    
    Text to summarize:
    {{text}}
    
    Summary:
    """
    
    /// A question answering template
    public static let questionAnswering = """
    System: You are a helpful AI assistant. Answer the question based on the provided context.
    
    Context:
    {{context}}
    
    Question: {{question}}
    
    Answer:
    """
    
    /// A document analysis template
    public static let documentAnalysis = """
    System: You are a helpful AI assistant. Analyze the following document.
    
    Document:
    {{document}}
    
    Analysis:
    """
    
    /// A code explanation template
    public static let codeExplanation = """
    System: You are an expert programmer. Explain the following code clearly and thoroughly.
    
    ```{{language}}
    {{code}}
    ```
    
    Explanation:
    """
    
    /// A brainstorming template
    public static let brainstorming = """
    System: You are a creative assistant. Generate ideas for the following topic.
    
    Topic: {{topic}}
    
    Number of ideas: {{count}}
    
    Ideas:
    """
    
    /// A meeting notes template
    public static let meetingNotes = """
    System: You are a meeting assistant. Summarize the meeting transcript into organized notes with action items.
    
    Meeting Transcript:
    {{transcript}}
    
    Meeting Notes:
    """
}
