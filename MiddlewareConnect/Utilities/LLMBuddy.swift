/**
 * @fileoverview LLMBuddy namespace for app-wide utilities and error types
 * @module LLMBuddy
 * 
 * Created: 2025-03-29
 * Last Modified: 2025-03-29
 * 
 * Dependencies:
 * - Foundation
 * 
 * Exports:
 * - LLMBuddy namespace
 * - PDFError enum
 */

import Foundation

/// Namespace for app-specific utilities and error types
enum LLMBuddy {
    /// Errors related to PDF operations
    enum PDFError: Error, Equatable {
        /// Failed to open a PDF file at the specified URL
        case failedToOpenPDF(url: URL)
        
        /// Failed to save a PDF file
        case failedToSavePDF
        
        /// Invalid page indices specified
        case invalidPageIndices
        
        /// Invalid page range specified
        case invalidPageRange
        
        /// Required for Equatable conformance
        static func == (lhs: PDFError, rhs: PDFError) -> Bool {
            switch (lhs, rhs) {
            case (.failedToOpenPDF(let lhsURL), .failedToOpenPDF(let rhsURL)):
                return lhsURL == rhsURL
            case (.failedToSavePDF, .failedToSavePDF):
                return true
            case (.invalidPageIndices, .invalidPageIndices):
                return true
            case (.invalidPageRange, .invalidPageRange):
                return true
            default:
                return false
            }
        }
    }
    
    /// Constants used throughout the app
    enum Constants {
        /// App name
        static let appName = "LLM Buddy"
        
        /// App version
        static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        /// App build number
        static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        /// Default chunk size for text processing
        static let defaultChunkSize = 4000
        
        /// Default overlap for text chunking
        static let defaultOverlap = 200
    }
    
    /// Date formatters used in the app
    enum DateFormatters {
        /// Standard date formatter (e.g., "Mar 29, 2025")
        static let standard: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter
        }()
        
        /// Date and time formatter (e.g., "Mar 29, 2025, 3:14 PM")
        static let dateAndTime: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter
        }()
    }
}

/// Extensions for PDFError
extension LLMBuddy.PDFError: LocalizedError {
    /// User-facing error description
    var errorDescription: String? {
        switch self {
        case .failedToOpenPDF(let url):
            return "Failed to open PDF file: \(url.lastPathComponent)"
        case .failedToSavePDF:
            return "Failed to save PDF file"
        case .invalidPageIndices:
            return "Invalid page indices selected"
        case .invalidPageRange:
            return "Invalid page range selected"
        }
    }
}
