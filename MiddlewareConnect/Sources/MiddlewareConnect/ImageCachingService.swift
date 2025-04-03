/**
@fileoverview Image caching service
@module ImageCachingService
Created: 2025-04-01
Last Modified: 2025-04-01
Dependencies:
- Foundation
- UIKit
Exports:
- ImageCachingService for caching and retrieving images
Notes:
- Uses NSCache for in-memory caching
- Handles disk caching for persistence
/

import Foundation
#if canImport(UIKit)
#if canImport(UIKit)
import UIKit
#endif
#endif

/// Service for caching images
class ImageCachingService {
    /// Shared instance
    static let shared = ImageCachingService()
    
    /// In-memory cache
    private let imageCache = NSCache<NSString, UIImage>()
    
    /// Disk cache URL
    private let diskCacheURL: URL
    
    /// Flag to enable/disable caching
    var cachingEnabled: Bool = true
    
    /// Private initializer for singleton
    private init() {
        // Set up memory cache
        imageCache.name = "com.llmbuddy.imagecache"
        imageCache.countLimit = 100
        
        // Set up disk cache location
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheURL.appendingPathComponent("ImageCache")
        
        // Create cache directory if needed
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    /// Cache an image
    /// - Parameters:
    ///   - image: The image to cache
    ///   - key: Cache key (URL string or other unique identifier)
    func cacheImage(_ image: UIImage, forKey key: String) {
        guard cachingEnabled else { return }
        
        // Cache in memory
        imageCache.setObject(image, forKey: key as NSString)
        
        // Cache to disk
        let fileURL = diskCacheURL.appendingPathComponent(key.md5Hash)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }
    
    /// Retrieve an image from cache
    /// - Parameter key: Cache key
    /// - Returns: Cached image, if available
    func retrieveImage(forKey key: String) -> UIImage? {
        guard cachingEnabled else { return nil }
        
        // Check memory cache first
        if let cachedImage = imageCache.object(forKey: key as NSString) {
            return cachedImage
        }
        
        // Check disk cache
        let fileURL = diskCacheURL.appendingPathComponent(key.md5Hash)
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // Add to memory cache for faster access next time
            imageCache.setObject(image, forKey: key as NSString)
            return image
        }
        
        return nil
    }
    
    /// Clear the image cache
    func clearImageCache() {
        // Clear memory cache
        imageCache.removeAllObjects()
        
        // Clear disk cache
        try? FileManager.default.removeItem(at: diskCacheURL)
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
}

// MARK: - String Extension for MD5 Hashing

extension String {
    var md5Hash: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Import for MD5 hashing
import CommonCrypto