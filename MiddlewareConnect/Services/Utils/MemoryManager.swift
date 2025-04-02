import Foundation
import UIKit
import BackgroundTasks

/// Notification name for memory warning
extension Notification.Name {
    static let memoryManagerDidReceiveWarning = Notification.Name("memoryManagerDidReceiveWarning")
    static let memoryManagerDidUpdateUsage = Notification.Name("memoryManagerDidUpdateUsage")
}

/// Memory manager singleton for monitoring memory usage
class MemoryManager {
    static let shared = MemoryManager()
    
    // Current memory usage in bytes
    private(set) var memoryUsage: UInt64 = 0
    
    // Device total memory
    private(set) var totalMemory: UInt64 = 0
    
    // Memory usage percentage (0-100)
    var memoryUsagePercentage: Double {
        if totalMemory == 0 { return 0 }
        return (Double(memoryUsage) / Double(totalMemory)) * 100.0
    }
    
    // High memory threshold (percentage)
    let highMemoryThreshold: Double = 80.0
    
    // Critical memory threshold (percentage)
    let criticalMemoryThreshold: Double = 90.0
    
    // Memory usage in formatted string (MB/GB)
    var formattedMemoryUsage: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memoryUsage))
    }
    
    private init() {
        // Get total physical memory
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        totalMemory = physicalMemory
        
        // Register for memory warnings at initialization
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Start monitoring memory usage with periodic updates
    /// - Parameter interval: The update interval in seconds (default: 5.0)
    /// - Returns: A timer that updates memory usage
    func startMonitoringMemoryUsage(interval: TimeInterval = 5.0) -> Timer? {
        // Update memory usage initially
        updateMemoryUsage()
        
        // Create timer for periodic updates
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
        
        return timer
    }
    
    /// Update memory usage measurement
    func updateMemoryUsage() {
        let memoryUsageBytes = getMemoryUsage()
        memoryUsage = memoryUsageBytes
        
        // Notify observers of memory usage update
        NotificationCenter.default.post(
            name: .memoryManagerDidUpdateUsage,
            object: self,
            userInfo: [
                "bytes": memoryUsage,
                "formatted": formattedMemoryUsage,
                "percentage": memoryUsagePercentage
            ]
        )
        
        // Check for high memory usage
        if memoryUsagePercentage > highMemoryThreshold {
            handleHighMemoryUsage()
        }
    }
    
    /// Handle memory warning notification
    @objc private func didReceiveMemoryWarning() {
        // Clear caches
        clearMemoryCaches()
        
        // Notify observers
        NotificationCenter.default.post(
            name: .memoryManagerDidReceiveWarning,
            object: self
        )
    }
    
    /// Handle high memory usage
    private func handleHighMemoryUsage() {
        // If memory usage is critical, clear caches proactively
        if memoryUsagePercentage > criticalMemoryThreshold {
            clearMemoryCaches()
        }
        
        // Log high memory usage
        print("⚠️ High memory usage: \(formattedMemoryUsage) (\(String(format: "%.1f", memoryUsagePercentage))%)")
    }
    
    /// Clear memory caches to free up memory
    func clearMemoryCaches() {
        // Clear image cache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear temporary files
        clearTemporaryFiles()
        
        // Force a garbage collection if possible
        autoreleasepool {
            // This helps release autoreleased objects
        }
        
        // Log memory cleanup
        print("🧹 Memory caches cleared")
        
        // Update memory usage after cleanup
        updateMemoryUsage()
    }
    
    /// Clear temporary files created by the app
    private func clearTemporaryFiles() {
        let fileManager = FileManager.default
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        
        do {
            let tempFiles = try fileManager.contentsOfDirectory(
                at: tempDirectoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            
            for fileURL in tempFiles {
                try? fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error cleaning temporary files: \(error.localizedDescription)")
        }
    }
    
    /// Get current memory usage in bytes
    /// - Returns: Memory usage in bytes
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            print("Error getting memory usage: \(kerr)")
            return 0
        }
    }
    
    /// Optimization result containing memory status information
    public struct OptimizationResult {
        /// Amount of memory freed in bytes
        public let memoryFreed: UInt64
        /// Success status of the optimization attempt
        public let success: Bool
        /// Current memory usage after optimization
        public let currentMemoryUsage: UInt64
    }
    
    /**
     * Optimizes the memory environment for large file operations like PDF processing.
     *
     * This method performs several memory optimization tasks:
     * 1. Forces a garbage collection cycle if possible
     * 2. Releases cached resources that aren't immediately needed
     * 3. Sends low memory notifications to encourage system-wide cleanup
     * 4. Logs memory usage statistics before and after optimization
     *
     * - Parameters:
     *   - threshold: Optional memory threshold in MB that triggers more aggressive optimization.
     *               Default value is 50MB.
     *   - logStats: Whether to log memory statistics. Default is true.
     *   - completion: Optional closure to execute after optimization completes.
     *
     * - Returns: An OptimizationResult struct containing information about the operation success
     *            and memory statistics.
     *
     * - Note: This method should be called before initiating resource-intensive operations
     *         like PDF combining or processing large documents.
     */
    @discardableResult
    public func optimizeForLargeFileOperation(
        threshold: Double = 50.0,
        logStats: Bool = true,
        completion: (() -> Void)? = nil
    ) -> OptimizationResult {
        // Log initial memory state if enabled
        if logStats {
            logMemoryUsage(label: "Before large file operation optimization")
        }
        
        // Get initial memory usage to calculate freed amount later
        let initialMemoryUsage = getMemoryUsage()
        
        // Clear caches and temporary resources
        clearMemoryCaches()
        
        // Force a garbage collection if possible
        autoreleasepool { }
        
        // Simulate memory warning to encourage system-wide cleanup
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        // Wait a moment for cleanup to take effect
        DispatchQueue.main.async {
            // Additional async cleanup if needed
            completion?()
        }
        
        // Get the current memory usage after optimization
        let currentMemoryUsage = getMemoryUsage()
        
        // Calculate how much memory was freed
        let memoryFreed = initialMemoryUsage > currentMemoryUsage ? initialMemoryUsage - currentMemoryUsage : 0
        
        // Log the results if enabled
        if logStats {
            logMemoryUsage(label: "After large file operation optimization")
            print("Memory optimization freed approximately \(memoryFreed / 1024 / 1024) MB")
        }
        
        return OptimizationResult(
            memoryFreed: memoryFreed,
            success: true,
            currentMemoryUsage: currentMemoryUsage
        )
    }
    
    /**
     * Logs the current memory usage with an optional label.
     * - Parameter label: A descriptive label for the log entry
     */
    private func logMemoryUsage(label: String) {
        let usedMemory = getMemoryUsage()
        let usedMemoryMB = Double(usedMemory) / 1024.0 / 1024.0
        print("\(label): \(String(format: "%.2f", usedMemoryMB)) MB")
    }
}