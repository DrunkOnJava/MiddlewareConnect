//
//  ImageCachingService.swift
//  LLMBuddy-iOS
//
//  Created on 3/25/2025.
//

import Foundation
import UIKit
import CryptoKit

/// Service for caching and managing images
class ImageCachingService {
    /// Shared instance for app-wide image caching
    static let shared = ImageCachingService()
    
    /// Caching service for image caching
    private let cachingService = CachingService.shared
    
    /// Initialize a new instance
    private init() {
        // Initialize the service
    }
    
    /// Flag to enable/disable image caching
    var cachingEnabled = true
    
    /// Cache an image with a specific key
    /// - Parameters:
    ///   - image: The image to cache
    ///   - key: The cache key
    func cacheImage(_ image: UIImage, forKey key: String) {
        if cachingEnabled {
            // Store the image in memory cache
            let key = "img_\(key)"
            NSCache<NSString, UIImage>().setObject(image, forKey: key as NSString)
        }
    }
    
    /// Cache an image with a URL as the key
    /// - Parameters:
    ///   - image: The image to cache
    ///   - url: The URL to use as the cache key
    func cacheImage(_ image: UIImage, forURL url: URL) {
        cacheImage(image, forKey: url.absoluteString)
    }
    
    /// Retrieve a cached image for a specific key
    /// - Parameter key: The cache key
    /// - Returns: The cached image, if available
    func cachedImage(forKey key: String) -> UIImage? {
        if cachingEnabled {
            let key = "img_\(key)"
            return NSCache<NSString, UIImage>().object(forKey: key as NSString)
        }
        return nil
    }
    
    /// Retrieve a cached image for a URL
    /// - Parameter url: The URL used as the cache key
    /// - Returns: The cached image, if available
    func cachedImage(forURL url: URL) -> UIImage? {
        return cachedImage(forKey: url.absoluteString)
    }
    
    /// Load an image from a URL, using the cache if available
    /// - Parameters:
    ///   - url: The URL of the image
    ///   - skipCache: Whether to skip the cache and force a new download
    ///   - completion: Callback with the loaded image or error
    func loadImage(from url: URL, skipCache: Bool = false, completion: @escaping (Result<UIImage, Error>) -> Void) {
        // Check cache if caching is enabled and we're not skipping the cache
        if cachingEnabled && !skipCache, let cachedImage = cachedImage(forURL: url) {
            completion(.success(cachedImage))
            return
        }
        
        // Download the image
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(.failure(ImageError.invalidImageData))
                }
                return
            }
            
            // Cache the image
            if let self = self, self.cachingEnabled {
                self.cacheImage(image, forURL: url)
            }
            
            DispatchQueue.main.async {
                completion(.success(image))
            }
        }
        
        task.resume()
    }
    
    /// Split an image into multiple parts
    /// - Parameters:
    ///   - image: The image to split
    ///   - rows: Number of rows
    ///   - columns: Number of columns
    ///   - cacheResults: Whether to cache the resulting images
    /// - Returns: Array of split images
    func splitImage(_ image: UIImage, rows: Int, columns: Int, cacheResults: Bool = true) -> [UIImage] {
        let width = image.size.width
        let height = image.size.height
        
        let tileWidth = width / CGFloat(columns)
        let tileHeight = height / CGFloat(rows)
        
        var results: [UIImage] = []
        
        // Generate a cache key for the original image
        let originalImageKey = generateCacheKey(for: image, operation: "original")
        
        // Cache the original image if needed
        if cacheResults && cachingEnabled {
            cacheImage(image, forKey: originalImageKey)
        }
        
        for row in 0..<rows {
            for column in 0..<columns {
                let x = CGFloat(column) * tileWidth
                let y = CGFloat(row) * tileHeight
                let rect = CGRect(x: x, y: y, width: tileWidth, height: tileHeight)
                
                // Generate a cache key for this tile
                let tileKey = "\(originalImageKey)-tile-\(row)-\(column)"
                
                // Check if this tile is already cached
                if cacheResults && cachingEnabled, let cachedTile = cachedImage(forKey: tileKey) {
                    results.append(cachedTile)
                    continue
                }
                
                // Create the tile
                if let cgImage = image.cgImage?.cropping(to: rect) {
                    let tileImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
                    
                    // Cache the tile
                    if cacheResults && cachingEnabled {
                        cacheImage(tileImage, forKey: tileKey)
                    }
                    
                    results.append(tileImage)
                }
            }
        }
        
        return results
    }
    
    /// Split an image horizontally
    /// - Parameters:
    ///   - image: The image to split
    ///   - parts: Number of parts to split into
    ///   - cacheResults: Whether to cache the resulting images
    /// - Returns: Array of split images
    func splitImageHorizontally(_ image: UIImage, parts: Int, cacheResults: Bool = true) -> [UIImage] {
        return splitImage(image, rows: 1, columns: parts, cacheResults: cacheResults)
    }
    
    /// Split an image vertically
    /// - Parameters:
    ///   - image: The image to split
    ///   - parts: Number of parts to split into
    ///   - cacheResults: Whether to cache the resulting images
    /// - Returns: Array of split images
    func splitImageVertically(_ image: UIImage, parts: Int, cacheResults: Bool = true) -> [UIImage] {
        return splitImage(image, rows: parts, columns: 1, cacheResults: cacheResults)
    }
    
    /// Enable or disable image caching - convenience method
    /// - Parameter enabled: Whether caching should be enabled
    @objc func setCachingEnabled(_ enabled: Bool) {
        cachingEnabled = enabled
    }
    
    /// Clear all cached images
    func clearImageCache() -> Void {
        // Clear images from the caching service
        // Since we're prefixing image keys with "img_" in this service,
        // use a custom implementation to clear just images
        let keysToRemove = ["img_"] // Placeholder - in a real implementation you'd track these
        
        for key in keysToRemove {
            let nsKey = key as NSString
            NSCache<NSString, UIImage>().removeObject(forKey: nsKey)
        }
    }
    
    /// Generate a cache key for the given image and operation
    /// - Parameters:
    ///   - image: The image
    ///   - operation: The type of operation being performed
    /// - Returns: A unique cache key
    private func generateCacheKey(for image: UIImage, operation: String) -> String {
        // Create a string with the image dimensions and operation
        let dimensions = "\(image.size.width)x\(image.size.height)"
        let input = "\(dimensions)|\(operation)|\(Date().timeIntervalSince1970)"
        
        // Hash the string to create a unique key
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

/// Errors that can occur during image operations
enum ImageError: Error, LocalizedError {
    case invalidImageData
    case imageProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data"
        case .imageProcessingFailed:
            return "Image processing failed"
        }
    }
}
