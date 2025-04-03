import Foundation
import Intents
#if canImport(UIKit)
#if canImport(UIKit)
import UIKit
#endif
#endif

/// Protocol defining common functionality for all shortcut handlers
protocol ShortcutHandler {
    /// The type of shortcut handled by this handler
    var shortcutType: ShortcutsManager.ShortcutType { get }
    
    /// Handles the shortcut execution with given parameters
    /// - Parameters:
    ///   - parameters: Dictionary of parameters passed from the shortcut
    ///   - completion: Completion handler called when the operation is finished
    func handle(parameters: [String: Any], completion: @escaping (Bool, Error?) -> Void)
    
    /// Shows a user notification about the shortcut operation
    /// - Parameters:
    ///   - title: Title of the notification
    ///   - body: Body text of the notification
    ///   - success: Whether the operation was successful
    func showNotification(title: String, body: String, success: Bool)
    
    /// Stores the result of a shortcut operation for later retrieval
    /// - Parameter result: The result to store
    func storeResult(_ result: Any)
}

/// Default implementation of common ShortcutHandler methods
extension ShortcutHandler {
    func showNotification(title: String, body: String, success: Bool) {
        let notificationCenter = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        notificationCenter.add(request)
    }
    
    func storeResult(_ result: Any) {
        if let stringResult = result as? String {
            UserDefaults.standard.set(stringResult, forKey: "last_shortcut_result")
        } else if let data = try? JSONSerialization.data(withJSONObject: result) {
            UserDefaults.standard.set(data, forKey: "last_shortcut_result_data")
        }
    }
}

/// Protocol for shortcuts that process text data
protocol TextProcessingShortcutHandler: ShortcutHandler {}

/// Protocol for shortcuts that process PDF documents
protocol PDFShortcutHandler: ShortcutHandler {
    /// Access to the PDF service
    var pdfService: PDFService { get }
}

/// Protocol for shortcuts that process image data
protocol ImageShortcutHandler: ShortcutHandler {}

/// Protocol for shortcuts that work with structured data
protocol DataFormattingShortcutHandler: ShortcutHandler {}

/// Protocol for shortcuts that analyze LLM operations
protocol LLMAnalysisShortcutHandler: ShortcutHandler {}