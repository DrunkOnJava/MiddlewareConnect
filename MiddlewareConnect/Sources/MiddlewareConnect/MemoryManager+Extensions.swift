/**
@fileoverview MemoryManager extensions for additional functionality
@module MemoryManager+Extensions
Created: 2025-04-01
Last Modified: 2025-04-01
Dependencies:
- Foundation
- MemoryManager
Exports:
- MemoryManager extensions
Notes:
- Adds UI-related memory management utilities
- Provides formatted memory usage information
/

import Foundation
#if canImport(UIKit)
#if canImport(UIKit)
import UIKit
#endif
#endif

// Notification name for memory warnings
extension Notification.Name {
    static let memoryManagerDidReceiveWarning = Notification.Name("memoryManagerDidReceiveWarning")
}

extension MemoryManager {
    /// Clear memory caches for UI operations
    func clearMemoryCaches() {
        // Clear image cache
        UIImageView.appearance().layer.removeAllAnimations()
        
        // Clear memory cache
        self.memoryCache.removeAll()
        
        // Suggest garbage collection
        autoreleasepool { }
    }
    
    /// Optimize memory for large file operations
    /// - Parameter operation: The operation to perform with memory optimization
    func optimizeForLargeFileOperation(operation: () -> Void) {
        // Clear memory before operation
        clearMemoryCaches()
        
        // Perform operation
        operation()
        
        // Clear memory after operation
        clearMemoryCaches()
    }
    
    /// Get formatted memory usage
    var formattedMemoryUsage: String {
        let bytes = memoryUsage
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
    
    /// Get memory usage percentage
    var memoryUsagePercentage: Double {
        let used = Double(memoryUsage)
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        return (used / total) * 100.0
    }
    
    /// Get memory usage in bytes
    private var memoryUsage: UInt64 {
        // This is a simplified version for iOS
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        
        return 0
    }
}