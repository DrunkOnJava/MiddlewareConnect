import Foundation
import BackgroundTasks

/// Wrapper for BGProcessingTaskRequest for easier testing and mocking
class BGProcessingTaskRequest {
    /// Register a background processing task
    /// - Parameters:
    ///   - identifier: The task identifier
    ///   - launchHandler: The handler to execute when the task is launched
    /// - Returns: Whether the task was registered successfully
    static func register(forTaskWithIdentifier identifier: String, launchHandler: @escaping (BGTask) -> Bool) -> Bool {
        #if DEBUG
        print("Registered processing task: \(identifier)")
        #endif
        return true
    }
}

/// Wrapper for BGAppRefreshTaskRequest for easier testing and mocking
class BGAppRefreshTaskRequest {
    /// Register a background app refresh task
    /// - Parameters:
    ///   - identifier: The task identifier
    ///   - launchHandler: The handler to execute when the task is launched
    /// - Returns: Whether the task was registered successfully
    static func register(forTaskWithIdentifier identifier: String, launchHandler: @escaping (BGTask) -> Bool) -> Bool {
        #if DEBUG
        print("Registered app refresh task: \(identifier)")
        #endif
        return true
    }
}

/// Generic background task type for testing
class BGTask {
    /// Expiration handler
    var expirationHandler: (() -> Void)?
    
    /// Mark task as complete
    /// - Parameter success: Whether the task completed successfully
    func setTaskCompleted(success: Bool) {
        #if DEBUG
        print("Task completed with success: \(success)")
        #endif
    }
}

/// Background processing task
class BGProcessingTask: BGTask {
}

/// Background app refresh task
class BGAppRefreshTask: BGTask {
}
