import Foundation
import SwiftUI
import PDFKit

// AnthropicError definition - workaround to avoid import issues
enum AnthropicError: Error {
    case missingApiKey
    case apiError(statusCode: Int, message: String)
    case emptyResponse
    case invalidModel(provider: String)
}

// Forward declaration to use existing error types
struct DummyPDFError: Error {
    let url: URL
}

// Forward declaration for LLMBuddy namespace to avoid redefinition issues
enum LLMBuddy {
    enum PDFError: Error {
        case failedToOpenPDF(url: URL)
        case failedToSavePDF
        case invalidPageIndices
        case invalidPageRange
        case noPDFsSelected
        case documentTooLarge
    }
}

/// Service for handling errors throughout the app
class ErrorHandlingService {
    static let shared = ErrorHandlingService()
    
    private init() {}
    
    /// Handle an error and return a user-friendly error message
    /// - Parameter error: The error to handle
    /// - Returns: A user-friendly error message
    func handleError(_ error: Error) -> String {
        // Log the error
        logError(error)
        
        // Return a user-friendly error message based on the error type
        if let anthropicError = error as? AnthropicError {
            return handleAnthropicError(anthropicError)
        } else if let pdfError = error as? LLMBuddy.PDFError {
            return handlePDFError(pdfError)
        } else if let urlError = error as? URLError {
            return handleURLError(urlError)
        } else {
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    /// Log an error for debugging purposes
    /// - Parameter error: The error to log
    private func logError(_ error: Error) {
        #if DEBUG
        print("🔴 ERROR: \(error.localizedDescription)")
        if let nsError = error as NSError? {
            print("Domain: \(nsError.domain), Code: \(nsError.code)")
            if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                print("Underlying error: \(underlyingError)")
            }
        }
        #endif
        
        // In a real app, you might send this to a logging service
    }
    
    /// Handle Anthropic API errors
    /// - Parameter error: The Anthropic error
    /// - Returns: A user-friendly error message
    private func handleAnthropicError(_ error: AnthropicError) -> String {
        switch error {
        case .missingApiKey:
            return "Please set up your API key in the settings."
        case .apiError(let statusCode, _):
            switch statusCode {
            case 401:
                return "Invalid API key. Please check your API key in the settings."
            case 429:
                return "API rate limit exceeded. Please try again later."
            case 500...599:
                return "The API service is currently unavailable. Please try again later."
            default:
                return "An API error occurred. Please try again later."
            }
        case .emptyResponse:
            return "The API returned an empty response. Please try again."
        case .invalidModel(let provider):
            return "The selected model from \(provider) is not supported by this service. Please choose a different model."
        }
    }
    
    /// Handle PDF errors
    /// - Parameter error: The PDF error
    /// - Returns: A user-friendly error message
    private func handlePDFError(_ error: LLMBuddy.PDFError) -> String {
        switch error {
        case .failedToOpenPDF(let url):
            return "Failed to open PDF: \(url.lastPathComponent)"
        case .failedToSavePDF:
            return "Failed to save PDF. Please check if you have enough storage space."
        case .invalidPageIndices:
            return "Invalid page indices. Please select valid pages."
        case .invalidPageRange:
            return "Invalid page range. Please select a valid range."
        case .noPDFsSelected:
            return "No PDFs selected. Please select at least one PDF file."
        case .documentTooLarge:
            return "The document is too large to process on this device."
        }
    }
    
    /// Handle URL errors
    /// - Parameter error: The URL error
    /// - Returns: A user-friendly error message
    private func handleURLError(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "No internet connection. Please check your network settings."
        case .timedOut:
            return "The request timed out. Please try again."
        case .cannotFindHost, .cannotConnectToHost:
            return "Cannot connect to the server. Please try again later."
        default:
            return "A network error occurred: \(error.localizedDescription)"
        }
    }
}

/// View modifier to show an error alert
struct ErrorAlert: ViewModifier {
    @Binding var error: Error?
    @Binding var showError: Bool
    
    func body(content: Content) -> some View {
        content
            .alert(
                "Error",
                isPresented: $showError,
                actions: {
                    Button("OK") {
                        error = nil
                        showError = false
                    }
                },
                message: {
                    if let error = error {
                        Text(ErrorHandlingService.shared.handleError(error))
                    } else {
                        Text("An unknown error occurred.")
                    }
                }
            )
    }
}

/// Extension to add the error alert modifier to any view
extension View {
    func errorAlert(error: Binding<Error?>, showError: Binding<Bool>) -> some View {
        modifier(ErrorAlert(error: error, showError: showError))
    }
}
