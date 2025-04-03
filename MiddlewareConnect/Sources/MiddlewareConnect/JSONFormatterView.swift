/**
@fileoverview JSON Formatter for formatting and validating JSON data
@module JSONFormatterView
Created: 2025-04-01
Last Modified: 2025-04-01
Dependencies:
- SwiftUI
Exports:
- JSONFormatterView
/

import SwiftUI
import UniformTypeIdentifiers

struct JSONFormatterView: View {
    // MARK: - State Variables
    @State private var inputJSON: String = ""
    @State private var outputJSON: String = ""
    @State private var isValidating: Bool = false
    @State private var isFormatting: Bool = false
    @State private var isMinifying: Bool = false
    @State private var formatIndentation: Int = 2
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var isImportingFile: Bool = false
    @State private var fileName: String = ""
    @State private var isComparing: Bool = false
    @State private var secondJSON: String = ""
    @State private var showInfo: Bool = false
    @State private var isExporting: Bool = false
    
    // Syntax highlighting
    @State private var highlightedJSON: NSAttributedString = NSAttributedString()
    @State private var shouldHighlight: Bool = true
    
    // MARK: - Computed Properties
    var buttonDisabled: Bool {
        inputJSON.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var indentationSteps: [Int] {
        return [2, 4, 8]
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "curlybraces")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("JSON Formatter")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 5)
                
                Text("Format, validate, and manipulate JSON data for optimal readability")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // Input Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Input JSON")
                        .font(.headline)
                    
                    if !fileName.isEmpty {
                        // Show file name if imported
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text(fileName)
                                .font(.subheadline)
                            Spacer()
                            Button(action: {
                                fileName = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    
                    // Text editor for input
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $inputJSON)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 200)
                            .padding(5)
                            .onChange(of: inputJSON) { _ in
                                if shouldHighlight {
                                    highlightJSON()
                                }
                            }
                        
                        if inputJSON.isEmpty {
                            Text("Paste your JSON here...")
                                .foregroundColor(.gray)
                                .font(.system(.body, design: .monospaced))
                                .padding(10)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Import button
                    Button(action: {
                        isImportingFile = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Import JSON File")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical)
                
                // Format Options
                VStack(alignment: .leading, spacing: 10) {
                    Text("2. Format Options")
                        .font(.headline)
                    
                    HStack {
                        Text("Indentation:")
                        
                        Picker("", selection: $formatIndentation) {
                            ForEach(indentationSteps, id: \.self) { step in
                                Text("\(step) spaces").tag(step)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    // Options grid
                    VStack(spacing: 12) {
                        // Format row
                        HStack {
                            Button(action: {
                                formatJSON(pretty: true)
                            }) {
                                VStack {
                                    Image(systemName: "text.alignleft")
                                        .font(.system(size: 28))
                                    Text("Pretty Print")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                formatJSON(pretty: false)
                            }) {
                                VStack {
                                    Image(systemName: "text.alignleft.indent")
                                        .font(.system(size: 28))
                                    Text("Minify")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                validateJSON()
                            }) {
                                VStack {
                                    Image(systemName: "checkmark.seal")
                                        .font(.system(size: 28))
                                    Text("Validate")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                        }
                        
                        // Advanced row
                        HStack {
                            Button(action: {
                                sortKeys()
                            }) {
                                VStack {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.system(size: 28))
                                    Text("Sort Keys")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                toggleCompare()
                            }) {
                                VStack {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(size: 28))
                                    Text("Compare")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                formatJSON(pretty: true)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    copyToClipboard(text: outputJSON)
                                }
                            }) {
                                VStack {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 28))
                                    Text("Copy")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .disabled(buttonDisabled)
                    .opacity(buttonDisabled ? 0.5 : 1.0)
                }
                .padding(.vertical)
                
                // Comparison section (conditional)
                if isComparing {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("JSON Comparison")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                isComparing = false
                                secondJSON = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        TextEditor(text: $secondJSON)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 150)
                            .padding(5)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Button(action: {
                            compareJSON()
                        }) {
                            Text("Compare JSONs")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(inputJSON.isEmpty || secondJSON.isEmpty)
                    }
                    .padding(.vertical)
                }
                
                // Output Section
                if !outputJSON.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("3. Formatted Output")
                            .font(.headline)
                        
                        ScrollView {
                            Text(outputJSON)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                        .frame(minHeight: 150, maxHeight: 300)
                        
                        // Actions row
                        HStack {
                            Button(action: {
                                copyToClipboard(text: outputJSON)
                            }) {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copy")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                inputJSON = outputJSON
                                outputJSON = ""
                            }) {
                                HStack {
                                    Image(systemName: "arrow.up")
                                    Text("Use as Input")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                isExporting = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                
                // JSON Stats (if output exists)
                if !outputJSON.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("JSON Statistics")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            HStack {
                                Text("Size:")
                                Spacer()
                                Text(formatByteSize(outputJSON.utf8.count))
                            }
                            
                            HStack {
                                Text("Characters:")
                                Spacer()
                                Text("\(outputJSON.count)")
                            }
                            
                            HStack {
                                Text("Structure:")
                                Spacer()
                                if let structure = analyzeJSONStructure() {
                                    Text(structure)
                                } else {
                                    Text("Invalid JSON")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                    .padding(.vertical)
                }
            }
            .padding()
            .navigationTitle("JSON Formatter")
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("JSON Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .fileImporter(
                isPresented: $isImportingFile,
                allowedContentTypes: [UTType.json, UTType.text],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile = try result.get().first else { return }
                    
                    if selectedFile.startAccessingSecurityScopedResource() {
                        defer { selectedFile.stopAccessingSecurityScopedResource() }
                        
                        if let data = try? Data(contentsOf: selectedFile),
                           let content = String(data: data, encoding: .utf8) {
                            inputJSON = content
                            fileName = selectedFile.lastPathComponent
                            highlightJSON()
                        }
                    }
                } catch {
                    errorMessage = "Error importing file: \(error.localizedDescription)"
                    showError = true
                }
            }
            .overlay(
                Group {
                    if isValidating || isFormatting || isMinifying {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                            
                            Text(isValidating ? "Validating..." : (isFormatting ? "Formatting..." : "Minifying..."))
                                .padding(.top)
                        }
                        .frame(width: 150, height: 150)
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(20)
                    }
                }
            )
            .alert("JSON Formatter", isPresented: $showInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This tool helps you format, validate, and manipulate JSON data. You can pretty-print JSON with custom indentation, minify it to save space, or validate it to check for syntax errors. Advanced features include sorting keys alphabetically and comparing two JSON structures.")
            }
        }
    }
    
    // MARK: - Methods
    
    private func formatJSON(pretty: Bool) {
        guard !inputJSON.isEmpty else { return }
        
        if pretty {
            isFormatting = true
        } else {
            isMinifying = true
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Parse JSON
                guard let jsonData = inputJSON.data(using: .utf8),
                      let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) else {
                    DispatchQueue.main.async {
                        errorMessage = "Invalid JSON input. Please check the syntax."
                        showError = true
                        isFormatting = false
                        isMinifying = false
                    }
                    return
                }
                
                // Format JSON
                let outputData: Data
                
                if pretty {
                    // Pretty printing with specified indentation
                    outputData = try JSONSerialization.data(
                        withJSONObject: jsonObject,
                        options: [.prettyPrinted]
                    )
                    
                    // Apply custom indentation if needed
                    var formattedString = String(data: outputData, encoding: .utf8) ?? ""
                    
                    // Replace default indentation (2 spaces) with the custom indentation
                    if formatIndentation != 2 {
                        let defaultIndent = "  " // 2 spaces
                        let customIndent = String(repeating: " ", count: formatIndentation)
                        formattedString = formattedString.replacingOccurrences(of: defaultIndent, with: customIndent)
                    }
                    
                    DispatchQueue.main.async {
                        outputJSON = formattedString
                        isFormatting = false
                        isMinifying = false
                    }
                } else {
                    // Minifying - no pretty print option
                    outputData = try JSONSerialization.data(
                        withJSONObject: jsonObject,
                        options: []
                    )
                    
                    DispatchQueue.main.async {
                        outputJSON = String(data: outputData, encoding: .utf8) ?? ""
                        isFormatting = false
                        isMinifying = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Error formatting JSON: \(error.localizedDescription)"
                    showError = true
                    isFormatting = false
                    isMinifying = false
                }
            }
        }
    }
    
    private func validateJSON() {
        guard !inputJSON.isEmpty else { return }
        
        isValidating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Try to parse the JSON
                guard let jsonData = inputJSON.data(using: .utf8) else {
                    DispatchQueue.main.async {
                        errorMessage = "Invalid text encoding. The input does not appear to be valid UTF-8."
                        showError = true
                        isValidating = false
                    }
                    return
                }
                
                let _ = try JSONSerialization.jsonObject(with: jsonData, options: [.allowFragments])
                
                // If we reached here, JSON is valid
                DispatchQueue.main.async {
                    outputJSON = "✅ JSON is valid."
                    isValidating = false
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    errorMessage = "JSON validation failed: \(error.localizedDescription)"
                    if let underlyingError = error.userInfo["NSDebugDescription"] as? String {
                        errorMessage += "\n\nDetails: \(underlyingError)"
                    }
                    showError = true
                    outputJSON = "❌ JSON is invalid. See error details."
                    isValidating = false
                }
            }
        }
    }
    
    private func sortKeys() {
        guard !inputJSON.isEmpty else { return }
        
        isFormatting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Parse JSON
                guard let jsonData = inputJSON.data(using: .utf8),
                      let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) else {
                    DispatchQueue.main.async {
                        errorMessage = "Invalid JSON input. Please check the syntax."
                        showError = true
                        isFormatting = false
                    }
                    return
                }
                
                // Sort keys recursively
                let sortedObject = sortJSONObject(jsonObject)
                
                // Format the result
                let outputData = try JSONSerialization.data(
                    withJSONObject: sortedObject,
                    options: [.prettyPrinted]
                )
                
                // Apply custom indentation if needed
                var formattedString = String(data: outputData, encoding: .utf8) ?? ""
                
                // Replace default indentation (2 spaces) with the custom indentation
                if formatIndentation != 2 {
                    let defaultIndent = "  " // 2 spaces
                    let customIndent = String(repeating: " ", count: formatIndentation)
                    formattedString = formattedString.replacingOccurrences(of: defaultIndent, with: customIndent)
                }
                
                DispatchQueue.main.async {
                    outputJSON = formattedString
                    isFormatting = false
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Error sorting JSON keys: \(error.localizedDescription)"
                    showError = true
                    isFormatting = false
                }
            }
        }
    }
    
    private func sortJSONObject(_ object: Any) -> Any {
        if let dictionary = object as? [String: Any] {
            var result = [String: Any]()
            
            // Sort the keys and recursively sort any nested objects
            let sortedKeys = dictionary.keys.sorted()
            for key in sortedKeys {
                result[key] = sortJSONObject(dictionary[key]!)
            }
            
            return result
        } else if let array = object as? [Any] {
            // Recursively sort objects in arrays
            return array.map { sortJSONObject($0) }
        } else {
            // Return primitive values as-is
            return object
        }
    }
    
    private func toggleCompare() {
        isComparing.toggle()
        if isComparing && !outputJSON.isEmpty {
            secondJSON = outputJSON
            outputJSON = ""
        }
    }
    
    private func compareJSON() {
        guard !inputJSON.isEmpty && !secondJSON.isEmpty else { return }
        
        isFormatting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Parse both JSON inputs
                guard let jsonData1 = inputJSON.data(using: .utf8),
                      let jsonObject1 = try? JSONSerialization.jsonObject(with: jsonData1, options: []),
                      let jsonData2 = secondJSON.data(using: .utf8),
                      let jsonObject2 = try? JSONSerialization.jsonObject(with: jsonData2, options: []) else {
                    DispatchQueue.main.async {
                        errorMessage = "One or both JSON inputs are invalid. Please check the syntax."
                        showError = true
                        isFormatting = false
                    }
                    return
                }
                
                // Compare the JSON objects
                let differences = compareJSONObjects(jsonObject1, jsonObject2)
                
                DispatchQueue.main.async {
                    if differences.isEmpty {
                        outputJSON = "✅ The JSON structures are identical."
                    } else {
                        outputJSON = "❌ Found differences:\n\n" + differences.joined(separator: "\n")
                    }
                    isFormatting = false
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Error comparing JSON: \(error.localizedDescription)"
                    showError = true
                    isFormatting = false
                }
            }
        }
    }
    
    private func compareJSONObjects(_ object1: Any, _ object2: Any, path: String = "root") -> [String] {
        var differences = [String]()
        
        // Check if types are different
        if type(of: object1) != type(of: object2) {
            differences.append("\(path): Type mismatch - \(type(of: object1)) vs \(type(of: object2))")
            return differences
        }
        
        if let dict1 = object1 as? [String: Any], let dict2 = object2 as? [String: Any] {
            // Compare dictionaries
            let allKeys = Set(dict1.keys).union(Set(dict2.keys))
            
            for key in allKeys {
                if dict1[key] == nil {
                    differences.append("\(path).\(key): Key exists only in second JSON")
                } else if dict2[key] == nil {
                    differences.append("\(path).\(key): Key exists only in first JSON")
                } else {
                    differences.append(contentsOf: compareJSONObjects(dict1[key]!, dict2[key]!, path: "\(path).\(key)"))
                }
            }
        } else if let array1 = object1 as? [Any], let array2 = object2 as? [Any] {
            // Compare arrays
            if array1.count != array2.count {
                differences.append("\(path): Array length mismatch - \(array1.count) vs \(array2.count)")
            }
            
            let minCount = min(array1.count, array2.count)
            for i in 0..<minCount {
                differences.append(contentsOf: compareJSONObjects(array1[i], array2[i], path: "\(path)[\(i)]"))
            }
        } else if !areEqual(object1, object2) {
            // Compare primitive values
            differences.append("\(path): Value mismatch - \(object1) vs \(object2)")
        }
        
        return differences
    }
    
    private func areEqual(_ value1: Any, _ value2: Any) -> Bool {
        // Compare primitive values
        if let num1 = value1 as? NSNumber, let num2 = value2 as? NSNumber {
            return num1.isEqual(to: num2)
        } else if let str1 = value1 as? String, let str2 = value2 as? String {
            return str1 == str2
        } else if let bool1 = value1 as? Bool, let bool2 = value2 as? Bool {
            return bool1 == bool2
        } else if value1 is NSNull && value2 is NSNull {
            return true
        }
        
        return false
    }
    
    private func highlightJSON() {
        guard !inputJSON.isEmpty else {
            highlightedJSON = NSAttributedString()
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let highlightedText = syntaxHighlightJSON(inputJSON)
            
            DispatchQueue.main.async {
                highlightedJSON = highlightedText
            }
        }
    }
    
    private func syntaxHighlightJSON(_ jsonString: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: jsonString)
        let entireRange = NSRange(location: 0, length: jsonString.utf16.count)
        
        // Define colors
        let keyColor = UIColor.systemBlue
        let stringColor = UIColor.systemGreen
        let numberColor = UIColor.systemOrange
        let booleanColor = UIColor.systemPurple
        let nullColor = UIColor.systemRed
        let punctuationColor = UIColor.darkGray
        
        // Apply a monospaced font to the entire string
        let font = UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize, weight: .regular)
        attributedString.addAttribute(.font, value: font, range: entireRange)
        
        // Define regex patterns
        let patterns: [(pattern: String, color: UIColor)] = [
            // Keys (with quotes and colon)
            ("\"[^\"]*\"\\s*:", keyColor),
            
            // Strings (not followed by colon, to avoid matching keys)
            ("\"[^\"]*\"(?!\\s*:)", stringColor),
            
            // Numbers
            ("\\b-?\\d+(?:\\.\\d+)?(?:[eE][+-]?\\d+)?\\b", numberColor),
            
            // Booleans
            ("\\b(?:true|false)\\b", booleanColor),
            
            // Null
            ("\\bnull\\b", nullColor),
            
            // Punctuation
            ("[\\{\\}\\[\\],]", punctuationColor)
        ]
        
        // Apply patterns
        for (pattern, color) in patterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                let matches = regex.matches(in: jsonString, options: [], range: entireRange)
                
                for match in matches {
                    attributedString.addAttribute(.foregroundColor, value: color, range: match.range)
                }
            } catch {
                print("Error creating regex: \(error.localizedDescription)")
            }
        }
        
        return attributedString
    }
    
    private func analyzeJSONStructure() -> String? {
        guard !outputJSON.isEmpty else { return nil }
        
        do {
            // Skip if the output is just a validation message
            if outputJSON.starts(with: "✅") || outputJSON.starts(with: "❌") {
                return "N/A - validation result"
            }
            
            // Parse the JSON
            guard let jsonData = outputJSON.data(using: .utf8),
                  let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) else {
                return nil
            }
            
            // Analyze the structure
            if let array = jsonObject as? [Any] {
                return "Array with \(array.count) elements"
            } else if let dict = jsonObject as? [String: Any] {
                return "Object with \(dict.count) properties"
            } else {
                return "Simple value"
            }
        } catch {
            return nil
        }
    }
    
    private func formatByteSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    private func copyToClipboard(text: String) {
        UIPasteboard.general.string = text
        
        // Show a toast or alert to indicate successful copy
        // In a real app, you might want to implement a toast notification
    }
}

struct JSONFormatterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            JSONFormatterView()
        }
    }
}
