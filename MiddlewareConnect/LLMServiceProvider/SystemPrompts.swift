import Foundation

/// A comprehensive repository of system prompts designed to guide and optimize 
/// language model interactions across diverse computational scenarios.
///
/// This utility provides a centralized, flexible approach to managing system-level 
/// instructions, enabling precise control over model behavior and output generation.
public struct SystemPrompts {
    /// Categories of system prompts to support various computational contexts
    public enum Category {
        /// Analytical and research-oriented prompts
        case analysis
        
        /// Content generation and creative writing
        case generation
        
        /// Technical problem-solving and code-related tasks
        case technicalAssistance
        
        /// Data processing and transformation
        case dataProcessing
        
        /// Language translation and linguistic tasks
        case linguistics
        
        /// Custom category for specialized use cases
        case custom(String)
    }
    
    /// Defines the structure and characteristics of a system prompt template
    public struct PromptTemplate {
        /// Unique identifier for the template
        public let id: String
        
        /// Category of the prompt template
        public let category: Category
        
        /// Primary objective of the prompt
        public let objective: String
        
        /// Detailed system instructions
        public let instructions: String
        
        /// Optional constraints or guidelines
        public let constraints: [String]
        
        /// Recommended output format
        public let outputFormat: String?
        
        /// Version of the prompt template
        public let version: String
        
        /// Creates a comprehensive system prompt template
        /// - Parameters:
        ///   - id: Unique identifier
        ///   - category: Functional category
        ///   - objective: Primary purpose
        ///   - instructions: Detailed guidance
        ///   - constraints: Optional processing constraints
        ///   - outputFormat: Preferred response structure
        ///   - version: Template version
        public init(
            id: String,
            category: Category,
            objective: String,
            instructions: String,
            constraints: [String] = [],
            outputFormat: String? = nil,
            version: String = "1.0.0"
        ) {
            self.id = id
            self.category = category
            self.objective = objective
            self.instructions = instructions
            self.constraints = constraints
            self.outputFormat = outputFormat
            self.version = version
        }
        
        /// Generates a fully composed system prompt
        /// - Returns: Comprehensive system prompt string
        public func compose() -> String {
            var promptComponents = [
                "SYSTEM PROMPT:",
                "ID: \(id)",
                "Version: \(version)",
                "Category: \(categoryDescription)",
                "Objective: \(objective)",
                "",
                "INSTRUCTIONS:",
                instructions
            ]
            
            if !constraints.isEmpty {
                promptComponents.append("")
                promptComponents.append("CONSTRAINTS:")
                promptComponents.append(contentsOf: constraints)
            }
            
            if let outputFormat = outputFormat {
                promptComponents.append("")
                promptComponents.append("OUTPUT FORMAT:")
                promptComponents.append(outputFormat)
            }
            
            return promptComponents.joined(separator: "\n")
        }
        
        /// Provides a human-readable description of the prompt's category
        private var categoryDescription: String {
            switch category {
            case .analysis: return "Analytical Processing"
            case .generation: return "Content Generation"
            case .technicalAssistance: return "Technical Problem Solving"
            case .dataProcessing: return "Data Transformation"
            case .linguistics: return "Linguistic Processing"
            case .custom(let name): return "Custom: \(name)"
            }
        }
    }
    
    /// Predefined system prompt templates for common use cases
    public struct Templates {
        /// Comprehensive document analysis template
        public static let documentAnalysis = PromptTemplate(
            id: "DOC_ANALYSIS_001",
            category: .analysis,
            objective: "Perform in-depth analysis of provided document",
            instructions: """
            You are an expert document analysis assistant. Your task is to:
            1. Extract key information with precision
            2. Identify core themes and insights
            3. Provide a structured, comprehensive summary
            4. Highlight potential areas of further investigation
            
            Analyze the document with a critical and objective approach, 
            maintaining the original context and intent.
            """,
            constraints: [
                "Maintain objectivity",
                "Focus on factual information",
                "Avoid personal interpretation"
            ],
            outputFormat: """
            - Document Overview
              * Title
              * Primary Subject
              * Key Themes
            
            - Detailed Insights
              * Major Findings
              * Contextual Analysis
              * Potential Implications
            
            - Additional Observations
              * Unique Perspectives
              * Recommendations for Further Study
            """
        )
        
        /// Technical code analysis and explanation template
        public static let codeAnalysis = PromptTemplate(
            id: "CODE_ANALYSIS_001",
            category: .technicalAssistance,
            objective: "Comprehensive code analysis and explanation",
            instructions: """
            Perform a multi-dimensional analysis of the provided code:
            1. Identify architectural patterns
            2. Assess code quality and potential improvements
            3. Explain technical implementation details
            4. Suggest optimization strategies
            
            Provide insights that balance theoretical understanding 
            with practical implementation considerations.
            """,
            constraints: [
                "Use clear, technical language",
                "Reference industry best practices",
                "Provide concrete, actionable feedback"
            ],
            outputFormat: """
            - Code Structure
              * Architectural Patterns
              * Dependency Analysis
            
            - Technical Assessment
              * Strengths
              * Potential Improvements
              * Performance Considerations
            
            - Optimization Recommendations
              * Refactoring Suggestions
              * Performance Enhancements
              * Best Practice Alignments
            """
        )
        
        /// Flexible data transformation template
        public static let dataTransformation = PromptTemplate(
            id: "DATA_TRANSFORM_001",
            category: .dataProcessing,
            objective: "Intelligent data transformation and processing",
            instructions: """
            Process and transform input data with intelligent strategies:
            1. Understand input data structure
            2. Apply appropriate transformation techniques
            3. Validate and clean transformed data
            4. Generate comprehensive transformation report
            
            Prioritize data integrity and meaningful transformation.
            """,
            constraints: [
                "Preserve original data semantics",
                "Minimize information loss",
                "Provide transparent transformation logic"
            ],
            outputFormat: """
            - Input Data Analysis
              * Original Structure
              * Identified Patterns
            
            - Transformation Process
              * Applied Techniques
              * Transformation Steps
            
            - Output Data Characteristics
              * New Structure
              * Data Quality Metrics
            
            - Transformation Metadata
              * Conversion Rationale
              * Potential Limitations
            """
        )
    }
    
    /// Registry for managing and retrieving system prompt templates
    public struct Registry {
        /// Internal storage for registered templates
        private var templates: [String: PromptTemplate] = [:]
        
        /// Register a new system prompt template
        /// - Parameter template: Template to register
        public mutating func register(_ template: PromptTemplate) {
            templates[template.id] = template
        }
        
        /// Retrieve a template by its identifier
        /// - Parameter id: Unique template identifier
        /// - Returns: Matching prompt template
        public func template(withId id: String) -> PromptTemplate? {
            return templates[id]
        }
        
        /// Find templates matching a specific category
        /// - Parameter category: Desired template category
        /// - Returns: Array of matching templates
        public func templates(inCategory category: Category) -> [PromptTemplate] {
            return templates.values.filter { $0.category == category }
        }
    }
}

// MARK: - Codable Support
extension SystemPrompts.Category: Codable {}
extension SystemPrompts.PromptTemplate: Codable {}
