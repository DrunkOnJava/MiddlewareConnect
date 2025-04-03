/**
@fileoverview Application delegate for the LLMBuddy app
@module AppDelegate
Created: 2025-03-29
Last Modified: 2025-03-29
Dependencies:
- UIKit
Exports:
- AppDelegate class
/

#if canImport(UIKit)
#if canImport(UIKit)
#if canImport(UIKit)
#if canImport(UIKit)
import UIKit
#endif
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Setup any app-level configurations here
        setupAppearance()
        registerForNotifications()
        // Initialize LLM Logger for error logging
        _ = LLMLogger.shared
        
        // Initialize SimpleLogger
        _ = SimpleLogger.shared
        return true
    }
    
    // Set up the global appearance for the app
    private func setupAppearance() {
        // Configure appearance settings
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    // Register for remote notifications
    private func registerForNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // Handle memory warnings
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        // Clear caches
        MemoryManager.shared.clearMemoryCaches()
    }
}
#endif // canImport(UIKit)
#endif // canImport(UIKit)
