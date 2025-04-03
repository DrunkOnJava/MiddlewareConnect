/**
 * @fileoverview Tools View
 * @module ToolsView
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - SwiftUI
 * - PDF
 * 
 * Exports:
 * - ToolsView
 * 
 * Notes:
 * - Collection of utility tools for document and text processing
 * - Provides access to PDF manipulation, text processing, and other utilities
 */

import SwiftUI
import UniformTypeIdentifiers
import PDFKit

/// Tools view
struct ToolsView: View {
    // MARK: - Properties
    
    /// Tool categories
    private let toolCategories = [
        ToolCategory(
            name: "PDF Tools",
            systemImage: "doc.text",
            tools: [
                Tool(
                    name: "Combine PDFs",
                    description: "Merge multiple PDF files into one document",
                    systemImage: "doc.on.doc",
                    color: .blue,
                    destination: AnyView(PDFCombinerView())
                ),
                Tool(
                    name: "Split PDF",
                    description: "Divide a PDF into multiple documents",
                    systemImage: "doc.text.below.ecg",
                    color: .purple,
                    destination: AnyView(PDFSplitterView())
                ),
                Tool(
                    name: "Extract Text",
                    description: "Extract text content from PDF documents",
                    systemImage: "doc.text.magnifyingglass",
                    color: .green,
                    destination: AnyView(PDFTextExtractorView())
                ),
                Tool(
                    name: "Add Annotations",
                    description: "Add notes, highlights, and other annotations to PDFs",
                    systemImage: "pencil.and.outline",
                    color: .orange,
                    destination: AnyView(PDFAnnotationView())
                )
            ]
        ),
        ToolCategory(
            name: "Text Processing",
            systemImage: "text.alignleft",
            tools: [
                Tool(
                    name: "Text Summarizer",
                    description: "Generate concise summaries of long texts",
                    systemImage: "text.redaction",
                    color: .blue,
                    destination: AnyView(TextSummarizerView())
                ),
                Tool(
                    name: "Entity Extractor",
                    description: "Extract people, organizations, dates, and other entities",
                    systemImage: "person.text.rectangle",
                    color: .purple,
                    destination: AnyView(EntityExtractorView())
                ),
                Tool(
                    name: "Format Converter",
                    description: "Convert between text formats (Markdown, HTML, etc.)",
                    systemImage: "arrow.triangle.swap",
                    color: .green,
                    destination: AnyView(FormatConverterView())
                )
            ]
        ),
        ToolCategory(
            name: "Utilities",
            systemImage: "wrench.and.screwdriver",
            tools: [
                Tool(
                    name: "Document Comparison",
                    description: "Compare two documents to find similarities and differences",
                    systemImage: "doc.text.below.ecg",
                    color: .blue,
                    destination: AnyView(DocumentComparisonView())
                ),
                Tool(
                    name: "Token Counter",
                    description: "Count tokens in text for LLM context management",
                    systemImage: "number.circle",
                    color: .purple,
                    destination: AnyView(TokenCounterView())
                ),
                Tool(
                    name: "Prompt Library",
                    description: "Create, manage, and use prompt templates",
                    systemImage: "text.word.spacing",
                    color: .green,
                    destination: AnyView(PromptLibraryView())
                )
            ]
        )
    ]
    
    // MARK: - Body
    
    var body: some View {
        List {
            ForEach(toolCategories) { category in
                Section(header: categoryHeader(category)) {
                    ForEach(category.tools) { tool in
                        NavigationLink(destination: tool.destination) {
                            toolRow(tool)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Tools")
    }
    
    /// Category header
    private func categoryHeader(_ category: ToolCategory) -> some View {
        HStack {
            Image(systemName: category.systemImage)
                .foregroundColor(.blue)
            
            Text(category.name)
                .font(.headline)
        }
    }
    
    /// Tool row
    private func toolRow(_ tool: Tool) -> some View {
        HStack {
            Image(systemName: tool.systemImage)
                .font(.title2)
                .frame(width: 32, height: 32)
                .foregroundColor(.white)
                .background(tool.color)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tool.name)
                    .font(.headline)
                
                Text(tool.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Tool category model
struct ToolCategory: Identifiable {
    /// Identifier
    let id = UUID()
    
    /// Name
    let name: String
    
    /// System image name
    let systemImage: String
    
    /// Tools
    let tools: [Tool]
}

/// Tool model
struct Tool: Identifiable {
    /// Identifier
    let id = UUID()
    
    /// Name
    let name: String
    
    /// Description
    let description: String
    
    /// System image name
    let systemImage: String
    
    /// Color
    let color: Color
    
    /// Destination view
    let destination: AnyView
}

// MARK: - PDF Tool Views

/// PDF combiner view
struct PDFCombinerView: View {
    // MARK: - Properties
    
    /// Selected PDF URLs
    @State private var selectedURLs: [URL] = []
    
    /// Show file picker
    @State private var showingFilePicker = false
    
    /// Combined PDF URL
    @State private var combinedPDFURL: URL?
    
    /// Is processing
    @State private var isProcessing = false
    
    /// Progress
    @State private var progress: Double = 0
    
    /// PDF service
    private let pdfService = PDFService.shared
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            // Header
            headerView
            
            // Selected PDFs
            selectedPDFsView
            
            // Combine button
            combineButtonView
            
            // Result preview
            resultPreviewView
        }
        .padding()
        .navigationTitle("Combine PDFs")
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker(allowMultiple: true) { urls in
                selectedURLs.append(contentsOf: urls)
            }
        }
        .onAppear {
            // Subscribe to progress updates
            pdfService.progress
                .receive(on: DispatchQueue.main)
                .sink { [weak self] progressValue in
                    self?.progress = progressValue
                }
        }
    }
    
    /// Header view
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Combine multiple PDF files into one document")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom)
            
            Button(action: {
                showingFilePicker = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add PDFs")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    /// Selected PDFs view
    private var selectedPDFsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected PDFs (\(selectedURLs.count))")
                .font(.headline)
                .padding(.top)
            
            if selectedURLs.isEmpty {
                Text("No PDFs selected")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                List {
                    ForEach(selectedURLs, id: \.self) { url in
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            
                            Text(url.lastPathComponent)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button(action: {
                                selectedURLs.removeAll { $0 == url }
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        selectedURLs.remove(atOffsets: indexSet)
                    }
                }
                .frame(height: 200)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    /// Combine button view
    private var combineButtonView: some View {
        VStack {
            Button(action: combinePDFs) {
                HStack {
                    Image(systemName: "doc.on.doc.fill")
                    Text("Combine PDFs")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    selectedURLs.count >= 2 && !isProcessing ?
                        Color.green : Color.gray
                )
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(selectedURLs.count < 2 || isProcessing)
            
            if isProcessing {
                VStack {
                    ProgressView(value: progress, total: 1.0)
                        .padding(.top)
                    
                    Text("Processing...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical)
    }
    
    /// Result preview view
    private var resultPreviewView: some View {
        VStack {
            if let pdfURL = combinedPDFURL {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Combined PDF")
                        .font(.headline)
                    
                    PDFKitView(url: pdfURL)
                        .frame(height: 300)
                        .cornerRadius(8)
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            // Share PDF
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
    /// Combine PDFs
    private func combinePDFs() {
        guard selectedURLs.count >= 2 else { return }
        
        isProcessing = true
        
        // Use PDFService to combine PDFs
        do {
            let combinedURL = try pdfService.combinePDFs(urls: selectedURLs)
            
            DispatchQueue.main.async {
                self.combinedPDFURL = combinedURL
                self.isProcessing = false
            }
        } catch {
            print("Error combining PDFs: \(error.localizedDescription)")
            
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
    }
}

/// PDF splitter view
struct PDFSplitterView: View {
    var body: some View {
        Text("PDF Splitter")
            .navigationTitle("Split PDF")
    }
}

/// PDF text extractor view
struct PDFTextExtractorView: View {
    var body: some View {
        Text("PDF Text Extractor")
            .navigationTitle("Extract Text")
    }
}

/// PDF annotation view
struct PDFAnnotationView: View {
    var body: some View {
        Text("PDF Annotation")
            .navigationTitle("Add Annotations")
    }
}

// MARK: - Text Processing Tool Views

/// Text summarizer view
struct TextSummarizerView: View {
    var body: some View {
        Text("Text Summarizer")
            .navigationTitle("Text Summarizer")
    }
}

/// Entity extractor view
struct EntityExtractorView: View {
    var body: some View {
        Text("Entity Extractor")
            .navigationTitle("Entity Extractor")
    }
}

/// Format converter view
struct FormatConverterView: View {
    var body: some View {
        Text("Format Converter")
            .navigationTitle("Format Converter")
    }
}

// MARK: - Utility Tool Views

/// Document comparison view
struct DocumentComparisonView: View {
    var body: some View {
        Text("Document Comparison")
            .navigationTitle("Document Comparison")
    }
}

/// Token counter view
struct TokenCounterView: View {
    // MARK: - Properties
    
    /// Input text
    @State private var inputText = ""
    
    /// Token count
    @State private var tokenCount = 0
    
    /// Character count
    @State private var characterCount = 0
    
    /// Word count
    @State private var wordCount = 0
    
    /// Current model
    @State private var selectedModel = Claude3Model.sonnet
    
    /// Token counter
    private let tokenCounter = TokenCounter.shared
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            // Header
            Text("Count tokens, words, and characters in your text")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom)
            
            // Model selector
            Picker("Model", selection: $selectedModel) {
                ForEach(Claude3Model.allCases) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom)
            
            // Text editor
            ZStack(alignment: .topLeading) {
                TextEditor(text: $inputText)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: inputText) { _ in
                        countTokens()
                    }
                
                if inputText.isEmpty {
                    Text("Enter your text here...")
                        .foregroundColor(.gray)
                        .padding(8)
                        .allowsHitTesting(false)
                }
            }
            
            // Counts display
            VStack {
                HStack(spacing: 20) {
                    CounterView(
                        label: "Tokens",
                        count: tokenCount,
                        systemImage: "number.circle",
                        color: .blue
                    )
                    
                    CounterView(
                        label: "Words",
                        count: wordCount,
                        systemImage: "text.word.spacing",
                        color: .green
                    )
                    
                    CounterView(
                        label: "Characters",
                        count: characterCount,
                        systemImage: "character",
                        color: .purple
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Model context info
                let maxTokens = tokenCounter.getTokenLimit(forModel: selectedModel.rawValue)
                let remaining = maxTokens - tokenCount
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Model Context Information")
                        .font(.headline)
                        .padding(.top)
                    
                    HStack {
                        Text("Maximum Context Size:")
                        Spacer()
                        Text("\(maxTokens) tokens")
                            .bold()
                    }
                    
                    HStack {
                        Text("Remaining Context:")
                        Spacer()
                        Text("\(remaining) tokens")
                            .bold()
                            .foregroundColor(
                                remaining < 1000 ? .red :
                                    remaining < 5000 ? .orange : .green
                            )
                    }
                    
                    HStack {
                        Text("Approximate Cost:")
                        Spacer()
                        
                        let inputCost = Double(tokenCount) * selectedModel.costPerInputToken
                        let outputCostEstimate = Double(tokenCount / 2) * selectedModel.costPerOutputToken
                        let totalCost = inputCost + outputCostEstimate
                        
                        Text("$\(String(format: "%.5f", totalCost))")
                            .bold()
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            Spacer()
            
            // Action buttons
            HStack {
                Button(action: {
                    inputText = ""
                    countTokens()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    UIPasteboard.general.string = inputText
                }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .navigationTitle("Token Counter")
        .onAppear {
            countTokens()
        }
    }
    
    // MARK: - Methods
    
    /// Counts tokens, words, and characters
    private func countTokens() {
        tokenCount = tokenCounter.countTokens(inputText)
        wordCount = inputText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        characterCount = inputText.count
    }
}

/// Counter view
struct CounterView: View {
    let label: String
    let count: Int
    let systemImage: String
    let color: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: systemImage)
                    .foregroundColor(color)
                    .font(.system(size: 24))
            }
            
            Text("\(count)")
                .font(.title3)
                .bold()
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

/// Prompt library view
struct PromptLibraryView: View {
    var body: some View {
        Text("Prompt Library")
            .navigationTitle("Prompt Library")
    }
}

/// Document picker
struct DocumentPicker: UIViewControllerRepresentable {
    let allowMultiple: Bool
    let onPick: ([URL]) -> Void
    
    init(allowMultiple: Bool = false, onPick: @escaping ([URL]) -> Void) {
        self.allowMultiple = allowMultiple
        self.onPick = onPick
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = allowMultiple
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    }
    
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

/// Preview provider
struct ToolsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ToolsView()
        }
    }
}
