/**
 * @fileoverview Application state management
 * @module AppState
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - SwiftUI
 * - Combine
 * 
 * Exports:
 * - AppState
 * 
 * Notes:
 * - This is the central state management class for the LLMBuddy application
 * - Manages application-wide settings, API keys, and user preferences
 */

import Foundation
import Combine
import SwiftUI

/// Central application state management class
public class AppState: ObservableObject {
    // MARK: - Published Properties
    
    // Selected LLM model
    @Published var selectedModel: LLMModel = .claudeSonnet
    
    // API Keys for different providers
    @Published var anthropicApiKey: String = ""
    @Published var openaiApiKey: String = ""
    @Published var googleApiKey: String = ""
    @Published var mistralApiKey: String = ""
    
    // User preferences
    @Published var useDarkMode: Bool = false
    @Published var enableHapticFeedback: Bool = true
    @Published var savePromptHistory: Bool = true
    @Published var maxPromptHistoryItems: Int = 100
    @Published var defaultTemperature: Double = 0.7
    @Published var defaultMaxTokens: Int = 2000
    
    // Feature flags
    @Published var enableExperimentalFeatures: Bool = false
    @Published var enableDebugLogging: Bool = false
    @Published var enableCloudSync: Bool = false
    
    // MARK: - Initializer
    
    public init() {
        loadSettings()
    }
    
    // MARK: - Methods
    
    /// Load saved settings from persistent storage
    private func loadSettings() {
        // In a real implementation, this would load settings from UserDefaults or KeychainService
        // For this placeholder, we'll just set some default values
        
        // Check if we're running in preview mode
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            setupPreviewData()
            return
        }
        
        // Load API keys from secure storage
        // anthropicApiKey = KeychainService.shared.retrieveAPIKey(for: .anthropic) ?? ""
        // openaiApiKey = KeychainService.shared.retrieveAPIKey(for: .openai) ?? ""
        // ...
        
        // Load user preferences from UserDefaults
        let defaults = UserDefaults.standard
        useDarkMode = defaults.bool(forKey: "useDarkMode")
        enableHapticFeedback = defaults.bool(forKey: "enableHapticFeedback")
        savePromptHistory = defaults.bool(forKey: "savePromptHistory")
        maxPromptHistoryItems = defaults.integer(forKey: "maxPromptHistoryItems")
        defaultTemperature = defaults.double(forKey: "defaultTemperature")
        defaultMaxTokens = defaults.integer(forKey: "defaultMaxTokens")
        
        // Load feature flags
        enableExperimentalFeatures = defaults.bool(forKey: "enableExperimentalFeatures")
        enableDebugLogging = defaults.bool(forKey: "enableDebugLogging")
        enableCloudSync = defaults.bool(forKey: "enableCloudSync")
    }
    
    /// Save current settings to persistent storage
    public func saveSettings() {
        // In a real implementation, this would save settings to UserDefaults or KeychainService
        
        // Save API keys to secure storage
        // KeychainService.shared.storeAPIKey(anthropicApiKey, for: .anthropic)
        // KeychainService.shared.storeAPIKey(openaiApiKey, for: .openai)
        // ...
        
        // Save user preferences to UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(useDarkMode, forKey: "useDarkMode")
        defaults.set(enableHapticFeedback, forKey: "enableHapticFeedback")
        defaults.set(savePromptHistory, forKey: "savePromptHistory")
        defaults.set(maxPromptHistoryItems, forKey: "maxPromptHistoryItems")
        defaults.set(defaultTemperature, forKey: "defaultTemperature")
        defaults.set(defaultMaxTokens, forKey: "defaultMaxTokens")
        
        // Save feature flags
        defaults.set(enableExperimentalFeatures, forKey: "enableExperimentalFeatures")
        defaults.set(enableDebugLogging, forKey: "enableDebugLogging")
        defaults.set(enableCloudSync, forKey: "enableCloudSync")
    }
    
    /// Set up dummy data for preview mode
    private func setupPreviewData() {
        anthropicApiKey = "preview_sk-ant-api123"
        openaiApiKey = "preview_sk-openai456"
        useDarkMode = true
        enableHapticFeedback = true
        savePromptHistory = true
        maxPromptHistoryItems = 50
        defaultTemperature = 0.7
        defaultMaxTokens = 2000
        enableExperimentalFeatures = true
    }
    
    /// Reset all settings to default values
    public func resetSettings() {
        selectedModel = .claudeSonnet
        anthropicApiKey = ""
        openaiApiKey = ""
        googleApiKey = ""
        mistralApiKey = ""
        useDarkMode = false
        enableHapticFeedback = true
        savePromptHistory = true
        maxPromptHistoryItems = 100
        defaultTemperature = 0.7
        defaultMaxTokens = 2000
        enableExperimentalFeatures = false
        enableDebugLogging = false
        enableCloudSync = false
        
        saveSettings()
    }
    
    /// Check if API key is configured for the selected model
    public func isApiKeyConfigured(for model: LLMModel? = nil) -> Bool {
        let modelToCheck = model ?? selectedModel
        
        switch modelToCheck.provider {
        case .anthropic:
            return !anthropicApiKey.isEmpty
        case .openai:
            return !openaiApiKey.isEmpty
        case .google:
            return !googleApiKey.isEmpty
        case .mistral:
            return !mistralApiKey.isEmpty
        case .meta, .local:
            return true // No API key needed for local models
        }
    }
    
    /// Get the API key for the specified provider
    public func getApiKey(for provider: Provider) -> String {
        switch provider {
        case .anthropic:
            return anthropicApiKey
        case .openai:
            return openaiApiKey
        case .google:
            return googleApiKey
        case .mistral:
            return mistralApiKey
        case .meta, .local:
            return ""
        }
    }
}
