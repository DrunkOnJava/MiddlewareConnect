/**
 * @fileoverview Memory management and caching system
 * @module MemoryManager
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - Foundation
 * - Combine
 * 
 * Exports:
 * - MemoryManager for centralized memory and cache management
 * - Supporting cache and document handling classes
 * 
 * Notes:
 * - Handles both memory and disk caching
 * - Provides document paging for large files
 * - Monitors memory pressure and responds appropriately
 */

import Foundation
import Combine
import SwiftUI

// MARK: - Notification Names
extension NSNotification.Name {
    static let memoryManagerDidReceiveWarning = NSNotification.Name("memoryManagerDidReceiveWarning")
}

/// Centralized memory management and caching service
class MemoryManager {
    // Singleton instance
    static let shared = MemoryManager()
    
    // Memory usage and limits
    private let memoryWarningThreshold: Double = 0.7 // 70% of available memory
    private var isInLowMemoryState = false
    
    // Document paging system
    private var documentPageStates = [URL: DocumentPageState]()
    
    // Caches
    private var memoryCache = MemoryCache()
    private var diskCache = DiskCache()
    
    // Publishers
    private let memoryWarningSubject = PassthroughSubject<Void, Never>()
    var memoryWarningPublisher: AnyPublisher<Void, Never> {
        memoryWarningSubject.eraseToAnyPublisher()
    }
    
    // Statistics
    private(set) var cacheStats = CacheStatistics()
    
    private init() {
        // Start monitoring memory usage
        startMemoryMonitoring()
    }
    
    /// Clear memory caches (public method referenced by app)
    func clearMemoryCaches() {
        memoryCache.trim(keepingCapacity: 0.3) // Keep only 30% of memory cache
        
        // Release non-active document pages
        for (_, pageState) in documentPageStates {
            pageState.releaseNonVisiblePages()
        }
        
        print("Memory caches cleared")
    }
    
    /// Start monitoring memory usage with specified interval
    /// - Parameter interval: Time interval between checks in seconds
    /// - Returns: Timer instance for the monitoring
    @discardableResult
    func startMonitoringMemoryUsage(interval: TimeInterval) -> Timer {
        return Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkMemoryUsage()
        }
    }
    
    /// Store an object in the cache
    /// - Parameters:
    ///   - object: The object to cache
    ///   - key: Cache key
    ///   - seconds: Optional expiration time in seconds
    func cache<T: AnyObject>(_ object: T, forKey key: String, expiresAfter seconds: TimeInterval? = nil) {
        // Store in memory cache
        memoryCache.set(object, forKey: key, expiresAfter: seconds)
        
        // Update statistics
        cacheStats.totalCacheOperations += 1
        cacheStats.totalCacheStorage += 1
    }
    
    /// Store data in the cache
    /// - Parameters:
    ///   - data: The data to cache
    ///   - key: Cache key
    ///   - toDisk: Whether to also store to disk
    ///   - seconds: Optional expiration time in seconds
    func cacheData(_ data: Data, forKey key: String, toDisk: Bool = false, expiresAfter seconds: TimeInterval? = nil) {
        // Store in memory cache
        memoryCache.setData(data, forKey: key, expiresAfter: seconds)
        
        // Also store to disk if requested
        if toDisk {
            diskCache.setData(data, forKey: key, expiresAfter: seconds)
        }
        
        // Update statistics
        cacheStats.totalCacheOperations += 1
        cacheStats.totalCacheStorage += 1
    }
    
    /// Retrieve an object from the cache
    /// - Parameter key: Cache key
    /// - Returns: The cached object, if available
    func retrieveObject<T: AnyObject>(forKey key: String) -> T? {
        // Update statistics first to avoid double counting
        cacheStats.totalCacheOperations += 1
        
        // Get from memory cache
        if let object: T = memoryCache.get(forKey: key) {
            cacheStats.cacheHits += 1
            return object
        }
        
        cacheStats.cacheMisses += 1
        return nil
    }
    
    /// Retrieve data from the cache
    /// - Parameters:
    ///   - key: Cache key
    ///   - checkDisk: Whether to check disk cache if not in memory
    /// - Returns: The cached data, if available
    func retrieveData(forKey key: String, checkDisk: Bool = false) -> Data? {
        // Get from memory cache
        if let data = memoryCache.getData(forKey: key) {
            // Update statistics
            cacheStats.totalCacheOperations += 1
            cacheStats.cacheHits += 1
            return data
        }
        
        // If not in memory and disk check is requested, try disk cache
        if checkDisk, let data = diskCache.getData(forKey: key) {
            // Move to memory cache for faster future access
            memoryCache.setData(data, forKey: key)
            
            // Update statistics
            cacheStats.totalCacheOperations += 1
            cacheStats.cacheHits += 1
            cacheStats.diskCacheHits += 1
            
            return data
        }
        
        // Update statistics
        cacheStats.totalCacheOperations += 1
        cacheStats.cacheMisses += 1
        return nil
    }
    
    /// Remove an object from the cache
    /// - Parameters:
    ///   - key: Cache key
    ///   - fromDisk: Whether to also remove from disk cache
    func removeObject(forKey key: String, fromDisk: Bool = false) {
        memoryCache.remove(forKey: key)
        
        if fromDisk {
            diskCache.remove(forKey: key)
        }
    }
    
    /// Clear all caches
    func clearAllCaches() {
        memoryCache.removeAll()
        diskCache.removeAll()
        cacheStats = CacheStatistics()
    }
    
    /// Prepare a document for paged access
    /// - Parameters:
    ///   - url: Document URL
    ///   - pageSize: Size of each page in bytes
    func prepareDocument(at url: URL, pageSize: Int) {
        let pageState = DocumentPageState(url: url, pageSize: pageSize)
        documentPageStates[url] = pageState
    }
    
    /// Access a page from a document
    /// - Parameters:
    ///   - url: Document URL
    ///   - pageIndex: Page index
    /// - Returns: The requested page data, if available
    func getDocumentPage(from url: URL, pageIndex: Int) -> Data? {
        guard let pageState = documentPageStates[url] else {
            return nil
        }
        
        return pageState.getPage(at: pageIndex)
    }
    
    /// Release a document from the paging system
    /// - Parameter url: Document URL
    func releaseDocument(at url: URL) {
        documentPageStates.removeValue(forKey: url)
    }
    
    // MARK: - Memory Optimization
    
    /// Optimizes memory for large file operations
    /// - Parameter operation: The operation to perform
    func optimizeForLargeFileOperation(_ operation: () -> Void) {
        // Clear memory caches before operation
        clearMemoryCaches()
        
        // Perform the operation
        operation()
        
        // Release memory after operation
        autoreleasepool { }
        
        // Clear memory caches again
        clearMemoryCaches()
    }
    
    /// Current memory usage as a percentage
    var memoryUsagePercentage: Double {
        return getMemoryUsage() * 100
    }
    
    /// Human-readable memory usage string
    var formattedMemoryUsage: String {
        let usage = getMemoryUsage()
        let usedMB = getUsedMemoryInMB()
        return String(format: "%.1f MB (%.1f%%)", usedMB, usage * 100)
    }
    
    /// Gets memory usage in MB
    private func getUsedMemoryInMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024)
        }
        
        return 0.0
    }
    
    // MARK: - Memory Monitoring
    
    private func startMemoryMonitoring() {
        // Start a timer to periodically check memory usage
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkMemoryUsage()
        }
    }
    
    private func checkMemoryUsage() {
        // Get current memory usage
        let memoryUsage = getMemoryUsage()
        
        // Check if we're using too much memory
        if memoryUsage > memoryWarningThreshold && !isInLowMemoryState {
            isInLowMemoryState = true
            handleLowMemory()
        } else if memoryUsage < memoryWarningThreshold * 0.8 && isInLowMemoryState {
            // We've recovered
            isInLowMemoryState = false
        }
    }
    
    private func getMemoryUsage() -> Double {
        // This is a simplified representation
        // In a real app, you would use vm_statistics to get actual memory usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / (1024 * 1024)
            let totalMB = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024)
            return usedMB / totalMB
        }
        
        return 0.0
    }
    
    // Handle memory warnings using the public method
    private func handleMemoryWarning() {
        isInLowMemoryState = true
        handleLowMemory()
        
        // Post notification for subscribers
        NotificationCenter.default.post(name: .memoryManagerDidReceiveWarning, object: self)
    }
    
    private func handleLowMemory() {
        // Send notification
        memoryWarningSubject.send()
        
        // Clear non-essential caches
        memoryCache.trim(keepingCapacity: 0.5) // Keep only 50% of memory cache
        
        // Release non-active document pages
        for (_, pageState) in documentPageStates {
            pageState.releaseNonVisiblePages()
        }
        
        // Log memory warning
        print("Memory warning handled, caches trimmed")
    }
}

// MARK: - Supporting Classes

/// Memory-based cache implementation
class MemoryCache {
    private class CacheEntry<T> {
        let value: T
        let expirationDate: Date?
        
        init(value: T, expiresAfter seconds: TimeInterval? = nil) {
            self.value = value
            
            if let seconds = seconds {
                self.expirationDate = Date().addingTimeInterval(seconds)
            } else {
                self.expirationDate = nil
            }
        }
        
        var isExpired: Bool {
            if let expirationDate = expirationDate {
                return Date() > expirationDate
            }
            return false
        }
    }
    
    private var cache = [String: Any]()
    private var dataCache = [String: Data]()
    private let lock = NSLock()
    
    // Set an object in the cache
    func set<T: AnyObject>(_ object: T, forKey key: String, expiresAfter seconds: TimeInterval? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        let entry = CacheEntry(value: object, expiresAfter: seconds)
        cache[key] = entry
        
        // Clean expired entries periodically
        if arc4random_uniform(100) < 5 { // 5% chance to clean on each operation
            cleanExpiredEntries()
        }
    }
    
    // Set data in the cache
    func setData(_ data: Data, forKey key: String, expiresAfter seconds: TimeInterval? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        dataCache[key] = data
        
        // Clean expired entries periodically
        if arc4random_uniform(100) < 5 { // 5% chance to clean on each operation
            cleanExpiredEntries()
        }
    }
    
    // Get an object from the cache
    func get<T: AnyObject>(forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let anyEntry = cache[key] else {
            return nil
        }
        
        guard let entry = anyEntry as? CacheEntry<T> else {
            return nil
        }
        
        // Check if the entry has expired
        if entry.isExpired {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.value
    }
    
    // Get data from the cache
    func getData(forKey key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        
        return dataCache[key]
    }
    
    // Remove an object from the cache
    func remove(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        
        cache.removeValue(forKey: key)
        dataCache.removeValue(forKey: key)
    }
    
    // Remove all objects from the cache
    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        
        cache.removeAll()
        dataCache.removeAll()
    }
    
    // Trim the cache to a percentage of its current size
    func trim(keepingCapacity percentage: Double) {
        lock.lock()
        defer { lock.unlock() }
        
        // Calculate how many entries to keep
        let objectEntriesToKeep = Int(Double(cache.count) * percentage)
        let dataEntriesToKeep = Int(Double(dataCache.count) * percentage)
        
        // Sort entries by recency or priority and keep only the specified number
        // This is a simplified implementation
        if cache.count > objectEntriesToKeep {
            let keysToRemove = Array(cache.keys).suffix(cache.count - objectEntriesToKeep)
            for key in keysToRemove {
                cache.removeValue(forKey: key)
            }
        }
        
        if dataCache.count > dataEntriesToKeep {
            let keysToRemove = Array(dataCache.keys).suffix(dataCache.count - dataEntriesToKeep)
            for key in keysToRemove {
                dataCache.removeValue(forKey: key)
            }
        }
    }
    
    // Clean expired entries
    private func cleanExpiredEntries() {
        // Remove expired entries from object cache
        for (key, value) in cache {
            if let entry = value as? CacheEntry<AnyObject>, entry.isExpired {
                cache.removeValue(forKey: key)
            }
        }
    }
}

/// Disk-based cache implementation
class DiskCache {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let lock = NSLock()
    
    init() {
        // Get the cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("LLMBuddyCache")
        
        // Create the cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // Set data in the disk cache
    func setData(_ data: Data, forKey key: String, expiresAfter seconds: TimeInterval? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        do {
            try data.write(to: fileURL)
            
            // Store expiration metadata if needed
            if let seconds = seconds {
                let expirationDate = Date().addingTimeInterval(seconds)
                let metadataURL = fileURL.appendingPathExtension("metadata")
                let metadata = ["expirationDate": expirationDate.timeIntervalSince1970]
                let metadataData = try JSONSerialization.data(withJSONObject: metadata)
                try metadataData.write(to: metadataURL)
            }
        } catch {
            print("Error writing to disk cache: \(error)")
        }
    }
    
    // Get data from the disk cache
    func getData(forKey key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        // Check if the file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // Check if the file has expired
        if isFileExpired(at: fileURL) {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
        
        // Read the file
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            print("Error reading from disk cache: \(error)")
            return nil
        }
    }
    
    // Remove data from the disk cache
    func remove(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        
        let fileURL = cacheDirectory.appendingPathComponent(key)
        let metadataURL = fileURL.appendingPathExtension("metadata")
        
        try? fileManager.removeItem(at: fileURL)
        try? fileManager.removeItem(at: metadataURL)
    }
    
    // Remove all data from the disk cache
    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // Check if a file has expired
    private func isFileExpired(at fileURL: URL) -> Bool {
        let metadataURL = fileURL.appendingPathExtension("metadata")
        
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            return false
        }
        
        do {
            let metadataData = try Data(contentsOf: metadataURL)
            if let metadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any],
               let expirationTimestamp = metadata["expirationDate"] as? TimeInterval {
                let expirationDate = Date(timeIntervalSince1970: expirationTimestamp)
                return Date() > expirationDate
            }
        } catch {
            print("Error reading metadata: \(error)")
        }
        
        return false
    }
}

/// Document paging system for handling large documents
class DocumentPageState {
    let url: URL
    let pageSize: Int
    private var loadedPages = [Int: Data]()
    private let lock = NSLock()
    private var activePageIndices = Set<Int>()
    
    init(url: URL, pageSize: Int) {
        self.url = url
        self.pageSize = pageSize
    }
    
    // Get a page from the document
    func getPage(at index: Int) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        
        // If the page is already loaded, return it
        if let page = loadedPages[index] {
            activePageIndices.insert(index)
            return page
        }
        
        // Otherwise, load the page
        do {
            let data = try Data(contentsOf: url)
            
            // Calculate the start and end indices for the requested page
            let startIndex = index * pageSize
            let endIndex = min(startIndex + pageSize, data.count)
            
            // Check if the page is valid
            guard startIndex < data.count else {
                return nil
            }
            
            // Extract the page data
            let pageData = data.subdata(in: startIndex..<endIndex)
            
            // Store the page
            loadedPages[index] = pageData
            activePageIndices.insert(index)
            
            // Limit the number of loaded pages
            ensurePageLimit(20)
            
            return pageData
        } catch {
            print("Error loading document page: \(error)")
            return nil
        }
    }
    
    // Mark a page as visible/active
    func markPageVisible(_ index: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        activePageIndices.insert(index)
    }
    
    // Release non-visible pages to free memory
    func releaseNonVisiblePages() {
        lock.lock()
        defer { lock.unlock() }
        
        let pagesToRemove = loadedPages.keys.filter { !activePageIndices.contains($0) }
        
        for pageIndex in pagesToRemove {
            loadedPages.removeValue(forKey: pageIndex)
        }
    }
    
    // Ensure that we don't keep too many pages in memory
    private func ensurePageLimit(_ maxPages: Int) {
        if loadedPages.count > maxPages {
            // Keep only active pages and recently used pages up to the limit
            let pagesToKeep = Set(activePageIndices)
                .union(Set(loadedPages.keys.sorted().suffix(maxPages - activePageIndices.count)))
            
            let pagesToRemove = loadedPages.keys.filter { !pagesToKeep.contains($0) }
            
            for pageIndex in pagesToRemove {
                loadedPages.removeValue(forKey: pageIndex)
            }
        }
    }
}

/// Cache statistics for monitoring and optimization
struct CacheStatistics {
    var totalCacheOperations: Int = 0
    var cacheHits: Int = 0
    var cacheMisses: Int = 0
    var diskCacheHits: Int = 0
    var totalCacheStorage: Int = 0
    
    var hitRate: Double {
        guard totalCacheOperations > 0 else { return 0 }
        return Double(cacheHits) / Double(totalCacheOperations)
    }
}
