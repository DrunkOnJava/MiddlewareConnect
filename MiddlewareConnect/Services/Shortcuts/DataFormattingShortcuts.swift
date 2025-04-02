import Foundation
import UIKit

/// Handler for CSV formatting shortcuts
class CSVFormatterShortcutHandler: DataFormattingShortcutHandler {
    let shortcutType: ShortcutsManager.ShortcutType = .csvFormatter
    
    func handle(parameters: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        // Get the parameters
        guard let fileURL = parameters["fileURL"] as? URL else {
            completion(false, nil)
            return
        }
        
        let delimiter = parameters["delimiter"] as? String ?? "comma"
        let hasHeader = parameters["hasHeader"] as? Bool ?? true
        
        // Determine the actual delimiter character
        let delimiterChar: String
        switch delimiter.lowercased() {
        case "comma":
            delimiterChar = ","
        case "tab":
            delimiterChar = "\t"
        case "semicolon":
            delimiterChar = ";"
        case "pipe":
            delimiterChar = "|"
        default:
            delimiterChar = ","
        }
        
        do {
            // Read the CSV file
            let csvData = try Data(contentsOf: fileURL)
            guard let csvString = String(data: csvData, encoding: .utf8) else {
                let error = NSError(domain: "com.llmbuddy.shortcuts", code: 1006, userInfo: [NSLocalizedDescriptionKey: "Failed to read CSV file as UTF-8"])
                completion(false, error)
                return
            }
            
            // Format the CSV
            let formattedCSV = formatCSV(csvString, delimiter: delimiterChar, hasHeader: hasHeader)
            
            // Create a temporary output path
            let tempDir = FileManager.default.temporaryDirectory
            let outputPath = tempDir.appendingPathComponent("FormattedCSV_\(UUID().uuidString).csv")
            
            // Write the formatted CSV to the output path
            try formattedCSV.write(to: outputPath, atomically: true, encoding: .utf8)
            
            // Store the result path for later retrieval
            UserDefaults.standard.set(outputPath.path, forKey: "last_shortcut_result_path")
            
            // Create a notification to inform the user
            showNotification(
                title: "CSV Formatting Complete",
                body: "Your CSV file has been formatted",
                success: true
            )
            
            completion(true, nil)
        } catch {
            // Handle error
            showNotification(
                title: "CSV Formatting Failed",
                body: "Error: \(error.localizedDescription)",
                success: false
            )
            
            completion(false, error)
        }
    }
    
    /// Format CSV string
    /// - Parameters:
    ///   - csvString: The original CSV string
    ///   - delimiter: The delimiter character
    ///   - hasHeader: Whether the CSV has a header row
    /// - Returns: The formatted CSV string
    private func formatCSV(_ csvString: String, delimiter: String, hasHeader: Bool) -> String {
        // Split the CSV into lines
        var lines = csvString.components(separatedBy: .newlines)
        
        // Remove empty lines
        lines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        if lines.isEmpty {
            return ""
        }
        
        // Process each line
        var formattedLines: [String] = []
        
        // First, determine the columns by splitting the first line
        let firstLineFields = lines[0].components(separatedBy: delimiter)
        let columnCount = firstLineFields.count
        
        for (index, line) in lines.enumerated() {
            // Split the line into fields
            var fields = line.components(separatedBy: delimiter)
            
            // Ensure all fields are trimmed
            fields = fields.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            // If we have header and this is the header row, don't trim quotes
            if hasHeader && index == 0 {
                // Format header fields (capitalize first letter)
                fields = fields.map { field in
                    if !field.isEmpty {
                        let firstChar = field.prefix(1).uppercased()
                        let rest = field.dropFirst()
                        return firstChar + rest
                    }
                    return field
                }
            }
            
            // Ensure each field is properly quoted if it contains the delimiter or a newline
            fields = fields.map { field in
                if field.contains(delimiter) || field.contains("\n") {
                    return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\"" 
                }
                return field
            }
            
            // Ensure consistent column count (add empty fields if needed)
            while fields.count < columnCount {
                fields.append("")
            }
            
            // Join fields back into a line
            let formattedLine = fields.joined(separator: delimiter)
            formattedLines.append(formattedLine)
        }
        
        // Join lines back into a string
        return formattedLines.joined(separator: "\n")
    }
}

/// Handler for image splitting shortcuts
class ImageSplitterShortcutHandler: ImageShortcutHandler {
    let shortcutType: ShortcutsManager.ShortcutType = .imageSplitter
    
    func handle(parameters: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        // Get the parameters
        guard let fileURL = parameters["fileURL"] as? URL,
              let splitType = parameters["splitType"] as? String else {
            completion(false, nil)
            return
        }
        
        let rows = parameters["rows"] as? Int ?? 2
        let columns = parameters["columns"] as? Int ?? 2
        
        do {
            // Load the image
            guard let image = UIImage(contentsOfFile: fileURL.path) else {
                let error = NSError(domain: "com.llmbuddy.shortcuts", code: 1007, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
                completion(false, error)
                return
            }
            
            // Create a temporary output directory
            let tempDir = FileManager.default.temporaryDirectory
            let outputDir = tempDir.appendingPathComponent("SplitImages_\(UUID().uuidString)")
            
            // Create the output directory
            try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
            
            // Split the image based on the split type
            var outputURLs: [URL] = []
            
            switch splitType.lowercased() {
            case "grid":
                outputURLs = splitImageIntoGrid(image, rows: rows, columns: columns, outputDir: outputDir)
            case "horizontal":
                outputURLs = splitImageHorizontally(image, parts: rows, outputDir: outputDir)
            case "vertical":
                outputURLs = splitImageVertically(image, parts: columns, outputDir: outputDir)
            default:
                // Default to grid
                outputURLs = splitImageIntoGrid(image, rows: rows, columns: columns, outputDir: outputDir)
            }
            
            if !outputURLs.isEmpty {
                // Store the result paths for later retrieval
                let paths = outputURLs.map { $0.path }
                UserDefaults.standard.set(paths, forKey: "last_shortcut_result_paths")
                
                // Create a notification to inform the user
                showNotification(
                    title: "Image Splitting Complete",
                    body: "Image has been split into \(outputURLs.count) parts",
                    success: true
                )
                
                completion(true, nil)
            } else {
                // Handle error
                let error = NSError(domain: "com.llmbuddy.shortcuts", code: 1008, userInfo: [NSLocalizedDescriptionKey: "Failed to split image"])
                completion(false, error)
            }
        } catch {
            // Handle error
            showNotification(
                title: "Image Splitting Failed", 
                body: "Error: \(error.localizedDescription)",
                success: false
            )
            
            completion(false, error)
        }
    }
    
    /// Split image into a grid
    /// - Parameters:
    ///   - image: The image to split
    ///   - rows: The number of rows
    ///   - columns: The number of columns
    ///   - outputDir: The directory to save the split images
    /// - Returns: The URLs of the split images
    private func splitImageIntoGrid(_ image: UIImage, rows: Int, columns: Int, outputDir: URL) -> [URL] {
        let width = image.size.width
        let height = image.size.height
        let tileWidth = width / CGFloat(columns)
        let tileHeight = height / CGFloat(rows)
        
        var outputURLs: [URL] = []
        
        for row in 0..<rows {
            for column in 0..<columns {
                // Calculate the tile's frame
                let x = CGFloat(column) * tileWidth
                let y = CGFloat(row) * tileHeight
                let rect = CGRect(x: x, y: y, width: tileWidth, height: tileHeight)
                
                // Extract the tile
                if let cgImage = image.cgImage?.cropping(to: rect) {
                    let tileImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
                    
                    // Save the tile to the output directory
                    let fileName = "tile_r\(row + 1)_c\(column + 1).jpg"
                    let outputURL = outputDir.appendingPathComponent(fileName)
                    
                    if let jpegData = tileImage.jpegData(compressionQuality: 0.9) {
                        do {
                            try jpegData.write(to: outputURL)
                            outputURLs.append(outputURL)
                        } catch {
                            print("Error saving tile: \(error)")
                        }
                    }
                }
            }
        }
        
        return outputURLs
    }
    
    /// Split image horizontally
    /// - Parameters:
    ///   - image: The image to split
    ///   - parts: The number of parts
    ///   - outputDir: The directory to save the split images
    /// - Returns: The URLs of the split images
    private func splitImageHorizontally(_ image: UIImage, parts: Int, outputDir: URL) -> [URL] {
        let width = image.size.width
        let height = image.size.height
        let partHeight = height / CGFloat(parts)
        
        var outputURLs: [URL] = []
        
        for part in 0..<parts {
            // Calculate the part's frame
            let x: CGFloat = 0
            let y = CGFloat(part) * partHeight
            let rect = CGRect(x: x, y: y, width: width, height: partHeight)
            
            // Extract the part
            if let cgImage = image.cgImage?.cropping(to: rect) {
                let partImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
                
                // Save the part to the output directory
                let fileName = "horizontal_part_\(part + 1).jpg"
                let outputURL = outputDir.appendingPathComponent(fileName)
                
                if let jpegData = partImage.jpegData(compressionQuality: 0.9) {
                    do {
                        try jpegData.write(to: outputURL)
                        outputURLs.append(outputURL)
                    } catch {
                        print("Error saving part: \(error)")
                    }
                }
            }
        }
        
        return outputURLs
    }
    
    /// Split image vertically
    /// - Parameters:
    ///   - image: The image to split
    ///   - parts: The number of parts
    ///   - outputDir: The directory to save the split images
    /// - Returns: The URLs of the split images
    private func splitImageVertically(_ image: UIImage, parts: Int, outputDir: URL) -> [URL] {
        let width = image.size.width
        let height = image.size.height
        let partWidth = width / CGFloat(parts)
        
        var outputURLs: [URL] = []
        
        for part in 0..<parts {
            // Calculate the part's frame
            let x = CGFloat(part) * partWidth
            let y: CGFloat = 0
            let rect = CGRect(x: x, y: y, width: partWidth, height: height)
            
            // Extract the part
            if let cgImage = image.cgImage?.cropping(to: rect) {
                let partImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
                
                // Save the part to the output directory
                let fileName = "vertical_part_\(part + 1).jpg"
                let outputURL = outputDir.appendingPathComponent(fileName)
                
                if let jpegData = partImage.jpegData(compressionQuality: 0.9) {
                    do {
                        try jpegData.write(to: outputURL)
                        outputURLs.append(outputURL)
                    } catch {
                        print("Error saving part: \(error)")
                    }
                }
            }
        }
        
        return outputURLs
    }
}