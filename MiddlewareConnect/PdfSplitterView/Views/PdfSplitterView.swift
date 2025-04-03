/**
 * @fileoverview PDF Splitter View for breaking PDFs into manageable chunks
 * @module PdfSplitterView
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - SwiftUI
 * - PDFKit
 * - Combine
 * 
 * Exports:
 * - PdfSplitterView
 * 
 * Notes:
 * - Main container orchestrating PDF splitting strategies
 * - Includes preview and output management
 */

import SwiftUI
import Combine
import PDFKit

/// Main view for PDF splitting and processing
public struct PdfSplitterView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: PdfSplitterViewModel
    @State private var isShowingFilePicker = false
    @State private var isShowingExportDialog = false
    @State private var selectedTabIndex = 0
    
    // MARK: - Initialization
    
    /// Initialize with a view model
    /// - Parameter viewModel: The view model for PDF splitting
    public init(viewModel: PdfSplitterViewModel = PdfSplitterViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selection
                Picker("View", selection: $selectedTabIndex) {
                    Text("Split").tag(0)
                    Text("Preview").tag(1)
                    Text("Export").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Tab content
                tabContent
                    .padding()
            }
            .navigationTitle("PDF Splitter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingFilePicker = true
                    }) {
                        Image(systemName: "doc.badge.plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.resetState()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.currentPdf == nil)
                }
            }
            .sheet(isPresented: $isShowingFilePicker) {
                DocumentPicker(
                    supportedTypes: ["com.adobe.pdf"],
                    onDocumentsPicked: { urls in
                        if let url = urls.first {
                            viewModel.loadPdf(from: url)
                        }
                    }
                )
            }
            .sheet(isPresented: $isShowingExportDialog) {
                ExportOptionsView(viewModel: viewModel)
            }
            .alert(item: alertBinding) { alertInfo in
                Alert(
                    title: Text(alertInfo.title),
                    message: Text(alertInfo.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onChange(of: viewModel.processingState) { state in
                // Auto-switch to preview tab when processing completes
                if case .processed = state {
                    withAnimation {
                        selectedTabIndex = 1
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Content for the selected tab
    private var tabContent: some View {
        ZStack {
            // Split tab
            if selectedTabIndex == 0 {
                splitTab
            }
            
            // Preview tab
            if selectedTabIndex == 1 {
                previewTab
            }
            
            // Export tab
            if selectedTabIndex == 2 {
                exportTab
            }
        }
    }
    
    /// Split tab content
    private var splitTab: some View {
        VStack(spacing: 16) {
            if viewModel.currentPdf == nil {
                noPdfView
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // PDF Info Section
                    pdfInfoSection
                    
                    Divider()
                    
                    // Split Strategy Section
                    splitStrategySection
                    
                    Spacer()
                    
                    // Process Button
                    Button(action: {
                        viewModel.processPdf()
                    }) {
                        if case .processing = viewModel.processingState {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Processing...")
                                    .padding(.leading, 8)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("Process PDF")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        viewModel.currentPdf == nil ||
                        viewModel.selectedStrategy == nil ||
                        viewModel.processingState == .processing
                    )
                }
            }
        }
    }
    
    /// Preview tab content
    private var previewTab: some View {
        VStack(spacing: 16) {
            if viewModel.splitResults.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No preview available")
                        .font(.title3)
                    
                    Text("Process a PDF to see the split results")
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        selectedTabIndex = 0
                    }) {
                        Text("Go to Split")
                            .frame(minWidth: 100)
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Split Results")
                        .font(.headline)
                    
                    Text("PDF Split into \(viewModel.splitResults.count) Chunks")
                        .foregroundColor(.secondary)
                    
                    // Stats Section
                    HStack(spacing: 20) {
                        VStack {
                            Text("\(viewModel.originalPageCount)")
                                .font(.title2)
                                .bold()
                            Text("Original Pages")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack {
                            Text("\(viewModel.splitResults.count)")
                                .font(.title2)
                                .bold()
                            Text("Output Files")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack {
                            Text(viewModel.averageChunkSize)
                                .font(.title2)
                                .bold()
                            Text("Avg. Size")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                    
                    // Results List
                    List {
                        ForEach(viewModel.splitResults) { result in
                            SplitResultRow(result: result) {
                                viewModel.previewSplitResult(result)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .frame(maxHeight: .infinity)
                    
                    // Navigation Buttons
                    HStack {
                        Button(action: {
                            selectedTabIndex = 0
                        }) {
                            Label("Modify Split", systemImage: "arrow.left")
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button(action: {
                            selectedTabIndex = 2
                        }) {
                            Label("Export Options", systemImage: "arrow.right")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
    
    /// Export tab content
    private var exportTab: some View {
        VStack(spacing: 16) {
            if viewModel.splitResults.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No content to export")
                        .font(.title3)
                    
                    Text("Process a PDF to generate export content")
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        selectedTabIndex = 0
                    }) {
                        Text("Go to Split")
                            .frame(minWidth: 100)
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Export Options")
                        .font(.headline)
                    
                    // Export Format Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Output Format")
                            .font(.subheadline)
                        
                        Picker("Format", selection: $viewModel.exportFormat) {
                            Text("PDF").tag(ExportFormat.pdf)
                            Text("Text").tag(ExportFormat.text)
                            Text("Markdown").tag(ExportFormat.markdown)
                            Text("JSON").tag(ExportFormat.json)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Naming Options
                    VStack(alignment: .leading, spacing: 8) {
                        Text("File Naming")
                            .font(.subheadline)
                        
                        Picker("Naming Pattern", selection: $viewModel.namingPattern) {
                            Text("Numeric").tag(NamingPattern.numeric)
                            Text("Page Numbers").tag(NamingPattern.pageNumbers)
                            Text("Content Based").tag(NamingPattern.contentBased)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        TextField("Base Filename", text: $viewModel.baseFilename)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Additional Options
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Options")
                            .font(.subheadline)
                        
                        Toggle("Include Table of Contents", isOn: $viewModel.includeTableOfContents)
                        Toggle("Add Page Numbers", isOn: $viewModel.addPageNumbers)
                        Toggle("Include Metadata", isOn: $viewModel.includeMetadata)
                    }
                    
                    // File Size Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Output Preview")
                            .font(.subheadline)
                        
                        HStack {
                            Text("Estimated Total Size:")
                            Spacer()
                            Text(viewModel.estimatedTotalSize)
                                .bold()
                        }
                        
                        HStack {
                            Text("Files to Generate:")
                            Spacer()
                            Text("\(viewModel.splitResults.count)")
                                .bold()
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // Export Button
                    Button(action: {
                        isShowingExportDialog = true
                    }) {
                        if case .exporting = viewModel.processingState {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Exporting...")
                                    .padding(.leading, 8)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            Label("Export Files", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.processingState == .exporting)
                }
            }
        }
    }
    
    /// View for when no PDF is loaded
    private var noPdfView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No PDF loaded")
                .font(.title3)
            
            Text("Upload a PDF file to get started")
                .foregroundColor(.secondary)
            
            Button(action: {
                isShowingFilePicker = true
            }) {
                Text("Select PDF")
                    .frame(minWidth: 100)
            }
            .buttonStyle(.bordered)
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// PDF Info Section
    private var pdfInfoSection: some View {
        Group {
            if let pdf = viewModel.currentPdf {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current PDF")
                        .font(.headline)
                    
                    HStack {
                        Text(pdf.documentURL?.lastPathComponent ?? "Document")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if let pageCount = pdf.pageCount, pageCount > 0 {
                            Text("\(pageCount) Pages")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    if let fileSize = viewModel.currentPdfSize {
                        Text("Size: \(fileSize)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    /// Split Strategy Section
    private var splitStrategySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Split Strategy")
                .font(.headline)
            
            // Strategy selector
            SplitStrategySelector(
                selectedStrategy: $viewModel.selectedStrategy,
                strategies: viewModel.availableStrategies
            )
            
            // Strategy options
            if let strategy = viewModel.selectedStrategy {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Strategy Options")
                        .font(.subheadline)
                    
                    switch strategy.type {
                    case .byPage:
                        HStack {
                            Text("Pages per chunk:")
                            Spacer()
                            Stepper(
                                value: $viewModel.pagesPerChunk,
                                in: 1...50
                            ) {
                                Text("\(viewModel.pagesPerChunk)")
                                    .frame(minWidth: 50, alignment: .trailing)
                            }
                        }
                        
                    case .byPageRange:
                        HStack(alignment: .top) {
                            Text("Page ranges:")
                            Spacer()
                            Text(viewModel.pageRanges.isEmpty ? "None" : viewModel.formattedPageRanges)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        PageRangeInputView(
                            pageRanges: $viewModel.pageRanges,
                            maxPage: viewModel.currentPdf?.pageCount ?? 1
                        )
                        
                    case .bySize:
                        HStack {
                            Text("Target size (KB):")
                            Spacer()
                            TextField("Size", value: $viewModel.targetSizeKB, formatter: NumberFormatter())
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 100)
                        }
                        
                    case .byBookmark:
                        if let bookmarks = viewModel.pdfBookmarks, !bookmarks.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Found \(bookmarks.count) bookmarks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Toggle("Split at every level", isOn: $viewModel.splitAtEveryLevel)
                                
                                if !viewModel.splitAtEveryLevel {
                                    HStack {
                                        Text("Maximum level:")
                                        Spacer()
                                        Stepper(
                                            value: $viewModel.maxBookmarkLevel,
                                            in: 1...5
                                        ) {
                                            Text("\(viewModel.maxBookmarkLevel)")
                                                .frame(minWidth: 50, alignment: .trailing)
                                        }
                                    }
                                }
                            }
                        } else {
                            Text("No bookmarks found in this PDF")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        
                    case .byHeading:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Detecting headings may take some time...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Toggle("Process all pages", isOn: $viewModel.processAllPages)
                            
                            if !viewModel.processAllPages {
                                HStack {
                                    Text("Sample pages:")
                                    Spacer()
                                    Stepper(
                                        value: $viewModel.samplePageCount,
                                        in: 1...10
                                    ) {
                                        Text("\(viewModel.samplePageCount)")
                                            .frame(minWidth: 50, alignment: .trailing)
                                    }
                                }
                            }
                            
                            Button("Detect Headings") {
                                viewModel.detectHeadings()
                            }
                            .buttonStyle(.bordered)
                            
                            if case .processing = viewModel.processingState {
                                ProgressView("Analyzing document...")
                                    .padding(.top, 8)
                            }
                        }
                        
                    case .byToken:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("For large language model processing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("Tokens per chunk:")
                                Spacer()
                                Stepper(
                                    value: $viewModel.tokensPerChunk,
                                    in: 100...4000,
                                    step: 100
                                ) {
                                    Text("\(viewModel.tokensPerChunk)")
                                        .frame(minWidth: 50, alignment: .trailing)
                                }
                            }
                            
                            HStack {
                                Text("Overlap tokens:")
                                Spacer()
                                Stepper(
                                    value: $viewModel.overlapTokens,
                                    in: 0...500,
                                    step: 50
                                ) {
                                    Text("\(viewModel.overlapTokens)")
                                        .frame(minWidth: 50, alignment: .trailing)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Alert Handling
    
    /// Structure for alert information
    private struct AlertInfo: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    
    /// Binding for alert presentation
    private var alertBinding: Binding<AlertInfo?> {
        Binding<AlertInfo?>(
            get: {
                if let errorMessage = viewModel.errorMessage {
                    return AlertInfo(
                        title: "Error",
                        message: errorMessage
                    )
                }
                return nil
            },
            set: { _ in
                viewModel.errorMessage = nil
            }
        )
    }
}

// MARK: - ViewModel

/// View model for PDF splitting orchestration
public class PdfSplitterViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current PDF document
    @Published public var currentPdf: PDFDocument?
    
    /// Size of the current PDF
    @Published public var currentPdfSize: String?
    
    /// Available splitting strategies
    @Published public var availableStrategies: [SplitStrategy] = []
    
    /// Selected splitting strategy
    @Published public var selectedStrategy: SplitStrategy?
    
    /// Pages per chunk for page-based splitting
    @Published public var pagesPerChunk: Int = 5
    
    /// Page ranges for range-based splitting
    @Published public var pageRanges: [PageRange] = []
    
    /// Target size in KB for size-based splitting
    @Published public var targetSizeKB: Int = 1000
    
    /// Whether to split at every bookmark level
    @Published public var splitAtEveryLevel: Bool = true
    
    /// Maximum bookmark level to split at
    @Published public var maxBookmarkLevel: Int = 1
    
    /// Whether to process all pages for heading detection
    @Published public var processAllPages: Bool = false
    
    /// Number of sample pages for heading detection
    @Published public var samplePageCount: Int = 3
    
    /// Tokens per chunk for token-based splitting
    @Published public var tokensPerChunk: Int = 1000
    
    /// Overlap tokens for token-based splitting
    @Published public var overlapTokens: Int = 100
    
    /// Current processing state
    @Published public var processingState: ProcessingState = .idle
    
    /// Results of splitting
    @Published public var splitResults: [SplitResult] = []
    
    /// PDF bookmarks if available
    @Published public var pdfBookmarks: [PDFBookmark]?
    
    /// Export format
    @Published public var exportFormat: ExportFormat = .pdf
    
    /// Naming pattern for exports
    @Published public var namingPattern: NamingPattern = .numeric
    
    /// Base filename for exports
    @Published public var baseFilename: String = "Split_PDF"
    
    /// Whether to include a table of contents
    @Published public var includeTableOfContents: Bool = true
    
    /// Whether to add page numbers
    @Published public var addPageNumbers: Bool = true
    
    /// Whether to include metadata
    @Published public var includeMetadata: Bool = true
    
    /// Error message if any
    @Published public var errorMessage: String?
    
    // MARK: - Computed Properties
    
    /// Original page count
    public var originalPageCount: Int {
        return currentPdf?.pageCount ?? 0
    }
    
    /// Average chunk size
    public var averageChunkSize: String {
        guard !splitResults.isEmpty else { return "0 KB" }
        
        let totalSize = splitResults.reduce(0) { $0 + ($1.sizeKB ?? 0) }
        let average = Double(totalSize) / Double(splitResults.count)
        
        return formatFileSize(sizeKB: Int(average))
    }
    
    /// Estimated total size
    public var estimatedTotalSize: String {
        let totalSize = splitResults.reduce(0) { $0 + ($1.sizeKB ?? 0) }
        return formatFileSize(sizeKB: totalSize)
    }
    
    /// Formatted page ranges
    public var formattedPageRanges: String {
        return pageRanges.map { "\($0.start)-\($0.end)" }.joined(separator: ", ")
    }
    
    // MARK: - Private Properties
    
    /// Service for PDF operations
    private let pdfService = PdfService()
    
    // MARK: - Initialization
    
    /// Initialize the view model
    public init() {
        loadAvailableStrategies()
    }
    
    // MARK: - Public Methods
    
    /// Loads available splitting strategies
    public func loadAvailableStrategies() {
        availableStrategies = [
            SplitStrategy(
                type: .byPage,
                name: "By Page Count",
                description: "Split PDF into chunks with a specific number of pages",
                iconName: "doc.on.doc"
            ),
            SplitStrategy(
                type: .byPageRange,
                name: "By Page Ranges",
                description: "Split PDF using custom page ranges",
                iconName: "text.insert"
            ),
            SplitStrategy(
                type: .bySize,
                name: "By File Size",
                description: "Split PDF into chunks with approximately equal file sizes",
                iconName: "arrow.up.arrow.down"
            ),
            SplitStrategy(
                type: .byBookmark,
                name: "By Bookmarks",
                description: "Split PDF at bookmark/outline entries",
                iconName: "bookmark"
            ),
            SplitStrategy(
                type: .byHeading,
                name: "By Headings",
                description: "Split PDF at detected headings in the content",
                iconName: "text.redaction"
            ),
            SplitStrategy(
                type: .byToken,
                name: "By Token Count",
                description: "Split PDF for LLM processing with controlled token counts",
                iconName: "character.textbox"
            )
        ]
        
        // Default to the first strategy
        selectedStrategy = availableStrategies.first
    }
    
    /// Loads a PDF from a URL
    /// - Parameter url: URL of the PDF file
    public func loadPdf(from url: URL) {
        guard let pdf = PDFDocument(url: url) else {
            errorMessage = "Failed to load PDF. The file may be corrupted or password-protected."
            return
        }
        
        currentPdf = pdf
        processingState = .loaded
        splitResults = []
        
        // Get file size
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int {
                currentPdfSize = formatFileSize(sizeKB: size / 1024)
            }
        } catch {
            currentPdfSize = "Unknown size"
        }
        
        // Load bookmarks if available
        loadPdfBookmarks()
        
        // Reset options based on PDF properties
        resetOptionsForNewPdf()
    }
    
    /// Processes the PDF using the selected strategy
    public func processPdf() {
        guard let pdf = currentPdf, let strategy = selectedStrategy else {
            errorMessage = "No PDF or strategy selected."
            return
        }
        
        processingState = .processing
        splitResults = []
        
        // Process based on strategy
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let results: [SplitResult]
            
            switch strategy.type {
            case .byPage:
                results = self.pdfService.splitByPage(pdf, pagesPerChunk: self.pagesPerChunk)
                
            case .byPageRange:
                if self.pageRanges.isEmpty {
                    DispatchQueue.main.async {
                        self.errorMessage = "No page ranges specified."
                        self.processingState = .idle
                    }
                    return
                }
                results = self.pdfService.splitByPageRanges(pdf, ranges: self.pageRanges)
                
            case .bySize:
                results = self.pdfService.splitBySize(pdf, targetSizeKB: self.targetSizeKB)
                
            case .byBookmark:
                if let bookmarks = self.pdfBookmarks, !bookmarks.isEmpty {
                    results = self.pdfService.splitByBookmarks(
                        pdf,
                        bookmarks: bookmarks,
                        splitAtEveryLevel: self.splitAtEveryLevel,
                        maxLevel: self.splitAtEveryLevel ? nil : self.maxBookmarkLevel
                    )
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "No bookmarks found in this PDF."
                        self.processingState = .idle
                    }
                    return
                }
                
            case .byHeading:
                results = self.pdfService.splitByHeadings(
                    pdf,
                    processAllPages: self.processAllPages,
                    samplePageCount: self.processAllPages ? nil : self.samplePageCount
                )
                
            case .byToken:
                results = self.pdfService.splitByTokenCount(
                    pdf,
                    tokensPerChunk: self.tokensPerChunk,
                    overlapTokens: self.overlapTokens
                )
            }
            
            DispatchQueue.main.async {
                self.splitResults = results
                self.processingState = .processed
            }
        }
    }
    
    /// Resets the view model state
    public func resetState() {
        currentPdf = nil
        currentPdfSize = nil
        processingState = .idle
        splitResults = []
        pdfBookmarks = nil
        resetOptions()
    }
    
    /// Previews a split result
    /// - Parameter result: The result to preview
    public func previewSplitResult(_ result: SplitResult) {
        // In a real app, this would show a preview of the split result
    }
    
    /// Detects headings in the PDF
    public func detectHeadings() {
        guard let pdf = currentPdf else { return }
        
        processingState = .processing
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // In a real app, this would detect headings
            // For this example, we'll simulate heading detection
            
            // Simulate processing time
            Thread.sleep(forTimeInterval: 2.0)
            
            DispatchQueue.main.async {
                self.processingState = .loaded
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads bookmarks from the current PDF
    private func loadPdfBookmarks() {
        guard let pdf = currentPdf, let outline = pdf.outlineRoot else {
            pdfBookmarks = nil
            return
        }
        
        // In a real app, this would extract bookmarks from the PDF outline
        // For this example, we'll simulate bookmarks
        
        let simulatedBookmarks = [
            PDFBookmark(title: "Chapter 1", pageIndex: 0, level: 1),
            PDFBookmark(title: "Section 1.1", pageIndex: 2, level: 2),
            PDFBookmark(title: "Section 1.2", pageIndex: 5, level: 2),
            PDFBookmark(title: "Chapter 2", pageIndex: 8, level: 1),
            PDFBookmark(title: "Section 2.1", pageIndex: 10, level: 2),
            PDFBookmark(title: "Appendix A", pageIndex: 15, level: 1)
        ]
        
        pdfBookmarks = simulatedBookmarks
    }
    
    /// Resets options for a new PDF
    private func resetOptionsForNewPdf() {
        pageRanges = []
        
        // Set sensible defaults based on PDF properties
        if let pageCount = currentPdf?.pageCount {
            pagesPerChunk = min(5, pageCount)
            
            if pageCount > 10 {
                pageRanges = [
                    PageRange(start: 1, end: pageCount / 3),
                    PageRange(start: pageCount / 3 + 1, end: 2 * pageCount / 3),
                    PageRange(start: 2 * pageCount / 3 + 1, end: pageCount)
                ]
            } else {
                pageRanges = [PageRange(start: 1, end: pageCount)]
            }
        }
        
        // If the PDF has bookmarks, select that strategy
        if let bookmarks = pdfBookmarks, !bookmarks.isEmpty {
            selectedStrategy = availableStrategies.first { $0.type == .byBookmark }
        }
    }
    
    /// Resets all options to defaults
    private func resetOptions() {
        pagesPerChunk = 5
        pageRanges = []
        targetSizeKB = 1000
        splitAtEveryLevel = true
        maxBookmarkLevel = 1
        processAllPages = false
        samplePageCount = 3
        tokensPerChunk = 1000
        overlapTokens = 100
        selectedStrategy = availableStrategies.first
    }
    
    /// Formats a file size in KB
    /// - Parameter sizeKB: Size in kilobytes
    /// - Returns: Formatted size string
    private func formatFileSize(sizeKB: Int) -> String {
        if sizeKB < 1024 {
            return "\(sizeKB) KB"
        } else {
            let sizeMB = Double(sizeKB) / 1024.0
            return String(format: "%.2f MB", sizeMB)
        }
    }
    
    // MARK: - PDF Service
    
    /// Service for PDF operations
    private class PdfService {
        /// Splits a PDF by page count
        /// - Parameters:
        ///   - pdf: PDF document to split
        ///   - pagesPerChunk: Pages per chunk
        /// - Returns: Array of split results
        func splitByPage(_ pdf: PDFDocument, pagesPerChunk: Int) -> [SplitResult] {
            // In a real app, this would actually split the PDF
            // For this example, we'll simulate splitting
            
            guard let pageCount = pdf.pageCount, pageCount > 0 else { return [] }
            
            var results: [SplitResult] = []
            var currentPage = 0
            
            while currentPage < pageCount {
                let endPage = min(currentPage + pagesPerChunk - 1, pageCount - 1)
                let pageRange = "\(currentPage + 1)-\(endPage + 1)"
                
                let result = SplitResult(
                    id: UUID(),
                    title: "Pages \(pageRange)",
                    pageRange: pageRange,
                    pageCount: endPage - currentPage + 1,
                    sizeKB: Int.random(in: 100...500),
                    preview: nil
                )
                
                results.append(result)
                currentPage = endPage + 1
            }
            
            return results
        }
        
        /// Splits a PDF by page ranges
        /// - Parameters:
        ///   - pdf: PDF document to split
        ///   - ranges: Page ranges to split at
        /// - Returns: Array of split results
        func splitByPageRanges(_ pdf: PDFDocument, ranges: [PageRange]) -> [SplitResult] {
            // In a real app, this would actually split the PDF
            // For this example, we'll simulate splitting
            
            return ranges.map { range in
                let pageRange = "\(range.start)-\(range.end)"
                let pageCount = range.end - range.start + 1
                
                return SplitResult(
                    id: UUID(),
                    title: "Range \(pageRange)",
                    pageRange: pageRange,
                    pageCount: pageCount,
                    sizeKB: pageCount * Int.random(in: 50...150),
                    preview: nil
                )
            }
        }
        
        /// Splits a PDF by file size
        /// - Parameters:
        ///   - pdf: PDF document to split
        ///   - targetSizeKB: Target size in kilobytes
        /// - Returns: Array of split results
        func splitBySize(_ pdf: PDFDocument, targetSizeKB: Int) -> [SplitResult] {
            // In a real app, this would actually split the PDF
            // For this example, we'll simulate splitting
            
            guard let pageCount = pdf.pageCount, pageCount > 0 else { return [] }
            
            // Estimate total size
            let estimatedTotalSizeKB = pageCount * Int.random(in: 100...200)
            
            // Calculate chunks
            let chunkCount = max(1, estimatedTotalSizeKB / targetSizeKB)
            let pagesPerChunk = max(1, pageCount / chunkCount)
            
            var results: [SplitResult] = []
            var currentPage = 0
            
            while currentPage < pageCount {
                let endPage = min(currentPage + pagesPerChunk - 1, pageCount - 1)
                let pageRange = "\(currentPage + 1)-\(endPage + 1)"
                let pageCount = endPage - currentPage + 1
                
                let result = SplitResult(
                    id: UUID(),
                    title: "Chunk \(results.count + 1)",
                    pageRange: pageRange,
                    pageCount: pageCount,
                    sizeKB: Int(Double(targetSizeKB) * 0.9 + Double.random(in: 0...0.2 * Double(targetSizeKB))),
                    preview: nil
                )
                
                results.append(result)
                currentPage = endPage + 1
            }
            
            return results
        }
        
        /// Splits a PDF by bookmarks
        /// - Parameters:
        ///   - pdf: PDF document to split
        ///   - bookmarks: Bookmarks to split at
        ///   - splitAtEveryLevel: Whether to split at every level
        ///   - maxLevel: Maximum level to split at
        /// - Returns: Array of split results
        func splitByBookmarks(
            _ pdf: PDFDocument,
            bookmarks: [PDFBookmark],
            splitAtEveryLevel: Bool,
            maxLevel: Int?
        ) -> [SplitResult] {
            // In a real app, this would actually split the PDF
            // For this example, we'll simulate splitting
            
            guard let pageCount = pdf.pageCount, pageCount > 0 else { return [] }
            
            // Filter bookmarks by level if needed
            let filteredBookmarks = splitAtEveryLevel
                ? bookmarks
                : bookmarks.filter { bookmark in
                    bookmark.level <= (maxLevel ?? 1)
                }
            
            // Sort bookmarks by page index
            let sortedBookmarks = filteredBookmarks.sorted { $0.pageIndex < $1.pageIndex }
            
            var results: [SplitResult] = []
            
            for i in 0..<sortedBookmarks.count {
                let bookmark = sortedBookmarks[i]
                let startPage = bookmark.pageIndex
                
                // Determine end page (next bookmark or end of document)
                let endPage = i < sortedBookmarks.count - 1
                    ? sortedBookmarks[i + 1].pageIndex - 1
                    : pageCount - 1
                
                let pageRange = "\(startPage + 1)-\(endPage + 1)"
                let pageCount = endPage - startPage + 1
                
                let result = SplitResult(
                    id: UUID(),
                    title: bookmark.title,
                    pageRange: pageRange,
                    pageCount: pageCount,
                    sizeKB: pageCount * Int.random(in: 50...150),
                    preview: nil
                )
                
                results.append(result)
            }
            
            return results
        }
        
        /// Splits a PDF by headings
        /// - Parameters:
        ///   - pdf: PDF document to split
        ///   - processAllPages: Whether to process all pages
        ///   - samplePageCount: Number of sample pages to process
        /// - Returns: Array of split results
        func splitByHeadings(
            _ pdf: PDFDocument,
            processAllPages: Bool,
            samplePageCount: Int?
        ) -> [SplitResult] {
            // In a real app, this would actually detect headings and split the PDF
            // For this example, we'll simulate splitting
            
            guard let pageCount = pdf.pageCount, pageCount > 0 else { return [] }
            
            // Simulate heading locations (page indices)
            let headingLocations = processAllPages
                ? stride(from: 0, to: pageCount, by: Int.random(in: 2...4)).map { $0 }
                : (0..<min(samplePageCount ?? 3, pageCount)).map { $0 * pageCount / (samplePageCount ?? 3) }
            
            var results: [SplitResult] = []
            
            for i in 0..<headingLocations.count {
                let startPage = headingLocations[i]
                
                // Determine end page (next heading or end of document)
                let endPage = i < headingLocations.count - 1
                    ? headingLocations[i + 1] - 1
                    : pageCount - 1
                
                let pageRange = "\(startPage + 1)-\(endPage + 1)"
                let pageCount = endPage - startPage + 1
                
                let result = SplitResult(
                    id: UUID(),
                    title: "Heading \(i + 1)",
                    pageRange: pageRange,
                    pageCount: pageCount,
                    sizeKB: pageCount * Int.random(in: 50...150),
                    preview: nil
                )
                
                results.append(result)
            }
            
            return results
        }
        
        /// Splits a PDF by token count
        /// - Parameters:
        ///   - pdf: PDF document to split
        ///   - tokensPerChunk: Tokens per chunk
        ///   - overlapTokens: Overlap tokens
        /// - Returns: Array of split results
        func splitByTokenCount(
            _ pdf: PDFDocument,
            tokensPerChunk: Int,
            overlapTokens: Int
        ) -> [SplitResult] {
            // In a real app, this would extract text, count tokens, and split the PDF
            // For this example, we'll simulate splitting
            
            guard let pageCount = pdf.pageCount, pageCount > 0 else { return [] }
            
            // Assume average of 500 tokens per page
            let estimatedTotalTokens = pageCount * 500
            
            // Calculate number of chunks
            let effectiveTokensPerChunk = tokensPerChunk - overlapTokens
            let chunkCount = max(1, estimatedTotalTokens / effectiveTokensPerChunk)
            
            // Calculate pages per chunk
            let pagesPerChunk = max(1, pageCount / chunkCount)
            
            var results: [SplitResult] = []
            var currentPage = 0
            var chunkIndex = 1
            
            while currentPage < pageCount {
                let endPage = min(currentPage + pagesPerChunk - 1, pageCount - 1)
                let pageRange = "\(currentPage + 1)-\(endPage + 1)"
                let pageCount = endPage - currentPage + 1
                
                let estimatedTokens = pageCount * Int.random(in: 450...550)
                
                let result = SplitResult(
                    id: UUID(),
                    title: "Chunk \(chunkIndex) (\(estimatedTokens) tokens)",
                    pageRange: pageRange,
                    pageCount: pageCount,
                    sizeKB: pageCount * Int.random(in: 50...150),
                    preview: nil
                )
                
                results.append(result)
                currentPage = endPage + 1
                chunkIndex += 1
            }
            
            return results
        }
    }
}

// MARK: - Supporting Types

/// Processing state
public enum ProcessingState: Equatable {
    case idle
    case loaded
    case processing
    case processed
    case exporting
    case exported
}

/// Split strategy
public struct SplitStrategy: Identifiable {
    public let id = UUID()
    public let type: SplitStrategyType
    public let name: String
    public let description: String
    public let iconName: String
    
    public init(type: SplitStrategyType, name: String, description: String, iconName: String) {
        self.type = type
        self.name = name
        self.description = description
        self.iconName = iconName
    }
}

/// Split strategy type
public enum SplitStrategyType: String, CaseIterable {
    case byPage
    case byPageRange
    case bySize
    case byBookmark
    case byHeading
    case byToken
}

/// Page range
public struct PageRange: Identifiable {
    public let id = UUID()
    public var start: Int
    public var end: Int
    
    public init(start: Int, end: Int) {
        self.start = start
        self.end = end
    }
}

/// PDF bookmark
public struct PDFBookmark: Identifiable {
    public let id = UUID()
    public let title: String
    public let pageIndex: Int
    public let level: Int
    
    public init(title: String, pageIndex: Int, level: Int) {
        self.title = title
        self.pageIndex = pageIndex
        self.level = level
    }
}

/// Split result
public struct SplitResult: Identifiable {
    public let id: UUID
    public let title: String
    public let pageRange: String
    public let pageCount: Int
    public let sizeKB: Int?
    public let preview: PDFDocument?
    
    public init(id: UUID, title: String, pageRange: String, pageCount: Int, sizeKB: Int?, preview: PDFDocument?) {
        self.id = id
        self.title = title
        self.pageRange = pageRange
        self.pageCount = pageCount
        self.sizeKB = sizeKB
        self.preview = preview
    }
}

/// Export format
public enum ExportFormat: String, CaseIterable {
    case pdf
    case text
    case markdown
    case json
}

/// Naming pattern
public enum NamingPattern: String, CaseIterable {
    case numeric
    case pageNumbers
    case contentBased
}

// MARK: - Supporting Views

/// Document picker for selecting files
struct DocumentPicker: UIViewControllerRepresentable {
    let supportedTypes: [String]
    let onDocumentsPicked: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes.map { UTType(filenameExtension: $0)! })
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
            parent.onDocumentsPicked(urls)
        }
    }
}

/// View for result row
struct SplitResultRow: View {
    let result: SplitResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.title)
                        .font(.headline)
                    
                    Text("Pages: \(result.pageRange) (\(result.pageCount) pages)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let sizeKB = result.sizeKB {
                    Text(sizeKB < 1024 ? "\(sizeKB) KB" : String(format: "%.2f MB", Double(sizeKB) / 1024.0))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// View for page range input
struct PageRangeInputView: View {
    @Binding var pageRanges: [PageRange]
    let maxPage: Int
    @State private var startPage = 1
    @State private var endPage = 1
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Start Page:")
                Spacer()
                Stepper(value: $startPage, in: 1...maxPage) {
                    Text("\(startPage)")
                        .frame(minWidth: 50, alignment: .trailing)
                }
            }
            
            HStack {
                Text("End Page:")
                Spacer()
                Stepper(value: $endPage, in: startPage...maxPage) {
                    Text("\(endPage)")
                        .frame(minWidth: 50, alignment: .trailing)
                }
            }
            .onChange(of: startPage) { _ in
                if endPage < startPage {
                    endPage = startPage
                }
            }
            
            Button(action: addPageRange) {
                Label("Add Range", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            
            if !pageRanges.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Defined Ranges:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(pageRanges) { range in
                        HStack {
                            Text("\(range.start)-\(range.end)")
                            
                            Spacer()
                            
                            Button(action: {
                                removePageRange(id: range.id)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func addPageRange() {
        pageRanges.append(PageRange(start: startPage, end: endPage))
        
        // Sort ranges
        pageRanges.sort { $0.start < $1.start }
        
        // Reset for next input
        startPage = min(endPage + 1, maxPage)
        endPage = min(startPage + 5, maxPage)
    }
    
    private func removePageRange(id: UUID) {
        pageRanges.removeAll { $0.id == id }
    }
}

/// View for export options
struct ExportOptionsView: View {
    @ObservedObject var viewModel: PdfSplitterViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Location")) {
                    Text("Files will be saved to Documents folder")
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        exportFiles()
                    }) {
                        Label("Export \(viewModel.splitResults.count) Files", systemImage: "square.and.arrow.up")
                    }
                    .disabled(viewModel.processingState == .exporting)
                }
                
                Section(header: Text("Export Settings")) {
                    Picker("Format", selection: $viewModel.exportFormat) {
                        Text("PDF").tag(ExportFormat.pdf)
                        Text("Text").tag(ExportFormat.text)
                        Text("Markdown").tag(ExportFormat.markdown)
                        Text("JSON").tag(ExportFormat.json)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    TextField("Base Filename", text: $viewModel.baseFilename)
                }
                
                Section(header: Text("File Options")) {
                    Toggle("Include Table of Contents", isOn: $viewModel.includeTableOfContents)
                    Toggle("Add Page Numbers", isOn: $viewModel.addPageNumbers)
                    Toggle("Include Metadata", isOn: $viewModel.includeMetadata)
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func exportFiles() {
        viewModel.processingState = .exporting
        
        // Simulate export process
        DispatchQueue.global(qos: .userInitiated).async {
            // Simulate processing time
            Thread.sleep(forTimeInterval: 2.0)
            
            DispatchQueue.main.async {
                viewModel.processingState = .exported
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Preview

struct PdfSplitterView_Previews: PreviewProvider {
    static var previews: some View {
        PdfSplitterView()
    }
}
