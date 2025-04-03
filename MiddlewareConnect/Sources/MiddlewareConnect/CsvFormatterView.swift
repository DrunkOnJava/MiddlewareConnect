import SwiftUI
import UniformTypeIdentifiers

struct CsvFormatterView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var delimiter: CSVDelimiter = .comma
    @State private var hasHeader: Bool = true
    @State private var quoteFields: Bool = true
    @State private var trimWhitespace: Bool = true
    @State private var showPreview: Bool = true
    @State private var isProcessing: Bool = false
    @State private var copiedOutput: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isShowingDocumentPicker = false
    
    // Preview data
    @State private var previewData: [[String]] = []
    @State private var previewHeaders: [String] = []
    
    enum CSVDelimiter: String, CaseIterable, Identifiable {
        case comma = ","
        case tab = "\t"
        case semicolon = ";"
        case pipe = "|"
        
        var id: String { self.rawValue }
        
        var displayName: String {
            switch self {
            case .comma: return "Comma (,)"
            case .tab: return "Tab (\\t)"
            case .semicolon: return "Semicolon (;)"
            case .pipe: return "Pipe (|)"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Input Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("CSV Input")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            isShowingDocumentPicker = true
                        }) {
                            Label("Import CSV", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    TextEditor(text: $inputText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .onChange(of: inputText) { _ in
                            if !inputText.isEmpty {
                                formatCSV()
                            } else {
                                outputText = ""
                                previewData = []
                                previewHeaders = []
                            }
                        }
                }
                
                // Format Options
                VStack(alignment: .leading, spacing: 8) {
                    Text("Format Options")
                        .font(.headline)
                    
                    HStack {
                        Text("Delimiter:")
                            .font(.subheadline)
                        
                        Picker("Delimiter", selection: $delimiter) {
                            ForEach(CSVDelimiter.allCases) { delimiter in
                                Text(delimiter.displayName).tag(delimiter)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: delimiter) { _ in
                            formatCSV()
                        }
                    }
                    
                    Toggle("Has Header Row", isOn: $hasHeader)
                        .onChange(of: hasHeader) { _ in
                            formatCSV()
                        }
                    
                    Toggle("Quote Fields", isOn: $quoteFields)
                        .onChange(of: quoteFields) { _ in
                            formatCSV()
                        }
                    
                    Toggle("Trim Whitespace", isOn: $trimWhitespace)
                        .onChange(of: trimWhitespace) { _ in
                            formatCSV()
                        }
                    
                    Toggle("Show Preview Table", isOn: $showPreview)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 4)
                }
                
                // Preview Table
                if showPreview && !previewData.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.headline)
                        
                        ScrollView(.horizontal) {
                            VStack(alignment: .leading, spacing: 0) {
                                // Headers
                                if hasHeader && !previewHeaders.isEmpty {
                                    HStack(spacing: 0) {
                                        ForEach(previewHeaders.indices, id: \.self) { index in
                                            Text(previewHeaders[index])
                                                .font(.system(.caption, design: .monospaced))
                                                .fontWeight(.bold)
                                                .padding(8)
                                                .frame(minWidth: 100, alignment: .leading)
                                                .background(Color.blue.opacity(0.1))
                                                .border(Color.gray.opacity(0.2), width: 0.5)
                                        }
                                    }
                                }
                                
                                // Data rows
                                ForEach(previewData.indices, id: \.self) { rowIndex in
                                    HStack(spacing: 0) {
                                        ForEach(previewData[rowIndex].indices, id: \.self) { colIndex in
                                            Text(previewData[rowIndex][colIndex])
                                                .font(.system(.caption, design: .monospaced))
                                                .padding(8)
                                                .frame(minWidth: 100, alignment: .leading)
                                                .background(rowIndex % 2 == 0 ? Color(.systemBackground) : Color(.systemGray6))
                                                .border(Color.gray.opacity(0.2), width: 0.5)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                
                Divider()
                
                // Output Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Formatted Output")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            copyOutputToClipboard()
                        }) {
                            Label(
                                copiedOutput ? "Copied" : "Copy",
                                systemImage: copiedOutput ? "checkmark" : "doc.on.doc"
                            )
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(outputText.isEmpty)
                        
                        Button(action: {
                            exportCSV()
                        }) {
                            Label("Export", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(outputText.isEmpty)
                    }
                    
                    if outputText.isEmpty {
                        Text("Enter CSV data in the input area to see the formatted output")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
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
                }
            }
            .padding()
        }
        .navigationTitle("CSV Formatter")
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPicker(
                contentTypes: [UTType.commaSeparatedText, UTType.text],
                onPick: { urls in
                    if let url = urls.first {
                        loadCSVFile(url: url)
                    }
                }
            )
        }
    }
    
    private func formatCSV() {
        guard !inputText.isEmpty else {
            outputText = ""
            previewData = []
            previewHeaders = []
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            // Parse the input CSV
            let parsedData = try parseCSV(inputText, delimiter: delimiter.rawValue, trimWhitespace: trimWhitespace)
            
            // Generate the preview data
            if hasHeader && parsedData.count > 0 {
                previewHeaders = parsedData[0]
                previewData = Array(parsedData.dropFirst())
            } else {
                previewHeaders = []
                previewData = parsedData
            }
            
            // Format the output CSV
            outputText = formatCSVOutput(parsedData, delimiter: delimiter.rawValue, quoteFields: quoteFields)
            
            isProcessing = false
        } catch {
            errorMessage = "Error formatting CSV: \(error.localizedDescription)"
            isProcessing = false
        }
    }
    
    private func parseCSV(_ input: String, delimiter: String, trimWhitespace: Bool) throws -> [[String]] {
        var result: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in input {
            if char == "\"" {
                if insideQuotes && input.count > 0 && input.index(after: input.firstIndex(of: char)!) != input.endIndex && input[input.index(after: input.firstIndex(of: char)!)] == "\"" {
                    // Escaped quote
                    currentField.append(char)
                } else {
                    // Toggle quote state
                    insideQuotes.toggle()
                }
            } else if String(char) == delimiter && !insideQuotes {
                // End of field
                if trimWhitespace {
                    currentField = currentField.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                currentRow.append(currentField)
                currentField = ""
            } else if char == "\n" && !insideQuotes {
                // End of row
                if trimWhitespace {
                    currentField = currentField.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                currentRow.append(currentField)
                result.append(currentRow)
                currentRow = []
                currentField = ""
            } else {
                // Regular character
                currentField.append(char)
            }
        }
        
        // Add the last field and row if needed
        if !currentField.isEmpty || !currentRow.isEmpty {
            if trimWhitespace {
                currentField = currentField.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            currentRow.append(currentField)
            result.append(currentRow)
        }
        
        return result
    }
    
    private func formatCSVOutput(_ data: [[String]], delimiter: String, quoteFields: Bool) -> String {
        var result = ""
        
        for row in data {
            var formattedRow = ""
            
            for (index, field) in row.enumerated() {
                let formattedField: String
                
                if quoteFields {
                    // Escape any quotes in the field by doubling them
                    let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
                    formattedField = "\"\(escapedField)\""
                } else {
                    formattedField = field
                }
                
                formattedRow += formattedField
                
                if index < row.count - 1 {
                    formattedRow += delimiter
                }
            }
            
            result += formattedRow + "\n"
        }
        
        return result
    }
    
    private func loadCSVFile(url: URL) {
        do {
            let csvContent = try String(contentsOf: url)
            inputText = csvContent
            formatCSV()
        } catch {
            errorMessage = "Failed to load CSV file: \(error.localizedDescription)"
        }
    }
    
    private func copyOutputToClipboard() {
        UIPasteboard.general.string = outputText
        copiedOutput = true
        
        // Reset the "Copied" status after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copiedOutput = false
        }
        
        // Show a haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func exportCSV() {
        // Create a temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "formatted_csv_\(Int(Date().timeIntervalSince1970)).csv"
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
            errorMessage = "Failed to export CSV: \(error.localizedDescription)"
        }
    }
}

// Document Picker for selecting CSV files
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

// Define UTType for CSV files
extension UTType {
    static var commaSeparatedText: UTType {
        UTType(importedAs: "public.comma-separated-values-text")
    }
}

struct CsvFormatterView_Previews: PreviewProvider {
    static var previews: some View {
        CsvFormatterView()
    }
}
