/**
@fileoverview Loading state management for async operations
@module LoadingStateManager
Created: 2025-04-01
Last Modified: 2025-04-01
Dependencies:
- SwiftUI
- Combine
Exports:
- LoadingState enum for different loading states
- LoadingStateManager for centralized loading state management
- View extensions for loading overlays
Notes:
- Use this for all async operations to provide consistent UX
- Supports progress tracking and time estimation
/

import SwiftUI
import Combine

/// Represents different types of loading states with progress tracking
enum LoadingState: Equatable {
    case idle
    case loading(progress: Double? = nil, message: String? = nil)
    case success(message: String? = nil)
    case failure(error: Error)
    
    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case let (.loading(lProgress, lMessage), .loading(rProgress, rMessage)):
            return lProgress == rProgress && lMessage == rMessage
        case let (.success(lMessage), .success(rMessage)):
            return lMessage == rMessage
        case (.failure, .failure):
            // Note: We can't compare errors directly, so we just check if both are failure cases
            return true
        default:
            return false
        }
    }
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var progress: Double? {
        if case .loading(let progress, _) = self {
            return progress
        }
        return nil
    }
    
    var message: String? {
        switch self {
        case .loading(_, let message):
            return message
        case .success(let message):
            return message
        default:
            return nil
        }
    }
    
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }
    
    var error: Error? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}

/// Manages loading states for various operations in the app
class LoadingStateManager: ObservableObject {
    @Published var state: LoadingState = .idle
    @Published var timeElapsed: TimeInterval = 0
    @Published var estimatedTimeRemaining: TimeInterval?
    
    private var startTime: Date?
    private var timer: AnyCancellable?
    private var taskCancellable: AnyCancellable?
    
    /// Start a loading operation with an optional message
    func startLoading(message: String? = nil) {
        state = .loading(progress: nil, message: message)
        startTime = Date()
        startTimer()
    }
    
    /// Update the progress of the current loading operation
    /// - Parameters:
    ///   - progress: Progress value between 0 and 1
    ///   - message: Optional updated message
    func updateProgress(_ progress: Double, message: String? = nil) {
        state = .loading(progress: min(max(progress, 0), 1), message: message)
        updateEstimatedTimeRemaining(progress)
    }
    
    /// Mark the current operation as successful
    /// - Parameter message: Optional success message
    func succeed(message: String? = nil) {
        state = .success(message: message)
        stopTimer()
        
        // Automatically reset to idle after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.reset()
        }
    }
    
    /// Mark the current operation as failed
    /// - Parameter error: The error that caused the failure
    func fail(error: Error) {
        state = .failure(error: error)
        stopTimer()
    }
    
    /// Reset to idle state
    func reset() {
        state = .idle
        timeElapsed = 0
        estimatedTimeRemaining = nil
        startTime = nil
        stopTimer()
    }
    
    /// Cancel the current operation
    func cancel() {
        taskCancellable?.cancel()
        reset()
    }
    
    /// Execute an asynchronous task with loading state management
    /// - Parameters:
    ///   - message: Optional loading message
    ///   - task: The async task to execute
    /// - Returns: Publisher that emits the task result or an error
    func executeTask<T>(
        message: String? = nil,
        task: @escaping () async throws -> T
    ) -> AnyPublisher<T, Error> {
        let subject = PassthroughSubject<T, Error>()
        
        startLoading(message: message)
        
        let task = Task {
            do {
                let result = try await task()
                succeed()
                subject.send(result)
                subject.send(completion: .finished)
            } catch {
                fail(error: error)
                subject.send(completion: .failure(error))
            }
        }
        
        taskCancellable = AnyCancellable {
            task.cancel()
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        stopTimer()
        
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let startTime = self.startTime else { return }
                self.timeElapsed = Date().timeIntervalSince(startTime)
            }
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func updateEstimatedTimeRemaining(_ progress: Double) {
        guard progress > 0, let startTime = startTime else {
            estimatedTimeRemaining = nil
            return
        }
        
        let timeElapsed = Date().timeIntervalSince(startTime)
        let timePerPercent = timeElapsed / progress
        estimatedTimeRemaining = timePerPercent * (1 - progress)
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Applies a loading overlay to the view based on the provided loading state
    /// - Parameters:
    ///   - state: The loading state to display
    ///   - allowCancel: Whether to show a cancel button
    ///   - onCancel: Closure to call when cancel is tapped
    /// - Returns: View with loading overlay applied
    func loadingOverlay(
        state: LoadingState, 
        allowCancel: Bool = false, 
        onCancel: (() -> Void)? = nil
    ) -> some View {
        self.modifier(LoadingOverlayModifier(
            state: state, 
            allowCancel: allowCancel, 
            onCancel: onCancel
        ))
    }
    
    /// Provides a loading overlay managed by the specified LoadingStateManager
    /// - Parameters:
    ///   - manager: The loading state manager
    ///   - allowCancel: Whether to show a cancel button
    /// - Returns: View with loading overlay applied
    func loadingOverlay(manager: LoadingStateManager, allowCancel: Bool = false) -> some View {
        self.modifier(ManagedLoadingOverlayModifier(
            manager: manager, 
            allowCancel: allowCancel
        ))
    }
}

/// Modifier that applies a loading overlay based on the current loading state
struct LoadingOverlayModifier: ViewModifier {
    let state: LoadingState
    let allowCancel: Bool
    let onCancel: (() -> Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(state.isLoading)
                .blur(radius: state.isLoading ? 2 : 0)
            
            if state.isLoading {
                loadingView
                    .transition(.opacity)
            }
        }
        .animation(.default, value: state.isLoading)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            if let progress = state.progress {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                
                Text("\(Int(progress * 100))%")
                    .font(.headline)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
            
            if let message = state.message {
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if allowCancel {
                Button("Cancel") {
                    onCancel?()
                }
                .font(.subheadline)
                .foregroundColor(.red)
                .padding(.top)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
        )
        .padding()
    }
}

/// Modifier that applies a loading overlay managed by a LoadingStateManager
struct ManagedLoadingOverlayModifier: ViewModifier {
    @ObservedObject var manager: LoadingStateManager
    let allowCancel: Bool
    
    func body(content: Content) -> some View {
        content.loadingOverlay(
            state: manager.state,
            allowCancel: allowCancel,
            onCancel: manager.cancel
        )
        .overlay(
            Group {
                if manager.state.isLoading, let timeRemaining = manager.estimatedTimeRemaining, timeRemaining > 2 {
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Text("Estimated time: \(formatTime(timeRemaining))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.secondarySystemBackground))
                                )
                            
                            Spacer()
                        }
                        .padding(.bottom)
                    }
                }
            }
        )
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        if timeInterval < 60 {
            return "\(Int(timeInterval)) seconds"
        } else {
            let minutes = Int(timeInterval) / 60
            let seconds = Int(timeInterval) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
}
