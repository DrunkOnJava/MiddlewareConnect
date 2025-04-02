/**
 * @fileoverview Batch Processor tool for processing multiple files or requests
 * @module BatchProcessorView
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - SwiftUI
 * - AppState (for LLM model configuration)
 * 
 * Exports:
 * - BatchProcessorView
 * 
 * @example
 * // Basic usage example
 * BatchProcessorView()
 *     .environmentObject(AppState())
 * 
 * Notes:
 * - This view allows processing multiple files or text inputs in batch mode
 * - Supports custom prompt templates and output format configuration
 */

import SwiftUI
import UniformTypeIdentifiers

/// Batch Processor View for bulk processing multiple files or text inputs
struct BatchProcessorView: View {
    // MARK: - State Variables
    @EnvironmentObject var appState: AppState
    @State private var selectedBatchType: BatchType = .files
    @State private var prompt: String = "Summarize the following text in 3-5 sentences:"
    @State private var selectedFileTypes: [FileType] = [.pdf, .txt]
    @State private var selectedFiles: [BatchFile] = []
    @State private var outputFormat: OutputFormat = .text
    @State private var outputDirectory: URL? = nil
    @State private var isProcessing: Bool = false
    @State private var processingProgress: Double = 0.0
    @State private var processingResults: [BatchResult] = []
    @State private var showingFilePicker: Bool = false
    @State private var showingOutputPicker: Bool = false
    @State private var showingOutputOptions: Bool = false
    @State private var showSamplePrompt: Bool = false
    @State private var errorMessage: String? = nil
    
    // MARK: - Computed Properties
    
    private var canStartBatch: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedFiles.isEmpty &&
        (outputFormat != .files || outputDirectory != nil)
    }
    
    private var batchProgress: String {
        if processingResults.isEmpty {
            return "0 / \(selectedFiles.count) files processed"
        } else {
            return "\(processingResults.count) / \(selectedFiles.count) files processed"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Image(systemName: "square.stack")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                    
                    Text("Batch Processor")
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
                Text("Process multiple files or text inputs in batch mode using LLM processing.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Batch Type Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Batch Type")
                        .font(.headline)
                    
                    Picker("Batch Type", selection: $selectedBatchType) {
                        Text("Process Files").tag(BatchType.files)
                        Text("Process Text Inputs").tag(BatchType.textInputs)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                // Prompt Template
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Prompt Template")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showSamplePrompt.toggle()
                        }) {
                            Label("Examples", systemImage: "text.quote")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    TextEditor(text: $prompt)
                        .font(.body)
                        .frame(minHeight: 120)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    
                    if showSamplePrompt {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sample Prompts")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Button(action: {
                                prompt = "Summarize the following text in 3-5 sentences:"
                            }) {
                                Text("Summary Prompt")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                prompt = "Extract the key information from this document and format it as bullet points:"
                            }) {
                                Text("Key Points Extraction")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                prompt = "Translate the following text to Spanish:"
                            }) {
                                Text("Translation Prompt")
                                    .font(.caption)
                                    .padding(8)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // File Type Selection (for file batch)
                if selectedBatchType == .files {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("File Types")
                            .font(.headline)
                        
                        HStack {
                            ForEach(FileType.allCases, id: \.self) { fileType in
                                Toggle(fileType.rawValue.uppercased(), isOn: Binding(
                                    get: { selectedFileTypes.contains(fileType) },
                                    set: { newValue in
                                        if newValue {
                                            selectedFileTypes.append(fileType)
                                        } else {
                                            selectedFileTypes.removeAll { $0 == fileType }
                                        }
                                    }
                                ))
                                .toggleStyle(.button)
                                .controlSize(.small)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // File Selection
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(selectedBatchType == .files ? "Selected Files" : "Text Inputs")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            if selectedBatchType == .files {
                                showingFilePicker = true
                            } else {
                                // Add a new text input
                                let newTextInput = BatchFile(
                                    id: UUID().uuidString,
                                    url: nil,
                                    name: "Text Input \(selectedFiles.count + 1)",
                                    type: .txt,
                                    text: ""
                                )
                                selectedFiles.append(newTextInput)
                            }
                        }) {
                            Label(
                                selectedBatchType == .files ? "Add Files" : "Add Text Input",
                                systemImage: "plus"
                            )
                            .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    if selectedFiles.isEmpty {
                        Text("No \(selectedBatchType == .files ? "files" : "text inputs") selected")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    } else {
                        ForEach(selectedFiles, id: \.id) { file in
                            batchFileRow(file)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Output Format
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Output Format")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showingOutputOptions = true
                        }) {
                            Label("Options", systemImage: "gear")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    Picker("Output Format", selection: $outputFormat) {
                        Text("Text Files").tag(OutputFormat.text)
                        Text("Markdown").tag(OutputFormat.markdown)
                        Text("JSON").tag(OutputFormat.json)
                        Text("CSV").tag(OutputFormat.csv)
                        Text("In-App Results").tag(OutputFormat.inApp)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if outputFormat != .inApp {
                        HStack {
                            if let outputDirectory = outputDirectory {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Output Directory:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(outputDirectory.lastPathComponent)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    self.outputDirectory = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Button(action: {
                                    showingOutputPicker = true
                                }) {
                                    Label("Select Output Directory", systemImage: "folder.badge.plus")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Start Batch Button
                VStack {
                    Button(action: startBatchProcessing) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Start Batch Processing")
                                .fontWeight(.semibold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(canStartBatch ? Color.green : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(!canStartBatch || isProcessing)
                    .padding(.horizontal)
                    
                    if isProcessing {
                        VStack(spacing: 8) {
                            ProgressView(value: processingProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle())
                                .padding(.horizontal)
                            
                            Text(batchProgress)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                }
                
                // Results
                if !processingResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Processing Results")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(processingResults) { result in
                            resultRow(result)
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Batch Processor")
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker(
                contentTypes: fileContentTypes(),
                allowMultiple: true,
                onPick: { urls in
                    for url in urls {
                        let fileType = fileTypeFrom(url: url)
                        let newFile = BatchFile(
                            id: UUID().uuidString,
                            url: url,
                            name: url.lastPathComponent,
                            type: fileType,
                            text: nil
                        )
                        selectedFiles.append(newFile)
                    }
                }
            )
        }
    }
    
    // MARK: - View Components
    
    private func batchFileRow(_ file: BatchFile) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: iconForFileType(file.type))
                    .foregroundColor(colorForFileType(file.type))
                
                if selectedBatchType == .files {
                    Text(file.name)
                        .font(.subheadline)
                        .lineLimit(1)
                } else {
                    TextField("Text Input Name", text: Binding(
                        get: { file.name },
                        set: { newValue in
                            if let index = selectedFiles.firstIndex(where: { $0.id == file.id }) {
                                selectedFiles[index].name = newValue
                            }
                        }
                    ))
                    .font(.subheadline)
                }
                
                Spacer()
                
                Button(action: {
                    selectedFiles.removeAll { $0.id == file.id }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            
            if selectedBatchType == .textInputs {
                TextEditor(text: Binding(
                    get: { file.text ?? "" },
                    set: { newValue in
                        if let index = selectedFiles.firstIndex(where: { $0.id == file.id }) {
                            selectedFiles[index].text = newValue
                        }
                    }
                ))
                .font(.caption)
                .frame(height: 80)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func resultRow(_ result: BatchResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(result.success ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                
                Text(result.fileName)
                    .font(.headline)
                
                Spacer()
                
                if result.success {
                    Button(action: {
                        // Share or copy result
                        UIPasteboard.general.string = result.output
                    }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if result.success {
                Text(result.output)
                    .font(.caption)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)
            } else {
                Text(result.error ?? "Unknown error")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func startBatchProcessing() {
        guard canStartBatch else { return }
        
        isProcessing = true
        processingProgress = 0.0
        processingResults = []
        
        // Simulate batch processing
        let totalFiles = selectedFiles.count
        var completedFiles = 0
        
        for (index, file) in selectedFiles.enumerated() {
            // In a real implementation, this would process each file with the LLM
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                // Simulate processing result
                let success = Double.random() > 0.2 // 80% success rate for simulation
                
                let result = BatchResult(
                    id: UUID(),
                    fileName: file.name,
                    success: success,
                    output: success ? generateSampleOutput(for: file) : "",
                    error: success ? nil : "Failed to process file due to content extraction error"
                )
                
                processingResults.append(result)
                completedFiles += 1
                processingProgress = Double(completedFiles) / Double(totalFiles)
                
                // Check if all files are processed
                if completedFiles == totalFiles {
                    isProcessing = false
                }
            }
        }
    }
    
    private func generateSampleOutput(for file: BatchFile) -> String {
        // This is a placeholder that would be replaced with actual LLM output
        let summaryOptions = [
            "This document discusses the implementation of machine learning algorithms for natural language processing. It covers various techniques including tokenization, embedding generation, and fine-tuning of transformer models. The authors propose a novel approach to sentiment analysis that improves accuracy by 12% compared to previous methods.",
            
            "The text presents a comprehensive overview of sustainable urban planning principles. Key focuses include green infrastructure, renewable energy integration, and pedestrian-friendly design. Case studies from several European cities demonstrate successful implementation strategies and quantifiable improvements in quality of life metrics.",
            
            "This analysis examines market trends in the renewable energy sector from 2020-2025. Solar and wind power installations have exceeded growth projections by 23% and 17% respectively. The report highlights regulatory changes that have accelerated adoption and identifies emerging investment opportunities in grid storage technologies."
        ]
        
        return summaryOptions[Int.random(in: 0..<summaryOptions.count)]
    }
    
    private func fileContentTypes() -> [UTType] {
        var types: [UTType] = []
        
        for fileType in selectedFileTypes {
            switch fileType {
            case .pdf:
                types.append(.pdf)
            case .txt:
                types.append(.plainText)
            case .doc:
                types.append(.wordDoc)
            case .csv:
                types.append(UTType(filenameExtension: "csv") ?? .plainText)
            }
        }
        
        return types
    }
    
    private func fileTypeFrom(url: URL) -> FileType {
        let ext = url.pathExtension.lowercased()
        
        switch ext {
        case "pdf":
            return .pdf
        case "txt", "text":
            return .txt
        case "doc", "docx":
            return .doc
        case "csv":
            return .csv
        default:
            return .txt
        }
    }
    
    private func iconForFileType(_ type: FileType) -> String {
        switch type {
        case .pdf:
            return "doc.fill"
        case .txt:
            return "doc.text"
        case .doc:
            return "doc.richtext"
        case .csv:
            return "tablecells"
        }
    }
    
    private func colorForFileType(_ type: FileType) -> Color {
        switch type {
        case .pdf:
            return .red
        case .txt:
            return .blue
        case .doc:
            return .blue
        case .csv:
            return .purple
        }
    }
}

// MARK: - Supporting Types

/// Batch Type Enum
enum BatchType {
    case files
    case textInputs
}

/// File Type Enum
enum FileType: String, CaseIterable {
    case pdf
    case txt
    case doc
    case csv
}

/// Output Format Enum
enum OutputFormat {
    case text
    case markdown
    case json
    case csv
    case inApp
}

/// Batch File Structure
struct BatchFile {
    var id: String
    var url: URL?
    var name: String
    var type: FileType
    var text: String?
}

/// Batch Result Structure
struct BatchResult: Identifiable {
    var id: UUID
    var fileName: String
    var success: Bool
    var output: String
    var error: String?
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let allowMultiple: Bool
    let onPick: ([URL]) -> Void
    
    init(contentTypes: [UTType], allowMultiple: Bool = false, onPick: @escaping ([URL]) -> Void) {
        self.contentTypes = contentTypes
        self.allowMultiple = allowMultiple
        self.onPick = onPick
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.allowsMultipleSelection = allowMultiple
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

struct BatchProcessorView_Previews: PreviewProvider {
    static var previews: some View {
        BatchProcessorView()
            .environmentObject(AppState())
    }
}
