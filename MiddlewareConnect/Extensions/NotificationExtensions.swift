import Foundation

/// Notification name extensions for custom notifications
public extension Notification.Name {
    static let memoryManagerDidReceiveWarning = Notification.Name("memoryManagerDidReceiveWarning")
    static let memoryManagerDidUpdateUsage = Notification.Name("memoryManagerDidUpdateUsage")
    static let backgroundTaskDidAdd = Notification.Name("backgroundTaskDidAdd")
    static let backgroundTaskDidComplete = Notification.Name("backgroundTaskDidComplete")
    static let backgroundApiDataDidUpdate = Notification.Name("backgroundApiDataDidUpdate")
}
