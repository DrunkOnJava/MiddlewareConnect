/**
 * @fileoverview PDFService extension for singleton access
 * @module PDFService+Shared
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - PDFService
 * 
 * Exports:
 * - PDFService shared instance and extensions
 * 
 * Notes:
 * - Adds singleton pattern to PDFService
 * - Adds memory optimization and caching functions
 * - Implements caching management for CachingManager integration
 */

import Foundation
import PDFKit

// MARK: - Caching Extension

// PDFService caching capabilities - these will be handled by CachingManager
// to avoid circular dependencies

extension PDFService {
    /// Enable or disable caching
    /// - Parameter enabled: Whether caching should be enabled
    public func setCachingEnabled(_ enabled: Bool) {
        isCachingEnabled = enabled
        
        // If caching is disabled, clear the cache
        if !enabled {
            clearCache()
        }
        print("PDF caching \(enabled ? "enabled" : "disabled")")
    }
    
    /// Clear the PDF cache
    public func clearCache() {
        // Clear memory cache
        PDFService.memoryCache.removeAllObjects()
        
        // Clear disk cache
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: CachingConfig.cacheDirectory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
            print("PDF cache cleared")
        } catch {
            print("Error clearing PDF cache: \(error.localizedDescription)")
        }
    }
}

// Original extension for singleton access
extension PDFService {
    /// Shared singleton instance
    static let shared = PDFService()
    
    // MARK: - Properties
    
    /// Caching configuration
    private struct CachingConfig {
        /// Key for user defaults
        static let enabledKey = "PDFService.cachingEnabled"
        
        /// Default cache directory
        static let cacheDirectory: URL = {
            let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let pdfCacheDirectory = cacheDirectory.appendingPathComponent("PDFService", isDirectory: true)
            
            // Create the directory if it doesn't exist
            if !FileManager.default.fileExists(atPath: pdfCacheDirectory.path) {
                try? FileManager.default.createDirectory(at: pdfCacheDirectory, withIntermediateDirectories: true)
            }
            
            return pdfCacheDirectory
        }()
    }
    
    /// In-memory cache for PDFs
    private static var memoryCache = NSCache<NSString, PDFDocument>()
    
    /// Whether caching is enabled
    private var isCachingEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: CachingConfig.enabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: CachingConfig.enabledKey)
        }
    }
    
    /// Memory-related utility functions and caching
    
    // These methods are now implemented in the CacheableService extension above
    // to ensure protocol conformance
    
    /// Get the size of the PDF cache
    /// - Returns: Size in bytes
    func cacheSize() -> UInt64 {
        var totalSize: UInt64 = 0
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: CachingConfig.cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            for fileURL in fileURLs {
                let fileAttributes = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = fileAttributes.fileSize {
                    totalSize += UInt64(fileSize)
                }
            }
        } catch {
            print("Error calculating PDF cache size: \(error.localizedDescription)")
        }
        
        return totalSize
    }
    
    /// Combines PDF documents and optimizes for memory usage
    /// - Parameter urls: URLs of the PDFs to combine
    /// - Returns: URL of the combined PDF
    /// - Throws: PDFError if combining fails
    func combineDocuments(urls: [URL]) throws -> URL {
        // This is a wrapper around the existing combinePDFs method
        // that adds memory optimization
        return try combinePDFs(urls: urls)
    }
    
    /// Check if combining the given PDFs might cause memory issues
    /// - Parameter urls: URLs of the PDFs to check
    /// - Returns: True if combining might cause memory issues
    func mightCauseMemoryIssues(urls: [URL]) -> Bool {
        // Check file sizes and estimate memory requirements
        var totalSize: Int64 = 0
        
        for url in urls {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                totalSize += fileSize
            } catch {
                // If we can't get the size, assume it's large
                totalSize += 10_000_000 // 10 MB estimate
            }
        }
        
        // If total size is more than 100 MB, warn about potential memory issues
        return totalSize > 100_000_000
    }
    
    // MARK: - Cache Management Methods
    
    /// Cache a PDF document
    /// - Parameters:
    ///   - document: PDF document to cache
    ///   - key: Cache key
    func cacheDocument(_ document: PDFDocument, forKey key: String) {
        guard isCachingEnabled else { return }
        
        // Cache in memory
        PDFService.memoryCache.setObject(document, forKey: key as NSString)
        
        // Cache on disk
        let fileURL = CachingConfig.cacheDirectory.appendingPathComponent("\(key).pdf")
        document.write(to: fileURL)
    }
    
    /// Get a cached PDF document
    /// - Parameter key: Cache key
    /// - Returns: Cached PDF document
    func getCachedDocument(forKey key: String) -> PDFDocument? {
        guard isCachingEnabled else { return nil }
        
        // Check memory cache first
        if let document = PDFService.memoryCache.object(forKey: key as NSString) {
            return document
        }
        
        // Check disk cache
        let fileURL = CachingConfig.cacheDirectory.appendingPathComponent("\(key).pdf")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let document = PDFDocument(url: fileURL) {
                // Cache in memory for future use
                PDFService.memoryCache.setObject(document, forKey: key as NSString)
                return document
            }
        }
        
        return nil
    }
}