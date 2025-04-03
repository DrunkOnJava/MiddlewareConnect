/**
@fileoverview Navigation coordination for the LLMBuddy application
@module NavigationCoordinator
Created: 2025-03-29
Last Modified: 2025-03-29
Dependencies:
- SwiftUI
Exports:
- NavigationCoordinator class
- NavigationDestination enum
/

import SwiftUI

/// Handles application navigation and routing
class NavigationCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current navigation path
    @Published var path = NavigationPath()
    
    /// Currently active sheet
    @Published var activeSheet: SheetDestination?
    
    /// Flag for showing fullscreen cover
    @Published var activeFullscreenCover: FullscreenDestination?
    
    /// Flag for showing alerts
    @Published var activeAlert: AlertType?
    
    /// Flag for showing context menu
    @Published var showContextMenu: Bool = false
    
    /// Flag for showing search
    @Published var showSearch: Bool = false
    
    /// Flag for showing API settings
    @Published var showApiSettings: Bool = false
    
    /// Flag for showing model settings
    @Published var showModelSettings: Bool = false
    
    /// Flag for showing release notes
    @Published var showReleaseNotes: Bool = false
    
    /// Flag for showing feedback form
    @Published var showFeedbackForm: Bool = false
    
    /// Flag for showing privacy policy
    @Published var showPrivacyPolicy: Bool = false
    
    // MARK: - Initialization
    
    /// Initialize the navigation coordinator
    init() {
        // Setup any observers or initial state if needed
    }
    
    // MARK: - Public Methods
    
    /// Navigate to a specific destination
    func navigateTo(_ destination: NavigationDestination) {
        path.append(destination)
    }
    
    /// Navigate back one level
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    /// Navigate to root
    func navigateToRoot() {
        path = NavigationPath()
    }
    
    /// Present a sheet
    func presentSheet(_ destination: SheetDestination) {
        activeSheet = destination
    }
    
    /// Dismiss the current sheet
    func dismissSheet() {
        activeSheet = nil
    }
    
    /// Present a fullscreen cover
    func presentFullscreenCover(_ destination: FullscreenDestination) {
        activeFullscreenCover = destination
    }
    
    /// Dismiss the current fullscreen cover
    func dismissFullscreenCover() {
        activeFullscreenCover = nil
    }
    
    /// Show an alert
    func showAlert(_ alertType: AlertType) {
        activeAlert = alertType
    }
    
    /// Dismiss the current alert
    func dismissAlert() {
        activeAlert = nil
    }
    
    /// Toggle search visibility
    func toggleSearch() {
        showSearch.toggle()
    }
}

/// Represents navigation destinations in the app
enum NavigationDestination: Hashable {
    case conversationDetail(UUID)
    case modelDetail(UUID)
    case settings
    case apiKeys
    case help
    case about
    
    // Add more destinations as needed
}

/// Represents sheet destinations in the app
enum SheetDestination: Identifiable {
    case newConversation
    case modelSelection
    case settings
    case exportConversation(UUID)
    case importConversation
    
    // Add more sheet destinations as needed
    
    var id: String {
        switch self {
        case .newConversation: return "newConversation"
        case .modelSelection: return "modelSelection"
        case .settings: return "settings"
        case .exportConversation(let id): return "exportConversation-\(id)"
        case .importConversation: return "importConversation"
        }
    }
}

/// Represents fullscreen cover destinations in the app
enum FullscreenDestination: Identifiable {
    case onboarding
    case authentication
    case welcomeTour
    
    // Add more fullscreen destinations as needed
    
    var id: String {
        switch self {
        case .onboarding: return "onboarding"
        case .authentication: return "authentication"
        case .welcomeTour: return "welcomeTour"
        }
    }
}

/// Represents alert types in the app
enum AlertType: Identifiable {
    case error(String)
    case confirmation(String, () -> Void)
    case deleteConfirmation(String, () -> Void)
    
    // Add more alert types as needed
    
    var id: String {
        switch self {
        case .error: return "error"
        case .confirmation: return "confirmation"
        case .deleteConfirmation: return "deleteConfirmation"
        }
    }
}
