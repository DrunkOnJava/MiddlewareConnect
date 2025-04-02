//
//  SimpleLogger.swift
//  LLMBuddy-iOS
//
//  A simplified error logger for LLM analysis
//

import Foundation
import UIKit

/// Simple error logger for LLM analysis
public class SimpleLogger {
    /// Shared instance
    public static let shared = SimpleLogger()
    
    private let logDirectory: String
    
    private init() {
        // Use app's Documents directory for logs
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let logDir = documentsDirectory.appendingPathComponent("Logs")
        logDirectory = logDir.path
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        
        // Log startup
        logInfo("Application started", context: "Lifecycle")
    }
    
    /// Log an info message
    public func logInfo(_ message: String, context: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: "INFO", message: message, context: context, file: file, function: function, line: line)
    }
    
    /// Log a warning
    public func logWarning(_ message: String, context: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: "WARNING", message: message, context: context, file: file, function: function, line: line)
    }
    
    /// Log an error
    public func logError(_ error: Error, context: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: "ERROR", message: error.localizedDescription, context: context, file: file, function: function, line: line)
        
        // Also log extra error details if available
        if let nsError = error as NSError {
            log(level: "ERROR DETAILS", message: "Domain: \(nsError.domain), Code: \(nsError.code), UserInfo: \(nsError.userInfo)", context: context, file: file, function: function, line: line)
        }
    }
    
    /// Export logs for LLM analysis
    public func exportLogs() -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let exportURL = URL(fileURLWithPath: logDirectory).appendingPathComponent("export_\(timestamp).md")
        
        var exportContent = "# LLM Optimized Log Export\n\n"
        exportContent += "Generated: \(Date())\n\n"
        
        // System info
        exportContent += "## System Information\n\n"
        exportContent += "- Device: \(UIDevice.current.model)\n"
        exportContent += "- OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)\n"
        exportContent += "- App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\n\n"
        
        // Log content
        exportContent += "## Log Entries\n\n"
        
        let logFile = URL(fileURLWithPath: logDirectory).appendingPathComponent("app.log")
        if let logContent = try? String(contentsOf: logFile) {
            exportContent += "```\n\(logContent)\n```\n"
        } else {
            exportContent += "No log entries found.\n"
        }
        
        try? exportContent.write(to: exportURL, atomically: true, encoding: .utf8)
        
        return exportURL
    }
    
    // MARK: - Private Methods
    
    private func log(level: String, message: String, context: String?, file: String, function: String, line: Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let contextStr = context != nil ? " [\(context!)]" : ""
        
        let logMessage = "[\(timestamp)] \(level)\(contextStr): \(message) (in \(filename):\(line))"
        appendToLogFile(logMessage)
        
        // Also print to console
        print(logMessage)
    }
    
    private func appendToLogFile(_ message: String) {
        let logFile = URL(fileURLWithPath: logDirectory).appendingPathComponent("app.log")
        
        if FileManager.default.fileExists(atPath: logFile.path),
           let fileHandle = try? FileHandle(forWritingTo: logFile) {
            // File exists, append to it
            fileHandle.seekToEndOfFile()
            if let data = "\(message)\n".data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } else {
            // File doesn't exist, create it
            try? "\(message)\n".write(to: logFile, atomically: true, encoding: .utf8)
        }
    }
}

/* Usage Example:
 
 // In AppDelegate:
 func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
     // Initialize logger
     _ = SimpleLogger.shared
     
     return true
 }
 
 // Log messages:
 SimpleLogger.shared.logInfo("User logged in", context: "Authentication")
 
 // Log errors:
 do {
     try riskyOperation()
 } catch {
     SimpleLogger.shared.logError(error, context: "Feature")
 }
 
 // Export for LLM:
 let exportURL = SimpleLogger.shared.exportLogs()
 UIApplication.shared.open(exportURL)
 
 */
