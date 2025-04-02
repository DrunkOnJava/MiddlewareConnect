/**
 * @fileoverview SwiftUI View extension for error handling
 * @module View+ErrorAlert
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - View extensions for standardized error handling
 * - AppError struct for consistent error representation
 * - ErrorAlertModifier for showing alerts
 * - ErrorToastModifier for non-modal error notifications
 * - NetworkErrorModifier for offline status handling
 * 
 * Notes:
 * - Provides a consistent way to display error messages across the app
 * - Includes comprehensive error context and recovery suggestions
 */

import SwiftUI

/// Error types for consistent error presentation
enum AppErrorType {
    case warning
    case critical
    case informational
    
    var title: String {
        switch self {
        case .warning: return "Warning"
        case .critical: return "Error"
        case .informational: return "Information"
        }
    }
    
    var iconName: String {
        switch self {
        case .warning: return "exclamationmark.triangle"
        case .critical: return "xmark.octagon"
        case .informational: return "info.circle"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .warning: return .yellow
        case .critical: return .red
        case .informational: return .blue
        }
    }
}

/// Represents an app error with additional context
struct AppError: Error, Identifiable {
    let id = UUID()
    let underlyingError: Error
    let type: AppErrorType
    let userMessage: String
    let recoverySuggestion: String?
    let retryAction: (() -> Void)?
    
    init(
        _ error: Error,
        type: AppErrorType = .critical,
        userMessage: String? = nil,
        recoverySuggestion: String? = nil,
        retryAction: (() -> Void)? = nil
    ) {
        self.underlyingError = error
        self.type = type
        self.userMessage = userMessage ?? error.localizedDescription
        self.recoverySuggestion = recoverySuggestion
        self.retryAction = retryAction
    }
}

/// Centralized error logging service
class ErrorLogService {
    static let shared = ErrorLogService()
    
    private init() {}
    
    func logError(_ error: AppError) {
        // Log to analytics, crash reporting service, or local logs
        #if DEBUG
        print("Error logged: \(error.userMessage)")
        print("Underlying error: \(error.underlyingError)")
        #endif
        
        // In a real implementation, this would send to a service like Firebase Crashlytics
    }
}

/// View extension for standardized error handling
extension View {
    /// Display an error alert
    /// - Parameters:
    ///   - error: Binding to the AppError to display
    ///   - onDismiss: Optional closure to execute when the alert is dismissed
    /// - Returns: Modified view with error alert capability
    func errorAlert(
        error: Binding<AppError?>,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        self.modifier(ErrorAlertModifier(error: error, onDismiss: onDismiss))
    }
    
    /// Present a temporary error message as a toast-style notification
    /// - Parameter error: Binding to the AppError to display
    /// - Returns: Modified view with error toast capability
    func errorToast(error: Binding<AppError?>) -> some View {
        self.modifier(ErrorToastModifier(error: error))
    }
    
    /// Handle network connectivity errors with appropriate UI
    /// - Parameter isOffline: Binding to the network connectivity state
    /// - Returns: Modified view with network error handling capability
    func networkErrorAware(isOffline: Binding<Bool>) -> some View {
        self.modifier(NetworkErrorModifier(isOffline: isOffline))
    }
    
    /// Legacy error alert support (for backward compatibility)
    func errorAlert(error: Binding<Error?>, showError: Binding<Bool>) -> some View {
        return self.alert(isPresented: showError) {
            Alert(
                title: Text("Error"),
                message: Text(error.wrappedValue?.localizedDescription ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

/// Modifier that shows an alert for errors with different styles based on the error type
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?
    var onDismiss: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(item: $error) { appError in
                // Log the error
                ErrorLogService.shared.logError(appError)
                
                var buttons = [Alert.Button]()
                
                // Dismiss button
                buttons.append(.default(Text("OK")) {
                    error = nil
                    onDismiss?()
                })
                
                // Add retry button if there's a retry action
                if let retryAction = appError.retryAction {
                    buttons.append(.default(Text("Retry")) {
                        error = nil
                        retryAction()
                    })
                }
                
                // Add relevant action buttons based on error type
                switch appError.type {
                case .critical:
                    buttons.append(.default(Text("Report")) {
                        // Implementation for reporting critical errors
                        error = nil
                    })
                case .warning, .informational:
                    // No additional actions for warnings and informational messages
                    break
                }
                
                var message: Text
                if let recoverySuggestion = appError.recoverySuggestion {
                    message = Text("\(appError.userMessage)\n\n\(recoverySuggestion)")
                } else {
                    message = Text(appError.userMessage)
                }
                
                return Alert(
                    title: Text(appError.type.title),
                    message: message,
                    buttons: buttons
                )
            }
    }
}

/// Displays a toast-style notification for temporary error messages
struct ErrorToastModifier: ViewModifier {
    @Binding var error: AppError?
    @State private var showingToast = false
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if showingToast, let appError = error {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: appError.type.iconName)
                            .foregroundColor(appError.type.iconColor)
                        
                        Text(appError.userMessage)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if appError.retryAction != nil {
                            Button("Retry") {
                                appError.retryAction?()
                                withAnimation {
                                    showingToast = false
                                    error = nil
                                }
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        Button {
                            withAnimation {
                                showingToast = false
                                error = nil
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
                    )
                    .padding()
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: showingToast)
                .onAppear {
                    // Automatically dismiss after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation {
                            showingToast = false
                            error = nil
                        }
                    }
                }
            }
        }
        .onChange(of: error) { newError in
            if newError != nil {
                ErrorLogService.shared.logError(newError!)
                withAnimation {
                    showingToast = true
                }
            }
        }
    }
}

/// Displays a banner for offline status and handles network-related UI adjustments
struct NetworkErrorModifier: ViewModifier {
    @Binding var isOffline: Bool
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if isOffline {
                VStack {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.white)
                        
                        Text("You're offline")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Retry") {
                            // Attempt to reconnect or refresh connectivity status
                            checkNetworkConnectivity()
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color.orange)
                .transition(.move(edge: .top))
            }
            
            content
                .disabled(isOffline) // Optional: disable interactions when offline
        }
        .animation(.default, value: isOffline)
    }
    
    private func checkNetworkConnectivity() {
        // Implementation to check network connectivity
        // This would use a real network monitoring service in a complete implementation
        
        // Simulate network check for this example
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Sample connectivity check result
            isOffline = false
        }
    }
}
