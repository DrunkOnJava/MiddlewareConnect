/**
 * @fileoverview Main export file for PdfSplitterView module
 * @module PdfSplitterView
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - SwiftUI
 * - PDFKit
 * 
 * Exports:
 * - Public interfaces for PdfSplitterView module
 * 
 * Notes:
 * - Re-exports public views and components
 * - Provides streamlined API for module consumers
 */

import SwiftUI
import PDFKit

// Re-export public components
public typealias SplitStrategy = PdfSplitterInternal.SplitStrategy
public typealias SplitStrategyType = PdfSplitterInternal.SplitStrategyType
public typealias PageRange = PdfSplitterInternal.PageRange
public typealias SplitResult = PdfSplitterInternal.SplitResult
public typealias ExportFormat = PdfSplitterInternal.ExportFormat
public typealias NamingPattern = PdfSplitterInternal.NamingPattern
public typealias ProcessingStatus = PdfSplitterInternal.ProcessingStatus

// Main entry point view
@available(iOS 14.0, macOS 11.0, *)
public struct PdfSplitterView: View {
    @StateObject private var viewModel: PdfSplitterViewModel
    
    public init(viewModel: PdfSplitterViewModel = PdfSplitterViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        PdfSplitterInternal.PdfSplitterView(viewModel: viewModel)
    }
}

// Component view
@available(iOS 14.0, macOS 11.0, *)
public struct SplitStrategySelector: View {
    @Binding var selectedStrategy: SplitStrategy?
    let strategies: [SplitStrategy]
    let displayMode: DisplayMode
    
    public init(
        selectedStrategy: Binding<SplitStrategy?>,
        strategies: [SplitStrategy],
        displayMode: DisplayMode = .card
    ) {
        self._selectedStrategy = selectedStrategy
        self.strategies = strategies
        self.displayMode = displayMode
    }
    
    public var body: some View {
        PdfSplitterInternal.SplitStrategySelector(
            selectedStrategy: $selectedStrategy,
            strategies: strategies,
            displayMode: PdfSplitterInternal.SplitStrategySelector.DisplayMode(rawValue: displayMode.rawValue) ?? .card
        )
    }
    
    public enum DisplayMode: Int {
        case card = 0
        case list = 1
        case compact = 2
    }
}

// Public view model
public class PdfSplitterViewModel: ObservableObject {
    private let internalViewModel: PdfSplitterInternal.PdfSplitterViewModel
    
    // MARK: - Published Properties
    
    /// Current PDF document
    @Published public var currentPdf: PDFDocument? {
        didSet {
            internalViewModel.currentPdf = currentPdf
        }
    }
    
    /// Size of the current PDF
    @Published public var currentPdfSize: String? {
        get { internalViewModel.currentPdfSize }
    }
    
    /// Available splitting strategies
    @Published public var availableStrategies: [SplitStrategy] {
        get { internalViewModel.availableStrategies }
    }
    
    /// Selected splitting strategy
    @Published public var selectedStrategy: SplitStrategy? {
        get { internalViewModel.selectedStrategy }
        set { internalViewModel.selectedStrategy = newValue }
    }
    
    /// Pages per chunk for page-based splitting
    @Published public var pagesPerChunk: Int {
        get { internalViewModel.pagesPerChunk }
        set { internalViewModel.pagesPerChunk = newValue }
    }
    
    /// Page ranges for range-based splitting
    @Published public var pageRanges: [PageRange] {
        get { internalViewModel.pageRanges }
        set { internalViewModel.pageRanges = newValue }
    }
    
    /// Current processing state
    @Published public var processingState: ProcessingStatus {
        get { internalViewModel.processingState }
    }
    
    /// Results of splitting
    @Published public var splitResults: [SplitResult] {
        get { internalViewModel.splitResults }
    }
    
    /// Export format
    @Published public var exportFormat: ExportFormat {
        get { internalViewModel.exportFormat }
        set { internalViewModel.exportFormat = newValue }
    }
    
    // MARK: - Initialization
    
    public init() {
        internalViewModel = PdfSplitterInternal.PdfSplitterViewModel()
    }
    
    // MARK: - Public Methods
    
    /// Loads a PDF from a URL
    /// - Parameter url: URL of the PDF file
    public func loadPdf(from url: URL) {
        internalViewModel.loadPdf(from: url)
    }
    
    /// Processes the PDF using the selected strategy
    public func processPdf() {
        internalViewModel.processPdf()
    }
    
    /// Resets the view model state
    public func resetState() {
        internalViewModel.resetState()
    }
}

// Factory methods for creating split strategies
public extension SplitStrategy {
    /// Create a page-based split strategy
    static func byPage(name: String = "By Page Count", description: String = "Split PDF into chunks with a specific number of pages") -> SplitStrategy {
        SplitStrategy(
            type: .byPage,
            name: name,
            description: description,
            iconName: "doc.on.doc"
        )
    }
    
    /// Create a page range-based split strategy
    static func byPageRange(name: String = "By Page Ranges", description: String = "Split PDF using custom page ranges") -> SplitStrategy {
        SplitStrategy(
            type: .byPageRange,
            name: name,
            description: description,
            iconName: "text.insert"
        )
    }
    
    /// Create a size-based split strategy
    static func bySize(name: String = "By File Size", description: String = "Split PDF into chunks with approximately equal file sizes") -> SplitStrategy {
        SplitStrategy(
            type: .bySize,
            name: name,
            description: description,
            iconName: "arrow.up.arrow.down"
        )
    }
    
    /// Create a bookmark-based split strategy
    static func byBookmark(name: String = "By Bookmarks", description: String = "Split PDF at bookmark/outline entries") -> SplitStrategy {
        SplitStrategy(
            type: .byBookmark,
            name: name,
            description: description,
            iconName: "bookmark"
        )
    }
}

// Internal namespace
private enum PdfSplitterInternal {
    typealias SplitStrategy = _SplitStrategy
    typealias SplitStrategyType = _SplitStrategyType
    typealias PageRange = _PageRange
    typealias SplitResult = _SplitResult
    typealias ExportFormat = _ExportFormat
    typealias NamingPattern = _NamingPattern
    typealias ProcessingStatus = _ProcessingStatus
    typealias PdfSplitterView = _PdfSplitterView
    typealias PdfSplitterViewModel = _PdfSplitterViewModel
    typealias SplitStrategySelector = _SplitStrategySelector
}
