/**
 * @fileoverview Summary length enum for document summarization
 * @module SummaryLength
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - Foundation
 * 
 * Exports:
 * - SummaryLength enum
 * 
 * Notes:
 * - Used by LLM services to specify summary length preference
 */

import Foundation

/// Enum representing different summary length options
enum SummaryLength: String, CaseIterable, Identifiable {
    /// Brief summary (1-2 paragraphs)
    case brief
    
    /// Moderate summary (3-5 paragraphs)
    case moderate
    
    /// Detailed summary (comprehensive coverage)
    case detailed
    
    /// Identifiable requirement
    var id: String { self.rawValue }
    
    /// Display name for the UI
    var displayName: String {
        switch self {
        case .brief:
            return "Brief"
        case .moderate:
            return "Moderate"
        case .detailed:
            return "Detailed"
        }
    }
    
    /// Description of the summary length for the UI
    var description: String {
        switch self {
        case .brief:
            return "A concise overview in 1-2 paragraphs (about 100-150 words)"
        case .moderate:
            return "A balanced summary in 3-5 paragraphs (about 250-350 words)"
        case .detailed:
            return "A comprehensive summary with full details (500+ words)"
        }
    }
    
    /// Target word count for the summary
    var targetWordCount: Int {
        switch self {
        case .brief:
            return 150
        case .moderate:
            return 300
        case .detailed:
            return 600
        }
    }
}