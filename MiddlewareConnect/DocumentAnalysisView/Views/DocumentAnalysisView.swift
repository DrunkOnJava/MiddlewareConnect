import SwiftUI
import Combine
import LLMServiceProvider

/// The primary container view for document analysis functionality
///
/// Serves as the integration point for document selection, preview, analysis configuration,
/// and results visualization, with comprehensive state management.
public struct DocumentAnalysisView: View {
    /// ViewModel managing state and business logic for document analysis
    @StateObject private var viewModel: ViewModel
    
    /// Core view model for the document analysis view
    public class ViewModel: ObservableObject {
        /// The currently selected document(s) for analysis
        @Published public var selectedDocuments: [DocumentFile] = []
        
        /// Current analysis configuration settings
        @Published public var configuration: AnalysisConfiguration = .default
        
        /// Current state of the analysis process
        @Published public var analysisState: AnalysisState = .ready
        
        /// Analysis results data for all processed documents
        @Published public var analysisResults: AnalysisResults?
        
        /// Active page in the analysis view
        @Published public var activePage: Page = .documentSelection
        
        /// User error message if applicable
        @Published public var errorMessage: String?
        
        /// Analysis service for document processing
        private let documentAnalyzer: DocumentAnalyzer
        
        /// Cancellation tokens for in-progress operations
        private var cancellables = Set<AnyCancellable>()
        
        /// Initializes the view model with a document analyzer service
        /// - Parameter documentAnalyzer: Service for analyzing documents
        public init(documentAnalyzer: DocumentAnalyzer = DocumentAnalyzer()) {
            self.documentAnalyzer = documentAnalyzer
        }
        
        /// Attempts to load a document from a URL
        /// - Parameter url: URL of the document to load
        public func loadDocument(from url: URL) {
            do {
                let documentFile = try DocumentFile(url: url)
                selectedDocuments.append(documentFile)
                activePage = .documentPreview
            } catch {
                errorMessage = "Failed to load document: \(error.localizedDescription)"
            }
        }
        
        /// Starts the document analysis process
        public func startAnalysis() {
            guard !selectedDocuments.isEmpty else {
                errorMessage = "No document selected for analysis"
                return
            }
            
            analysisState = .processing(progress: 0.0)
            activePage = .analysisResults
            
            // Configure the analyzer with current settings
            let analyzerConfig = AnalyzerConfiguration(
                extractEntities: configuration.extractEntities,
                generateSummary: configuration.generateSummary,
                deepAnalysis: configuration.deepAnalysis,
                contextSize: configuration.contextSize,
                modelConfiguration: configuration.modelConfiguration
            )
            
            // Process documents
            documentAnalyzer.analyze(
                documents: selectedDocuments,
                configuration: analyzerConfig
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.analysisState = .completed
                    case .failure(let error):
                        self?.analysisState = .failed
                        self?.errorMessage = "Analysis failed: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] result in
                    if let progress = result.progress {
                        self?.analysisState = .processing(progress: progress)
                    }
                    
                    if let results = result.results {
                        self?.analysisResults = results
                    }
                }
            )
            .store(in: &cancellables)
        }
        
        /// Cancels any ongoing analysis process
        public func cancelAnalysis() {
            cancellables.forEach { $0.cancel() }
            analysisState = .ready
        }
        
        /// Clears the current results and returns to document selection
        public func reset() {
            selectedDocuments = []
            analysisResults = nil
            analysisState = .ready
            activePage = .documentSelection
            errorMessage = nil
        }
    }
    
    /// Represents a document file for analysis
    public struct DocumentFile: Identifiable {
        /// Unique identifier for the document
        public let id = UUID()
        
        /// File URL of the document
        public let url: URL
        
        /// Display name of the document
        public let filename: String
        
        /// MIME type of the document
        public let contentType: String
        
        /// File size in bytes
        public let fileSize: Int64
        
        /// Creates a document file from a URL
        /// - Parameter url: URL of the document
        /// - Throws: Error if file cannot be accessed
        public init(url: URL) throws {
            self.url = url
            
            let resourceValues = try url.resourceValues(forKeys: [
                .nameKey,
                .contentTypeKey,
                .fileSizeKey
            ])
            
            self.filename = resourceValues.name ?? url.lastPathComponent
            self.contentType = resourceValues.contentType?.description ?? "unknown"
            self.fileSize = resourceValues.fileSize ?? 0
        }
    }
    
    /// Configuration settings for document analysis
    public struct AnalysisConfiguration {
        /// Whether to extract named entities
        public var extractEntities: Bool
        
        /// Whether to generate document summaries
        public var generateSummary: Bool
        
        /// Whether to perform deeper contextual analysis
        public var deepAnalysis: Bool
        
        /// Maximum token context size for processing
        public var contextSize: Int
        
        /// Model configuration for LLM processing
        public var modelConfiguration: ModelConfiguration
        
        /// Default configuration settings
        public static let `default` = AnalysisConfiguration(
            extractEntities: true,
            generateSummary: true,
            deepAnalysis: false,
            contextSize: 8192,
            modelConfiguration: .init(model: .claude3Sonnet)
        )
    }
    
    /// Model configuration for analysis
    public struct ModelConfiguration {
        /// LLM model to use
        public var model: Claude3Model.ModelType
        
        /// Temperature setting for generation
        public var temperature: Double
        
        /// Top-p sampling parameter
        public var topP: Double
        
        /// Default model configuration
        public static let `default` = ModelConfiguration(
            model: .claude3Sonnet,
            temperature: 0.7,
            topP: 0.9
        )
        
        /// Initializes model configuration
        /// - Parameters:
        ///   - model: LLM model type
        ///   - temperature: Temperature setting (0.0-1.0)
        ///   - topP: Top-p setting (0.0-1.0)
        public init(
            model: Claude3Model.ModelType,
            temperature: Double = 0.7,
            topP: Double = 0.9
        ) {
            self.model = model
            self.temperature = temperature
            self.topP = topP
        }
    }
    
    /// Represents analysis results for documents
    public struct AnalysisResults {
        /// Document summaries if generated
        public let summaries: [DocumentSummary]?
        
        /// Extracted entities if requested
        public let entities: [Entity]?
        
        /// Key insights extracted from analysis
        public let insights: [String]
        
        /// Source documents that were analyzed
        public let documents: [DocumentFile]
        
        /// Processing statistics
        public let stats: ProcessingStats
        
        /// Initializes analysis results
        /// - Parameters:
        ///   - summaries: Generated document summaries
        ///   - entities: Extracted entities
        ///   - insights: Key insights from analysis
        ///   - documents: Source documents
        ///   - stats: Processing statistics
        public init(
            summaries: [DocumentSummary]? = nil,
            entities: [Entity]? = nil,
            insights: [String] = [],
            documents: [DocumentFile],
            stats: ProcessingStats
        ) {
            self.summaries = summaries
            self.entities = entities
            self.insights = insights
            self.documents = documents
            self.stats = stats
        }
    }
    
    /// Processing statistics for analysis
    public struct ProcessingStats {
        /// Total tokens processed
        public let totalTokens: Int
        
        /// Processing time in seconds
        public let processingTime: TimeInterval
        
        /// Model used for processing
        public let model: String
        
        /// Initializes processing statistics
        /// - Parameters:
        ///   - totalTokens: Total token count
        ///   - processingTime: Time in seconds
        ///   - model: Model identifier
        public init(
            totalTokens: Int,
            processingTime: TimeInterval,
            model: String
        ) {
            self.totalTokens = totalTokens
            self.processingTime = processingTime
            self.model = model
        }
    }
    
    /// Possible states of the analysis process
    public enum AnalysisState: Equatable {
        /// Ready to begin analysis
        case ready
        
        /// Analysis in progress with percentage
        case processing(progress: Double)
        
        /// Analysis completed successfully
        case completed
        
        /// Analysis failed with error
        case failed
    }
    
    /// Available pages in the analysis view
    public enum Page {
        /// Document selection and upload page
        case documentSelection
        
        /// Document preview and configuration page
        case documentPreview
        
        /// Analysis results visualization page
        case analysisResults
    }
    
    /// Initializes document analysis view
    /// - Parameter viewModel: ViewModel for state management
    public init(viewModel: ViewModel = ViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationView {
            VStack {
                // Top navigation bar
                navigationBar
                
                // Main content based on active page
                mainContent
                
                // Action buttons based on current state
                actionButtons
                
                // Error message display if present
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }
            }
            .padding()
            .navigationTitle("Document Analysis")
        }
    }
    
    /// Navigation controls for the view
    private var navigationBar: some View {
        HStack {
            Spacer()
            
            // Page selector
            Picker("Page", selection: $viewModel.activePage) {
                Text("Select Document").tag(Page.documentSelection)
                Text("Preview").tag(Page.documentPreview)
                    .disabled(viewModel.selectedDocuments.isEmpty)
                Text("Analysis Results").tag(Page.analysisResults)
                    .disabled(viewModel.analysisResults == nil)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 400)
            
            Spacer()
            
            // Reset button
            Button(action: viewModel.reset) {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
        }
        .padding(.bottom)
    }
    
    /// Main content area based on active page
    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.activePage {
        case .documentSelection:
            documentSelectionView
        case .documentPreview:
            documentPreviewView
        case .analysisResults:
            analysisResultsView
        }
    }
    
    /// Document selection view
    private var documentSelectionView: some View {
        VStack(spacing: 20) {
            Text("Select Documents for Analysis")
                .font(.title)
            
            // This is a placeholder for the DocumentPicker component
            // that will be implemented in Task 15
            Button("Select Document") {
                // Document selection will be handled by DocumentPicker
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            if !viewModel.selectedDocuments.isEmpty {
                documentList
            } else {
                Text("No documents selected")
                    .foregroundColor(.gray)
                    .padding(.top, 40)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Document preview view
    private var documentPreviewView: some View {
        VStack {
            if let document = viewModel.selectedDocuments.first {
                VStack(alignment: .leading, spacing: 20) {
                    // Document info header
                    HStack {
                        VStack(alignment: .leading) {
                            Text(document.filename)
                                .font(.headline)
                            
                            Text("\(document.contentType) • \(formattedFileSize(document.fileSize))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    
                    // This is a placeholder for the PDFPreviewView component
                    // that will be implemented in Task 12
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            Text("PDF Preview (Task 12)")
                                .foregroundColor(.gray)
                        )
                }
                .padding()
            } else {
                Text("No document selected")
                    .foregroundColor(.gray)
            }
            
            // Analysis configuration
            configurationPanel
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Analysis results view
    private var analysisResultsView: some View {
        VStack {
            if let results = viewModel.analysisResults {
                HStack(spacing: 0) {
                    // This is a placeholder for the SummaryView component
                    // that will be implemented in Task 13
                    VStack {
                        Text("Summary View (Task 13)")
                            .font(.headline)
                        
                        if let summaries = results.summaries {
                            Text("\(summaries.count) summaries generated")
                        } else {
                            Text("No summaries generated")
                        }
                    }
                    .frame(width: 300)
                    .frame(maxHeight: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    
                    // Main results area
                    VStack {
                        if results.entities != nil {
                            // This is a placeholder for the EntitiesView component
                            // that will be implemented in Task 14
                            Text("Entities View (Task 14)")
                                .font(.headline)
                        } else {
                            Text("No entities extracted")
                                .foregroundColor(.gray)
                        }
                        
                        // Insights section
                        VStack(alignment: .leading) {
                            Text("Key Insights")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            if results.insights.isEmpty {
                                Text("No insights extracted")
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(results.insights, id: \.self) { insight in
                                    HStack(alignment: .top) {
                                        Image(systemName: "lightbulb")
                                            .foregroundColor(.yellow)
                                        
                                        Text(insight)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                        
                        // Processing stats
                        HStack {
                            Label("Model: \(results.stats.model)", systemImage: "cpu")
                            Spacer()
                            Label("\(results.stats.totalTokens) tokens", systemImage: "text.word.spacing")
                            Spacer()
                            Label(String(format: "%.1f seconds", results.stats.processingTime), systemImage: "clock")
                        }
                        .font(.caption)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if case .processing(let progress) = viewModel.analysisState {
                VStack {
                    ProgressView(value: progress, total: 1.0) {
                        Text("Analyzing documents...")
                    }
                    
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.caption)
                        .padding(.top, 5)
                }
                .padding()
            } else {
                Text("No analysis results available")
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Document list display
    private var documentList: some View {
        List {
            ForEach(viewModel.selectedDocuments) { document in
                HStack {
                    Image(systemName: "doc.text")
                    
                    VStack(alignment: .leading) {
                        Text(document.filename)
                            .font(.headline)
                        
                        Text("\(document.contentType) • \(formattedFileSize(document.fileSize))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .onDelete { indices in
                viewModel.selectedDocuments.remove(atOffsets: indices)
            }
        }
        .frame(height: 200)
    }
    
    /// Configuration panel for analysis settings
    private var configurationPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analysis Configuration")
                .font(.headline)
            
            VStack(alignment: .leading) {
                Toggle("Generate Summary", isOn: $viewModel.configuration.generateSummary)
                Toggle("Extract Entities", isOn: $viewModel.configuration.extractEntities)
                Toggle("Deep Analysis", isOn: $viewModel.configuration.deepAnalysis)
            }
            
            Divider()
            
            // Model selection
            VStack(alignment: .leading) {
                Text("Model Configuration")
                    .font(.subheadline)
                
                Picker("Model", selection: $viewModel.configuration.modelConfiguration.model) {
                    Text("Claude 3 Haiku").tag(Claude3Model.ModelType.claude3Haiku)
                    Text("Claude 3 Sonnet").tag(Claude3Model.ModelType.claude3Sonnet)
                    Text("Claude 3 Opus").tag(Claude3Model.ModelType.claude3Opus)
                }
                
                // Temperature slider
                HStack {
                    Text("Temperature:")
                    Slider(
                        value: $viewModel.configuration.modelConfiguration.temperature,
                        in: 0.0...1.0,
                        step: 0.1
                    )
                    Text(String(format: "%.1f", viewModel.configuration.modelConfiguration.temperature))
                        .frame(width: 30)
                }
                
                // Context size picker
                Picker("Context Size", selection: $viewModel.configuration.contextSize) {
                    Text("8K tokens").tag(8192)
                    Text("16K tokens").tag(16384)
                    Text("32K tokens").tag(32768)
                    Text("100K tokens").tag(100000)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    /// Action buttons based on current state
    @ViewBuilder
    private var actionButtons: some View {
        HStack {
            Spacer()
            
            switch viewModel.activePage {
            case .documentSelection:
                // No action buttons on selection page
                EmptyView()
                
            case .documentPreview:
                // Analyze button
                Button("Start Analysis") {
                    viewModel.startAnalysis()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedDocuments.isEmpty)
                
            case .analysisResults:
                // Action buttons for results page
                if case .processing = viewModel.analysisState {
                    Button("Cancel") {
                        viewModel.cancelAnalysis()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("New Analysis") {
                        viewModel.reset()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    /// Error message banner
    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.white)
            
            Text(message)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                viewModel.errorMessage = nil
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.red)
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    /// Formats file size in human-readable form
    private func formattedFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - Preview Support
#if DEBUG
struct DocumentAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentAnalysisView(
            viewModel: DocumentAnalysisView.ViewModel().apply {
                // Mock data for preview
                $0.selectedDocuments = [
                    try! DocumentAnalysisView.DocumentFile(
                        url: URL(fileURLWithPath: "/path/to/document.pdf")
                    )
                ]
                
                $0.analysisResults = DocumentAnalysisView.AnalysisResults(
                    summaries: [
                        DocumentSummary(
                            id: UUID(),
                            document: "document.pdf",
                            summary: "This is a sample summary",
                            keyPoints: ["Point 1", "Point 2"],
                            length: .medium
                        )
                    ],
                    entities: [
                        Entity(
                            id: UUID(),
                            name: "Sample Entity",
                            type: .person,
                            confidence: 0.9,
                            references: [TextReference(text: "Sample text", location: "p.1")]
                        )
                    ],
                    insights: [
                        "The document discusses key innovations in AI technology",
                        "There appears to be significant overlap with previous research"
                    ],
                    documents: [],
                    stats: DocumentAnalysisView.ProcessingStats(
                        totalTokens: 15420,
                        processingTime: 3.5,
                        model: "claude-3-sonnet"
                    )
                )
            }
        )
    }
}

extension DocumentAnalysisView.ViewModel {
    /// Helper for configuring preview instances
    func apply(_ configure: (DocumentAnalysisView.ViewModel) -> Void) -> DocumentAnalysisView.ViewModel {
        configure(self)
        return self
    }
}
#endif

// MARK: - Placeholder Types
// These types would typically be imported from LLMServiceProvider but are defined
// here as placeholders to avoid dependency issues until those components are implemented

public struct DocumentSummary: Identifiable {
    public let id: UUID
    public let document: String
    public let summary: String
    public let keyPoints: [String]
    public let length: SummaryLength
    
    public enum SummaryLength {
        case brief, medium, comprehensive
    }
}

public struct Entity: Identifiable {
    public let id: UUID
    public let name: String
    public let type: EntityType
    public let confidence: Double
    public let references: [TextReference]
    
    public enum EntityType {
        case person, organization, location, date, concept, custom(String)
    }
}

public struct TextReference {
    public let text: String
    public let location: String
}

public struct AnalyzerConfiguration {
    public let extractEntities: Bool
    public let generateSummary: Bool
    public let deepAnalysis: Bool
    public let contextSize: Int
    public let modelConfiguration: DocumentAnalysisView.ModelConfiguration
}
