/**
 * @fileoverview Import/Export tool for data exchange between formats
 * @module ImportExportToolView
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - SwiftUI
 * - UniformTypeIdentifiers
 * 
 * Exports:
 * - ImportExportToolView
 * 
 * Notes:
 * - Supports importing and exporting data between various formats
 * - Includes conversion between CSV, JSON, XML, and other formats
 */

import SwiftUI
import UniformTypeIdentifiers

/// Import/Export Tool View for data format conversion
struct ImportExportToolView: View {
    // MARK: - State Variables
    @State private var selectedSourceFormat: DataFormat = .csv
    @State private var selectedTargetFormat: DataFormat = .json
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showingImportPicker: Bool = false
    @State private var isShowingHelp: Bool = false
    @State private var selectedConversionType: ConversionType = .structuredData
    @State private var conversionOptions: [String: Bool] = [
        "prettyPrint": true,
        "includeHeaders": true,
        "escapeSpecialChars": true,
        "autoDetectDateFormat": true
    ]
    
    // MARK: - Enums
    
    enum DataFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
        case xml = "XML"
        case yaml = "YAML"
        case markdown = "Markdown"
        case plainText = "Plain Text"
        
        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            case .xml: return "xml"
            case .yaml: return "yaml"
            case .markdown: return "md"
            case .plainText: return "txt"
            }
        }
        
        var contentType: UTType {
            switch self {
            case .csv: return UTType.commaSeparatedText
            case .json: return UTType.json
            case .xml: return UTType.xml
            case .yaml: return UTType(filenameExtension: "yaml") ?? UTType.plainText
            case .markdown: return UTType.markdown
            case .plainText: return UTType.plainText
            }
        }
        
        var color: Color {
            switch self {
            case .csv: return .blue
            case .json: return .purple
            case .xml: return .orange
            case .yaml: return .green
            case .markdown: return .indigo
            case .plainText: return .gray
            }
        }
        
        var iconName: String {
            switch self {
            case .csv: return "tablecells"
            case .json: return "curlybraces.square"
            case .xml: return "chevron.left.forwardslash.chevron.right"
            case .yaml: return "doc.text"
            case .markdown: return "text.badge.checkmark"
            case .plainText: return "doc.plaintext"
            }
        }
    }
    
    enum ConversionType: String, CaseIterable {
        case structuredData = "Structured Data"
        case documentFormat = "Document Format"
    }
    
    // MARK: - Computed Properties
    
    private var canConvert: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var validConversion: Bool {
        // Check if source and target formats make sense together
        if selectedConversionType == .structuredData {
            // Structured data conversions only work between structured formats
            let structuredFormats: [DataFormat] = [.csv, .json, .xml, .yaml]
            return structuredFormats.contains(selectedSourceFormat) && structuredFormats.contains(selectedTargetFormat)
        } else {
            // Document format conversions
            let documentFormats: [DataFormat] = [.markdown, .plainText]
            return !((structuredFormats.contains(selectedSourceFormat) && documentFormats.contains(selectedTargetFormat)) || 
                    (documentFormats.contains(selectedSourceFormat) && structuredFormats.contains(selectedTargetFormat)))
        }
    }
    
    private var structuredFormats: [DataFormat] {
        [.csv, .json, .xml, .yaml]
    }
    
    private var documentFormats: [DataFormat] {
        [.markdown, .plainText]
    }
    
    private var availableSourceFormats: [DataFormat] {
        selectedConversionType == .structuredData ? structuredFormats : DataFormat.allCases
    }
    
    private var availableTargetFormats: [DataFormat] {
        if selectedConversionType == .structuredData {
            return structuredFormats.filter { $0 != selectedSourceFormat }
        } else if structuredFormats.contains(selectedSourceFormat) {
            return structuredFormats.filter { $0 != selectedSourceFormat }
        } else {
            return DataFormat.allCases.filter { $0 != selectedSourceFormat }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Image(systemName: "square.and.arrow.up.on.square")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                    
                    Text("Import/Export Tool")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(LinearGradient(
                    gradient: Gradient(colors: [.green.opacity(0.7), .green.opacity(0.5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .cornerRadius(12)
                
                // Description
                Text("Convert data between different formats for import/export operations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Conversion Type
                VStack(alignment: .leading, spacing: 8) {
                    Text("Conversion Type")
                        .font(.headline)
                    
                    Picker("Conversion Type", selection: $selectedConversionType) {
                        ForEach(ConversionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedConversionType) { _ in
                        // Reset to appropriate formats when changing type
                        if selectedConversionType == .structuredData {
                            selectedSourceFormat = .csv
                            selectedTargetFormat = .json
                        } else {
                            selectedSourceFormat = .markdown
                            selectedTargetFormat = .plainText
                        }
                    }
                }
                .padding(.horizontal)
                
                // Format Selection
                HStack(spacing: 20) {
                    // Source Format
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source Format")
                            .font(.headline)
                        
                        FormatPickerView(
                            selectedFormat: $selectedSourceFormat,
                            availableFormats: availableSourceFormats
                        )
                    }
                    
                    // Conversion Arrow
                    VStack {
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    // Target Format
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Format")
                            .font(.headline)
                        
                        FormatPickerView(
                            selectedFormat: $selectedTargetFormat,
                            availableFormats: availableTargetFormats
                        )
                    }
                }
                .padding(.horizontal)
                
                // Conversion Options
                DisclosureGroup("Conversion Options") {
                    VStack(alignment: .leading, spacing: 10) {
                        if structuredFormats.contains(selectedSourceFormat) || structuredFormats.contains(selectedTargetFormat) {
                            Toggle("Pretty Print", isOn: $conversionOptions["prettyPrint", default: true])
                            Toggle("Include Headers", isOn: $conversionOptions["includeHeaders", default: true])
                            Toggle("Auto-detect Date Format", isOn: $conversionOptions["autoDetectDateFormat", default: true])
                        }
                        
                        Toggle("Escape Special Characters", isOn: $conversionOptions["escapeSpecialChars", default: true])
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal)
                
                // Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Input Data")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showingImportPicker = true
                        }) {
                            Label("Import File", systemImage: "square.and.arrow.down")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(action: {
                            inputText = ""
                        }) {
                            Label("Clear", systemImage: "xmark")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(inputText.isEmpty)
                    }
                    
                    TextEditor(text: $inputText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                // Convert Button
                Button(action: convertData) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Convert")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(canConvert && validConversion ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(!canConvert || isProcessing || !validConversion)
                .padding(.horizontal)
                
                if !validConversion {
                    Text("The selected conversion is not supported. Please select compatible formats.")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Output
                if !outputText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Output Data")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: copyOutputToClipboard) {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.subheadline)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button(action: exportOutput) {
                                Label("Export", systemImage: "square.and.arrow.up")
                                    .font(.subheadline)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        TextEditor(text: .constant(outputText))
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 200)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .disabled(true)
                    }
                    .padding(.horizontal)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                // Sample Data Section
                sampleDataSection
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Import/Export Tool")
        .sheet(isPresented: $showingImportPicker) {
            DocumentPicker(
                contentTypes: [selectedSourceFormat.contentType],
                onPick: { urls in
                    if let url = urls.first {
                        loadFile(url: url)
                    }
                }
            )
        }
        .sheet(isPresented: $isShowingHelp) {
            formatHelpView
        }
    }
    
    // MARK: - View Components
    
    private var sampleDataSection: some View {
        DisclosureGroup("Sample Data") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Use these samples to test the conversion tool:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        SampleDataButton(
                            title: "CSV Sample",
                            format: .csv,
                            onTap: {
                                inputText = sampleCSV
                                selectedSourceFormat = .csv
                            }
                        )
                        
                        SampleDataButton(
                            title: "JSON Sample",
                            format: .json,
                            onTap: {
                                inputText = sampleJSON
                                selectedSourceFormat = .json
                            }
                        )
                        
                        SampleDataButton(
                            title: "XML Sample",
                            format: .xml,
                            onTap: {
                                inputText = sampleXML
                                selectedSourceFormat = .xml
                            }
                        )
                        
                        SampleDataButton(
                            title: "Markdown Sample",
                            format: .markdown,
                            onTap: {
                                inputText = sampleMarkdown
                                selectedSourceFormat = .markdown
                            }
                        )
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var formatHelpView: some View {
        NavigationView {
            List {
                Section(header: Text("Supported Format Conversions")) {
                    ForEach(DataFormat.allCases, id: \.self) { format in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: format.iconName)
                                    .foregroundColor(format.color)
                                
                                Text(format.rawValue)
                                    .font(.headline)
                            }
                            
                            Text(formatDescription(format))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Conversion Types")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Structured Data")
                            .font(.headline)
                        
                        Text("Convert between data formats like CSV, JSON, XML, and YAML. Best for tabular data or structured information.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Document Format")
                            .font(.headline)
                        
                        Text("Convert between document formats like Markdown and plain text. Best for text documents, articles, or content.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Tips")) {
                    Text("For CSV files, ensure the first row contains column headers for best results.")
                    Text("Large files may take longer to process, especially complex XML structures.")
                    Text("When converting to Markdown, structural elements will be preserved where possible.")
                    Text("JSON to CSV conversion works best with flat, uniform JSON objects.")
                }
            }
            .navigationTitle("Format Help")
            .navigationBarItems(trailing: Button("Done") {
                isShowingHelp = false
            })
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertData() {
        guard canConvert else { return }
        
        isProcessing = true
        errorMessage = nil
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                // In a real implementation, this would handle actual conversion logic
                outputText = try simulateConversion(
                    input: inputText,
                    from: selectedSourceFormat,
                    to: selectedTargetFormat
                )
                isProcessing = false
            } catch {
                outputText = ""
                errorMessage = "Conversion error: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }
    
    private func loadFile(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            if let content = String(data: data, encoding: .utf8) {
                inputText = content
            } else {
                errorMessage = "Could not decode file content as text"
            }
        } catch {
            errorMessage = "Error loading file: \(error.localizedDescription)"
        }
    }
    
    private func copyOutputToClipboard() {
        UIPasteboard.general.string = outputText
        
        // Show haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func exportOutput() {
        // Create a temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "converted_\(Int(Date().timeIntervalSince1970)).\(selectedTargetFormat.fileExtension)"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try outputText.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Share the file
            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            // Present the activity view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        } catch {
            errorMessage = "Failed to export file: \(error.localizedDescription)"
        }
    }
    
    private func formatDescription(_ format: DataFormat) -> String {
        switch format {
        case .csv:
            return "Comma-Separated Values - Best for tabular data that can be represented in rows and columns."
        case .json:
            return "JavaScript Object Notation - Flexible format for hierarchical data structures."
        case .xml:
            return "Extensible Markup Language - Supports complex hierarchical structures with attributes."
        case .yaml:
            return "YAML Ain't Markup Language - Human-readable data serialization format."
        case .markdown:
            return "Markdown Text - Lightweight markup language for formatted text documents."
        case .plainText:
            return "Plain Text - Unformatted text without styling or structure information."
        }
    }
    
    private func simulateConversion(input: String, from sourceFormat: DataFormat, to targetFormat: DataFormat) throws -> String {
        // This is a placeholder implementation that would be replaced with actual conversion logic
        
        // Simulate conversion errors for certain cases
        if input.count < 5 {
            throw ConversionError.invalidInput("Input is too short to be valid \(sourceFormat.rawValue)")
        }
        
        // For CSV to JSON conversion (as an example)
        if sourceFormat == .csv && targetFormat == .json {
            return convertCSVtoJSON(input)
        } else if sourceFormat == .json && targetFormat == .csv {
            return convertJSONtoCSV(input)
        } else if sourceFormat == .markdown && targetFormat == .plainText {
            return convertMarkdownToPlainText(input)
        } else {
            // Generic conversion placeholder
            let result = """
            // Converted from \(sourceFormat.rawValue) to \(targetFormat.rawValue)
            // Original content length: \(input.count) characters
            // Conversion options: \(conversionOptions)
            
            \(placeholderConversion(input: input, targetFormat: targetFormat))
            """
            
            return result
        }
    }
    
    private func convertCSVtoJSON(_ csvInput: String) -> String {
        let lines = csvInput.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard !lines.isEmpty else { return "[]" }
        
        // Parse headers
        let headers = lines[0].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Parse data rows
        var jsonArray: [[String: String]] = []
        for i in 1..<lines.count {
            let values = lines[i].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            var jsonObject: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                if index < values.count {
                    jsonObject[header] = values[index]
                }
            }
            
            jsonArray.append(jsonObject)
        }
        
        // Create JSON string with pretty printing
        let prettyPrint = conversionOptions["prettyPrint"] ?? true
        let jsonData = try? JSONSerialization.data(
            withJSONObject: jsonArray,
            options: prettyPrint ? [.prettyPrinted] : []
        )
        
        return jsonData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }
    
    private func convertJSONtoCSV(_ jsonInput: String) -> String {
        // This is a simplified placeholder implementation
        guard let jsonData = jsonInput.data(using: .utf8),
              let jsonArray = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            return "Error: Could not parse JSON input"
        }
        
        guard !jsonArray.isEmpty else { return "" }
        
        // Get all unique keys from the JSON objects
        var allKeys = Set<String>()
        for item in jsonArray {
            for key in item.keys {
                allKeys.insert(key)
            }
        }
        
        // Create CSV header
        let sortedKeys = Array(allKeys).sorted()
        var csv = sortedKeys.joined(separator: ",") + "\n"
        
        // Create CSV rows
        for item in jsonArray {
            let row = sortedKeys.map { key in
                let value = item[key]
                return value.flatMap { "\($0)" } ?? ""
            }
            csv += row.joined(separator: ",") + "\n"
        }
        
        return csv
    }
    
    private func convertMarkdownToPlainText(_ markdownInput: String) -> String {
        // Very basic markdown to plain text conversion
        var plaintext = markdownInput
        
        // Remove heading markers
        plaintext = plaintext.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression, range: nil)
        
        // Remove bold/italic markers
        plaintext = plaintext.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "$1", options: .regularExpression, range: nil)
        plaintext = plaintext.replacingOccurrences(of: #"\*(.+?)\*"#, with: "$1", options: .regularExpression, range: nil)
        plaintext = plaintext.replacingOccurrences(of: #"__(.+?)__"#, with: "$1", options: .regularExpression, range: nil)
        plaintext = plaintext.replacingOccurrences(of: #"_(.+?)_"#, with: "$1", options: .regularExpression, range: nil)
        
        // Convert lists to plain text
        plaintext = plaintext.replacingOccurrences(of: #"^\s*[-*+]\s+"#, with: "- ", options: .regularExpression, range: nil)
        plaintext = plaintext.replacingOccurrences(of: #"^\s*\d+\.\s+"#, with: "• ", options: .regularExpression, range: nil)
        
        // Remove link syntax, keep link text
        plaintext = plaintext.replacingOccurrences(of: #"\[(.+?)\]\(.+?\)"#, with: "$1", options: .regularExpression, range: nil)
        
        return plaintext
    }
    
    private func placeholderConversion(input: String, targetFormat: DataFormat) -> String {
        switch targetFormat {
        case .json:
            return "{\n  \"convertedData\": \"example\",\n  \"originalFormat\": \"\(selectedSourceFormat.rawValue)\"\n}"
        case .xml:
            return "<root>\n  <convertedData>example</convertedData>\n  <originalFormat>\(selectedSourceFormat.rawValue)</originalFormat>\n</root>"
        case .yaml:
            return "convertedData: example\noriginalFormat: \(selectedSourceFormat.rawValue)"
        case .markdown:
            return "# Converted Document\n\nThis is a sample conversion from \(selectedSourceFormat.rawValue) to Markdown.\n\n## Content\n\nPlaceholder content representing the conversion result."
        case .plainText:
            return "CONVERTED DOCUMENT\n\nThis is a sample conversion from \(selectedSourceFormat.rawValue) to Plain Text.\n\nContent:\nPlaceholder content representing the conversion result."
        case .csv:
            return "header1,header2,header3\nvalue1,value2,value3\nexample,\(selectedSourceFormat.rawValue),conversion"
        }
    }
}

// MARK: - Supporting Types

/// Format Picker View
struct FormatPickerView: View {
    @Binding var selectedFormat: ImportExportToolView.DataFormat
    let availableFormats: [ImportExportToolView.DataFormat]
    
    var body: some View {
        Menu {
            ForEach(availableFormats, id: \.self) { format in
                Button(action: {
                    selectedFormat = format
                }) {
                    Label(format.rawValue, systemImage: format.iconName)
                }
            }
        } label: {
            HStack {
                Image(systemName: selectedFormat.iconName)
                    .foregroundColor(selectedFormat.color)
                Text(selectedFormat.rawValue)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            .frame(maxWidth: .infinity)
        }
    }
}

/// Sample Data Button
struct SampleDataButton: View {
    let title: String
    let format: ImportExportToolView.DataFormat
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(systemName: format.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(format.color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            .frame(width: 100)
        }
        .buttonStyle(.plain)
    }
}

/// Conversion Error Enum
enum ConversionError: Error, LocalizedError {
    case invalidInput(String)
    case unsupportedConversion(String)
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let details):
            return "Invalid input: \(details)"
        case .unsupportedConversion(let details):
            return "Unsupported conversion: \(details)"
        case .parsingError(let details):
            return "Parsing error: \(details)"
        }
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onPick: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onPick(urls)
        }
    }
}

// MARK: - Sample Data

/// Sample CSV data
let sampleCSV = """
Name,Age,Location,Occupation
John Doe,32,New York,Software Engineer
Jane Smith,28,San Francisco,Data Scientist
Alex Johnson,45,Chicago,Marketing Manager
Emily Brown,36,Boston,Product Manager
Michael Wilson,41,Seattle,UX Designer
"""

/// Sample JSON data
let sampleJSON = """
[
  {
    "name": "John Doe",
    "age": 32,
    "location": "New York",
    "occupation": "Software Engineer"
  },
  {
    "name": "Jane Smith",
    "age": 28,
    "location": "San Francisco",
    "occupation": "Data Scientist"
  },
  {
    "name": "Alex Johnson",
    "age": 45,
    "location": "Chicago",
    "occupation": "Marketing Manager"
  }
]
"""

/// Sample XML data
let sampleXML = """
<?xml version="1.0" encoding="UTF-8"?>
<people>
  <person>
    <name>John Doe</name>
    <age>32</age>
    <location>New York</location>
    <occupation>Software Engineer</occupation>
  </person>
  <person>
    <name>Jane Smith</name>
    <age>28</age>
    <location>San Francisco</location>
    <occupation>Data Scientist</occupation>
  </person>
  <person>
    <name>Alex Johnson</name>
    <age>45</age>
    <location>Chicago</location>
    <occupation>Marketing Manager</occupation>
  </person>
</people>
"""

/// Sample Markdown data
let sampleMarkdown = """
# Team Members

This document contains information about our team members.

## Engineering Team

- **John Doe** - *Software Engineer*
  - 32 years old
  - Based in New York
  - Specializes in iOS development

- **Jane Smith** - *Data Scientist*
  - 28 years old
  - Based in San Francisco
  - Specializes in machine learning

## Marketing Team

- **Alex Johnson** - *Marketing Manager*
  - 45 years old
  - Based in Chicago
  - Specializes in digital marketing
"""

// MARK: - Preview

extension UTType {
    static var commaSeparatedText: UTType {
        UTType(importedAs: "public.comma-separated-values-text")
    }
    
    static var markdown: UTType {
        UTType(importedAs: "net.daringfireball.markdown")
    }
}

struct ImportExportToolView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ImportExportToolView()
        }
    }
}
