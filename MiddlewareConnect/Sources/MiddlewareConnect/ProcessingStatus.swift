import Foundation

/// Manages the status and lifecycle of document and prompt processing
///
/// Provides a robust, type-safe mechanism for tracking the progression of 
/// computational tasks across the MiddlewareConnect ecosystem.
public enum ProcessingStatus {
    /// Document Processing Status
    /// Represents the comprehensive state of document analysis and transformation
    public enum DocumentProcessing {
        /// Initial state when a document is first received
        case received
        
        /// Document is queued for processing
        case queued
        
        /// Preprocessing tasks are in progress
        case preprocessing
        
        /// Text extraction is underway
        case extracting
        
        /// Chunking or segmentation of document content
        case chunking
        
        /// Analysis and feature extraction in progress
        case analyzing
        
        /// Token counting and context window management
        case tokenizing
        
        /// Successful completion of processing
        case completed
        
        /// Processing encountered a recoverable issue
        case paused
        
        /// Processing failed due to an unrecoverable error
        case failed(reason: ErrorReason)
        
        /// Determines if the current status represents a terminal state
        public var isFinal: Bool {
            switch self {
            case .completed, .failed:
                return true
            default:
                return false
            }
        }
        
        /// Provides a descriptive string representation of the current status
        public var description: String {
            switch self {
            case .received: return "Document received"
            case .queued: return "Queued for processing"
            case .preprocessing: return "Preprocessing document"
            case .extracting: return "Extracting text content"
            case .chunking: return "Segmenting document"
            case .analyzing: return "Performing content analysis"
            case .tokenizing: return "Managing token context"
            case .completed: return "Processing completed successfully"
            case .paused: return "Processing temporarily halted"
            case .failed(let reason): return "Processing failed: \(reason.description)"
            }
        }
    }
    
    /// Prompt Processing Status
    /// Tracks the lifecycle of prompt generation and transformation
    public enum PromptProcessing {
        /// Initial prompt construction begins
        case initializing
        
        /// Applying system-level context and instructions
        case contextEnrichment
        
        /// Refining and optimizing prompt structure
        case formatting
        
        /// Token-level optimization
        case tokenOptimization
        
        /// Preparing prompt for model submission
        case finalizing
        
        /// Prompt is ready for model processing
        case ready
        
        /// Prompt processing completed
        case completed
        
        /// Encountered an issue during prompt preparation
        case failed(reason: ErrorReason)
        
        /// Checks if the status represents a final state
        public var isFinal: Bool {
            switch self {
            case .completed, .failed:
                return true
            default:
                return false
            }
        }
        
        /// Generates a human-readable status description
        public var description: String {
            switch self {
            case .initializing: return "Initializing prompt"
            case .contextEnrichment: return "Enhancing prompt context"
            case .formatting: return "Structuring prompt"
            case .tokenOptimization: return "Optimizing token usage"
            case .finalizing: return "Preparing prompt for submission"
            case .ready: return "Prompt ready for processing"
            case .completed: return "Prompt processing completed"
            case .failed(let reason): return "Prompt processing failed: \(reason.description)"
            }
        }
    }
    
    /// Represents specific reasons for processing failures
    public struct ErrorReason: Error, CustomStringConvertible {
        /// Unique error identifier
        public let code: String
        
        /// Detailed error message
        public let message: String
        
        /// Provides a comprehensive description of the error
        public var description: String {
            return "\(code): \(message)"
        }
        
        /// Common predefined error reasons
        public static let documentTooLarge = ErrorReason(
            code: "DOC_LARGE_001",
            message: "Document exceeds maximum supported size"
        )
        
        public static let unsupportedFormat = ErrorReason(
            code: "DOC_FORMAT_002",
            message: "Unsupported document format"
        )
        
        public static let tokenizationFailure = ErrorReason(
            code: "PROC_TOKEN_003",
            message: "Failed to tokenize content"
        )
        
        public static let contextWindowExceeded = ErrorReason(
            code: "PROC_CONTEXT_004",
            message: "Context window limit exceeded"
        )
        
        public static let modelCompatibilityIssue = ErrorReason(
            code: "MODEL_COMPAT_005",
            message: "Incompatible model configuration"
        )
    }
    
    /// Transition validation for document processing
    /// - Parameters:
    ///   - from: Current processing state
    ///   - to: Proposed next state
    /// - Returns: Boolean indicating if the transition is valid
    public static func isValidTransition(
        from currentState: DocumentProcessing,
        to nextState: DocumentProcessing
    ) -> Bool {
        switch (currentState, nextState) {
        case (.received, .queued): return true
        case (.queued, .preprocessing): return true
        case (.preprocessing, .extracting): return true
        case (.extracting, .chunking): return true
        case (.chunking, .analyzing): return true
        case (.analyzing, .tokenizing): return true
        case (.tokenizing, .completed): return true
        case (_, .paused): return true
        case (_, .failed): return true
        default: return false
        }
    }
    
    /// Transition validation for prompt processing
    /// - Parameters:
    ///   - from: Current processing state
    ///   - to: Proposed next state
    /// - Returns: Boolean indicating if the transition is valid
    public static func isValidTransition(
        from currentState: PromptProcessing,
        to nextState: PromptProcessing
    ) -> Bool {
        switch (currentState, nextState) {
        case (.initializing, .contextEnrichment): return true
        case (.contextEnrichment, .formatting): return true
        case (.formatting, .tokenOptimization): return true
        case (.tokenOptimization, .finalizing): return true
        case (.finalizing, .ready): return true
        case (.ready, .completed): return true
        case (_, .failed): return true
        default: return false
        }
    }
}

// MARK: - Extension for Codable Support
extension ProcessingStatus.DocumentProcessing: Codable {}
extension ProcessingStatus.PromptProcessing: Codable {}
extension ProcessingStatus.ErrorReason: Codable {}
