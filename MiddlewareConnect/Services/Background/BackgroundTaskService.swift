import Foundation
import UIKit
import BackgroundTasks

/// Notification names for background tasks
extension Notification.Name {
    static let backgroundTaskDidAdd = Notification.Name("backgroundTaskDidAdd")
    static let backgroundTaskDidComplete = Notification.Name("backgroundTaskDidComplete")
    static let backgroundApiDataDidUpdate = Notification.Name("backgroundApiDataDidUpdate")
}

/// Service for managing background tasks
class BackgroundTaskService {
    // Singleton instance
    static let shared = BackgroundTaskService()
    
    // Dictionary to store completion handlers for operations
    private var completionHandlers: [String: (Bool) -> Void] = [:]
    
    private init() {}
    
    /// Add a background task
    /// - Parameters:
    ///   - operationId: The ID of the operation
    ///   - completion: A closure to call when the task completes
    func addBackgroundTask(operationId: String, completion: ((Bool) -> Void)? = nil) {
        // Store the completion handler if provided
        if let completion = completion {
            completionHandlers[operationId] = completion
        }
        
        // Store the operation ID in UserDefaults
        var pendingOperations = UserDefaults.standard.array(forKey: "pendingBackgroundOperations") as? [String] ?? []
        if !pendingOperations.contains(operationId) {
            pendingOperations.append(operationId)
            UserDefaults.standard.set(pendingOperations, forKey: "pendingBackgroundOperations")
        }
        
        // Post notification
        NotificationCenter.default.post(
            name: .backgroundTaskDidAdd,
            object: self,
            userInfo: ["operationId": operationId]
        )
    }
    
    /// Mark a background task as completed
    /// - Parameters:
    ///   - operationId: The ID of the operation
    ///   - success: Whether the operation was successful
    func completeBackgroundTask(operationId: String, success: Bool) {
        // Remove the operation ID from UserDefaults
        var pendingOperations = UserDefaults.standard.array(forKey: "pendingBackgroundOperations") as? [String] ?? []
        pendingOperations.removeAll { $0 == operationId }
        UserDefaults.standard.set(pendingOperations, forKey: "pendingBackgroundOperations")
        
        // Call the completion handler if available
        if let completion = completionHandlers[operationId] {
            completion(success)
            completionHandlers.removeValue(forKey: operationId)
        }
        
        // Post notification
        NotificationCenter.default.post(
            name: .backgroundTaskDidComplete,
            object: self,
            userInfo: ["operationId": operationId, "success": success]
        )
    }
    
    /// Check for completed background tasks
    func checkForCompletedTasks() {
        // This would check if any tasks have completed since the app was last opened
        // For now, we'll just print a message
        print("Checking for completed background tasks")
    }
    
    /// Handle a background processing task
    /// - Parameter task: The background processing task
    func handleBackgroundProcessingTask(_ task: BGProcessingTask) {
        // Submit background task
        task.expirationHandler = {
            // Cancel any ongoing work if the task expires
            print("Background processing task expired")
        }
        
        // Perform background work here
        // ...
        
        // Mark task complete
        task.setTaskCompleted(success: true)
    }
    
    /// Handle a background refresh task
    /// - Parameter task: The background refresh task
    func handleBackgroundRefreshTask(_ task: BGAppRefreshTask) {
        // Submit background task
        task.expirationHandler = {
            // Cancel any ongoing work if the task expires
            print("Background refresh task expired")
        }
        
        // Perform background work here
        // ...
        
        // Mark task complete
        task.setTaskCompleted(success: true)
    }
}