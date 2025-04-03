/**
@fileoverview Centralized caching service
@module CachingService
Created: 2025-04-01
Last Modified: 2025-04-01
Dependencies:
- Foundation
Exports:
- CachingService for app-wide cache management
- CacheType enum
Notes:
- Manages different types of caches
- Provides centralized cache control
/

import Foundation

/// Types of caches managed by the service
enum CacheType {
    case api
    case data
    case file
    case all
}

/// Centralized caching service
class CachingService {
    /// Shared instance
    static let shared = CachingService()
    
    /// Cache directories
    private var cacheDirs: [CacheType: URL] = [:]
    
    /// Private initializer for singleton
    private init() {
        setupCacheDirectories()
    }
    
    /// Set up cache directories
    private func setupCacheDirectories() {
        let baseURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let mainCacheURL = baseURL.appendingPathComponent("LLMBuddyCache")
        
        // Create directories
        cacheDirs = [
            .api: mainCacheURL.appendingPathComponent("API"),
            .data: mainCacheURL.appendingPathComponent("Data"),
            .file: mainCacheURL.appendingPathComponent("Files")
        ]
        
        // Ensure directories exist
        for (_, url) in cacheDirs {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    /// Clear a specific type of cache
    /// - Parameter type: The type of cache to clear
    func clearCache(type: CacheType) {
        switch type {
        case .all:
            for (cacheType, _) in cacheDirs {
                clearCache(type: cacheType)
            }
        default:
            if let cacheDir = cacheDirs[type] {
                try? FileManager.default.removeItem(at: cacheDir)
                try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
            }
        }
    }
    
    /// Clear all caches
    func clearAllCaches() {
        clearCache(type: .all)
    }
    
    /// Get the size of the disk cache
    /// - Returns: Size in bytes
    func diskCacheSize() -> UInt64 {
        var totalSize: UInt64 = 0
        
        for (_, url) in cacheDirs {
            totalSize += directorySize(url: url)
        }
        
        return totalSize
    }
    
    /// Calculate the size of a directory
    /// - Parameter url: Directory URL
    /// - Returns: Size in bytes
    private func directorySize(url: URL) -> UInt64 {
        let fileManager = FileManager.default
        var size: UInt64 = 0
        
        // Get all files in directory
        guard let fileEnumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        for case let fileURL as URL in fileEnumerator {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let fileSize = attributes[.size] as? NSNumber {
                    size += fileSize.uint64Value
                }
            } catch {
                print("Error getting size of file \(fileURL): \(error)")
            }
        }
        
        return size
    }
    
    /// Cache data to disk
    /// - Parameters:
    ///   - data: Data to cache
    ///   - key: Cache key
    ///   - type: Cache type
    func cacheData(_ data: Data, forKey key: String, type: CacheType) {
        guard let cacheDir = cacheDirs[type] else { return }
        
        let fileURL = cacheDir.appendingPathComponent(key)
        try? data.write(to: fileURL)
    }
    
    /// Retrieve data from disk cache
    /// - Parameters:
    ///   - key: Cache key
    ///   - type: Cache type
    /// - Returns: Cached data, if available
    func retrieveData(forKey key: String, type: CacheType) -> Data? {
        guard let cacheDir = cacheDirs[type] else { return nil }
        
        let fileURL = cacheDir.appendingPathComponent(key)
        return try? Data(contentsOf: fileURL)
    }
    
    /// Remove data from disk cache
    /// - Parameters:
    ///   - key: Cache key
    ///   - type: Cache type
    func removeData(forKey key: String, type: CacheType) {
        guard let cacheDir = cacheDirs[type] else { return }
        
        let fileURL = cacheDir.appendingPathComponent(key)
        try? FileManager.default.removeItem(at: fileURL)
    }
}