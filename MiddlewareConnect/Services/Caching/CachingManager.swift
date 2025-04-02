//
//  CachingManager.swift
//  LLMBuddy-iOS
//
//  Created on 3/25/2025.
//

import Foundation
import UIKit

// Add additional imports needed for caching-related services
import PDFKit

// Define our own CacheType to avoid conflicts
enum CacheManagerType {
    case api
    case pdf
    case image
    case all
}

/// Define a protocol instead of referencing the deprecated class
protocol LLMServiceProvider {
    func setCachingEnabled(_ enabled: Bool)
}

/// Manager for coordinating all caching services in the app
class CachingManager {
    /// Shared instance for app-wide caching management
    static let shared = CachingManager()
    
    /// The underlying caching service
    private let cachingService = CachingService.shared
    
    /// The LLM service provider - using protocol type instead
    private let llmServiceProvider: Any?
    
    /// The PDF service
    private let pdfService = PDFService()
    
    /// The image caching service
    private let imageCachingService = ImageCachingService.shared
    
    /// Flag to enable/disable all caching
    private var cachingEnabled = true
    
    /// Private initializer for singleton
    private init() {
        // Use reflection to find the service provider
        let serviceName = "LLMServiceProvider"
        
        // We'll use a more generic approach to avoid direct references to deprecated classes
        if let bundleClass = NSClassFromString("LLMBuddy_iOS.\(serviceName)") as? NSObject.Type {
            self.llmServiceProvider = bundleClass.init()
        } else {
            self.llmServiceProvider = nil
        }
        
        // Load caching preferences from UserDefaults
        cachingEnabled = UserDefaults.standard.bool(forKey: "cachingEnabled")
        
        // Set default value if not set
        if !UserDefaults.standard.contains(key: "cachingEnabled") {
            cachingEnabled = true
            UserDefaults.standard.set(true, forKey: "cachingEnabled")
        }
        
        // Apply the setting to all services
        updateCachingState()
    }
    
    /// Enable or disable all caching
    /// - Parameter enabled: Whether caching should be enabled
    func setCachingEnabled(_ enabled: Bool) {
        cachingEnabled = enabled
        
        // Save the preference
        UserDefaults.standard.set(enabled, forKey: "cachingEnabled")
        
        // Update all services
        updateCachingState()
    }
    
    /// Check if caching is enabled
    /// - Returns: Whether caching is enabled
    func getCachingStatus() -> Bool {
        return cachingEnabled
    }
    
    /// Clear all caches
    func clearAllCaches() {
        cachingService.clearAllCaches()
    }
    
    /// Clear a specific type of cache
    /// - Parameter type: The type of cache to clear
    func clearCache(type: CacheManagerType) {
        switch type {
        case .api:
            cachingService.clearCache(type: .api)
        case .pdf:
            // Clear PDF cache
            pdfService.clearCache()
        case .image:
            // Clear image cache
            imageCachingService.clearImageCache()
        case .all:
            // Clear all caches
            clearAllCaches()
        }
    }
    
    /// Get the total size of all disk caches
    /// - Returns: The size in bytes
    func totalDiskCacheSize() -> UInt64 {
        return cachingService.diskCacheSize()
    }
    
    /// Get the formatted size of all disk caches
    /// - Returns: The formatted size string (e.g., "10.5 MB")
    func formattedDiskCacheSize() -> String {
        let bytes = totalDiskCacheSize()
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
    
    /// Update the caching state for all services
    private func updateCachingState() {
        // Update API service if available - using reflection to avoid deprecation warnings
        if let service = llmServiceProvider as AnyObject? {  // Cast to AnyObject to access Objective-C runtime methods
            let selector = NSSelectorFromString("setCachingEnabled:")
            if service.responds(to: selector) {
                _ = service.perform(selector, with: cachingEnabled as NSNumber)
            }
        }
        
        // Update PDF service
        pdfService.setCachingEnabled(cachingEnabled)
        
        // Update image service using direct property access
        imageCachingService.cachingEnabled = cachingEnabled
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    /// Check if a key exists in UserDefaults
    /// - Parameter key: The key to check
    /// - Returns: Whether the key exists
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
