import SwiftUI
import PDFKit

/// A comprehensive PDF rendering component with advanced viewing capabilities
///
/// Provides rich PDF viewing capabilities with page navigation, zoom control,
/// and text selection integrated with PDFKit.
public struct PDFPreviewView: View {
    /// Core view model for PDF preview functionality
    @StateObject private var viewModel: ViewModel
    
    /// ViewModel handling PDF document state and interaction
    public class ViewModel: ObservableObject {
        /// Current PDF document being displayed
        @Published public private(set) var document: PDFDocument?
        
        /// Current page index being displayed
        @Published public var currentPage: Int = 0
        
        /// Total number of pages in the document
        @Published public private(set) var pageCount: Int = 0
        
        /// Current zoom scale factor
        @Published public var zoomScale: Double = 1.0
        
        /// Currently selected text
        @Published public private(set) var selectedText: String?
        
        /// Selection coordinates for highlighting
        @Published public private(set) var selectionRects: [CGRect] = []
        
        /// Current viewing mode for the document
        @Published public var viewMode: ViewMode = .singlePage
        
        /// URL of the current document if loaded from file
        private var documentURL: URL?
        
        /// Loads a PDF document from a URL
        /// - Parameter url: URL of the PDF file
        /// - Returns: Boolean indicating success
        @discardableResult
        public func loadDocument(from url: URL) -> Bool {
            // Create a PDF document from the URL
            guard let document = PDFDocument(url: url) else {
                return false
            }
            
            self.document = document
            self.documentURL = url
            self.pageCount = document.pageCount
            self.currentPage = 0
            self.zoomScale = 1.0
            self.selectedText = nil
            self.selectionRects = []
            
            return true
        }
        
        /// Loads a PDF document from Data
        /// - Parameter data: PDF document data
        /// - Returns: Boolean indicating success
        @discardableResult
        public func loadDocument(from data: Data) -> Bool {
            // Create a PDF document from the data
            guard let document = PDFDocument(data: data) else {
                return false
            }
            
            self.document = document
            self.documentURL = nil
            self.pageCount = document.pageCount
            self.currentPage = 0
            self.zoomScale = 1.0
            self.selectedText = nil
            self.selectionRects = []
            
            return true
        }
        
        /// Navigates to the specified page
        /// - Parameter page: Target page index
        public func goToPage(_ page: Int) {
            guard let document = document, page >= 0, page < pageCount else {
                return
            }
            
            currentPage = page
        }
        
        /// Moves to the next page if available
        public func nextPage() {
            if currentPage < pageCount - 1 {
                currentPage += 1
            }
        }
        
        /// Moves to the previous page if available
        public func previousPage() {
            if currentPage > 0 {
                currentPage -= 1
            }
        }
        
        /// Zooms in on the document
        public func zoomIn() {
            zoomScale = min(zoomScale * 1.25, 5.0)
        }
        
        /// Zooms out from the document
        public func zoomOut() {
            zoomScale = max(zoomScale / 1.25, 0.25)
        }
        
        /// Resets zoom to default
        public func resetZoom() {
            zoomScale = 1.0
        }
        
        /// Updates the currently selected text
        /// - Parameter text: Selected text string
        public func updateSelectedText(_ text: String?) {
            selectedText = text
        }
        
        /// Updates the selection rectangle coordinates
        /// - Parameter rects: Array of selection rectangles
        public func updateSelectionRects(_ rects: [CGRect]) {
            selectionRects = rects
        }
        
        /// Extracts all text from the current document
        /// - Returns: Complete text content or nil if unavailable
        public func extractAllText() -> String? {
            return document?.string
        }
        
        /// Extracts text from a specific page
        /// - Parameter page: Page index
        /// - Returns: Text content from the page or nil if unavailable
        public func extractTextFromPage(_ page: Int) -> String? {
            guard let document = document, page >= 0, page < pageCount,
                  let pdfPage = document.page(at: page) else {
                return nil
            }
            
            return pdfPage.string
        }
        
        /// Searches for text in the document
        /// - Parameter searchText: Text to search for
        /// - Returns: Array of search results
        public func search(for searchText: String) -> [PDFSelection] {
            guard let document = document, !searchText.isEmpty else {
                return []
            }
            
            return document.findString(searchText, withOptions: .caseInsensitive)
        }
        
        /// Gets a thumbnail image for a specific page
        /// - Parameters:
        ///   - page: Page index
        ///   - size: Desired thumbnail size
        /// - Returns: Optional thumbnail image
        public func thumbnailForPage(_ page: Int, size: CGSize) -> UIImage? {
            guard let document = document, page >= 0, page < pageCount,
                  let pdfPage = document.page(at: page) else {
                return nil
            }
            
            return pdfPage.thumbnail(of: size, for: .mediaBox)
        }
    }
    
    /// Viewing modes for PDF display
    public enum ViewMode {
        /// Single page at a time
        case singlePage
        
        /// Continuous scrolling through pages
        case continuous
        
        /// Two pages side-by-side
        case twoUp
    }
    
    /// Coordinator class for interfacing with PDFKit
    public class Coordinator: NSObject, PDFViewDelegate {
        /// Reference to parent view model
        private var viewModel: ViewModel
        
        /// Initializes a new coordinator
        /// - Parameter viewModel: Parent view model
        init(viewModel: ViewModel) {
            self.viewModel = viewModel
            super.init()
        }
        
        /// Called when the current page changes
        public func pdfViewPageChanged(_ pdfView: PDFView) {
            if let currentPage = pdfView.currentPage,
               let document = pdfView.document,
               let pageIndex = document.index(for: currentPage) {
                viewModel.goToPage(pageIndex)
            }
        }
        
        /// Called when text is selected
        public func pdfViewSelectionChanged(_ pdfView: PDFView) {
            if let selection = pdfView.currentSelection {
                viewModel.updateSelectedText(selection.string)
                
                var rects: [CGRect] = []
                for i in 0..<selection.numberOfRanges {
                    if let page = selection.page(at: i),
                       let pageRect = selection.bounds(for: page) {
                        rects.append(pageRect)
                    }
                }
                viewModel.updateSelectionRects(rects)
            } else {
                viewModel.updateSelectedText(nil)
                viewModel.updateSelectionRects([])
            }
        }
    }
    
    /// UIKit PDF view wrapped for SwiftUI
    public struct PDFKitView: UIViewRepresentable {
        /// View model to coordinate with
        @ObservedObject var viewModel: ViewModel
        
        /// Creates the PDF view
        public func makeUIView(context: Context) -> PDFView {
            let pdfView = PDFView()
            pdfView.document = viewModel.document
            pdfView.delegate = context.coordinator
            pdfView.autoScales = true
            pdfView.displayMode = displayMode(for: viewModel.viewMode)
            pdfView.displayDirection = .vertical
            pdfView.usePageViewController(true)
            pdfView.pageBreakMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
            
            if viewModel.pageCount > 0, let page = viewModel.document?.page(at: viewModel.currentPage) {
                pdfView.go(to: page)
            }
            
            return pdfView
        }
        
        /// Updates the PDF view when SwiftUI state changes
        public func updateUIView(_ pdfView: PDFView, context: Context) {
            // Update document if needed
            if pdfView.document != viewModel.document {
                pdfView.document = viewModel.document
            }
            
            // Update current page
            if viewModel.pageCount > 0,
               let document = viewModel.document,
               let currentUIPage = pdfView.currentPage,
               let currentIndex = document.index(for: currentUIPage),
               currentIndex != viewModel.currentPage,
               let targetPage = document.page(at: viewModel.currentPage) {
                pdfView.go(to: targetPage)
            }
            
            // Update zoom scale
            pdfView.scaleFactor = CGFloat(viewModel.zoomScale)
            
            // Update display mode
            pdfView.displayMode = displayMode(for: viewModel.viewMode)
        }
        
        /// Creates the coordinator for UIKit integration
        public func makeCoordinator() -> Coordinator {
            Coordinator(viewModel: viewModel)
        }
        
        /// Maps view mode to PDFDisplayMode
        private func displayMode(for viewMode: ViewMode) -> PDFDisplayMode {
            switch viewMode {
            case .singlePage:
                return .singlePage
            case .continuous:
                return .singlePageContinuous
            case .twoUp:
                return .twoUp
            }
        }
    }
    
    /// Initializes a PDF preview view
    /// - Parameter url: Optional URL of PDF to display
    public init(url: URL? = nil) {
        let viewModel = ViewModel()
        self._viewModel = StateObject(wrappedValue: viewModel)
        
        if let url = url {
            viewModel.loadDocument(from: url)
        }
    }
    
    /// Initializes a PDF preview with a pre-configured view model
    /// - Parameter viewModel: View model for the preview
    public init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack {
            // PDF view
            if viewModel.document != nil {
                PDFKitView(viewModel: viewModel)
                    .padding(1)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                
                // Controls below PDF
                controlBar
            } else {
                // Empty state
                emptyStateView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Control bar for PDF interaction
    private var controlBar: some View {
        VStack(spacing: 8) {
            // Page navigation controls
            HStack {
                Button(action: viewModel.previousPage) {
                    Image(systemName: "chevron.left")
                }
                .disabled(viewModel.currentPage <= 0)
                
                Text("Page \(viewModel.currentPage + 1) of \(viewModel.pageCount)")
                    .frame(minWidth: 120)
                
                Button(action: viewModel.nextPage) {
                    Image(systemName: "chevron.right")
                }
                .disabled(viewModel.currentPage >= viewModel.pageCount - 1)
                
                Spacer()
                
                // View mode selector
                Picker("View Mode", selection: $viewModel.viewMode) {
                    Image(systemName: "doc.text").tag(ViewMode.singlePage)
                    Image(systemName: "doc.text.below.ecg").tag(ViewMode.continuous)
                    Image(systemName: "doc.text.beside.doc.text").tag(ViewMode.twoUp)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            
            // Zoom controls
            HStack {
                Button(action: viewModel.zoomOut) {
                    Image(systemName: "minus.magnifyingglass")
                }
                
                Slider(
                    value: $viewModel.zoomScale,
                    in: 0.25...5.0,
                    step: 0.25
                )
                .frame(width: 150)
                
                Button(action: viewModel.zoomIn) {
                    Image(systemName: "plus.magnifyingglass")
                }
                
                Button(action: viewModel.resetZoom) {
                    Text("Reset")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                
                Spacer()
                
                // Text selection info
                if let selectedText = viewModel.selectedText, !selectedText.isEmpty {
                    HStack {
                        Text("Selected: \(selectedText.prefix(20))")
                            .font(.caption)
                            .lineLimit(1)
                        
                        Button(action: {
                            // Copy text to clipboard
                            UIPasteboard.general.string = selectedText
                        }) {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
    }
    
    /// Empty state when no document is loaded
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No PDF Document Loaded")
                .font(.headline)
            
            Button("Select PDF") {
                // Document selection would trigger a delegate/callback
                // to the parent view to show a file picker
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.05))
    }
}

// MARK: - PDF Document Extensions
extension PDFDocument {
    /// Gets the total page count
    var pageCount: Int {
        return pageCount
    }
}

// MARK: - Preview Support
#if DEBUG
struct PDFPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty state
            PDFPreviewView()
                .previewDisplayName("Empty State")
            
            // With mock document
            PDFPreviewView(viewModel: mockViewModel())
                .previewDisplayName("With Document")
        }
    }
    
    static func mockViewModel() -> PDFPreviewView.ViewModel {
        let viewModel = PDFPreviewView.ViewModel()
        
        // Create a simple PDF for preview
        let pdfMetadata = [
            kCGPDFContextCreator: "PDFPreviewView Preview",
            kCGPDFContextAuthor: "MiddlewareConnect"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetadata as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            // First page
            context.beginPage()
            let textRect = CGRect(x: 50, y: 50, width: pageRect.width - 100, height: pageRect.height - 100)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: paragraphStyle
            ]
            
            let text = "This is a sample PDF document created for the PDFPreviewView component preview. It contains multiple pages with text content to demonstrate pagination, zooming, and text selection capabilities."
            
            text.draw(in: textRect, withAttributes: attributes)
            
            // Second page
            context.beginPage()
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        // Load the generated PDF data
        viewModel.loadDocument(from: data)
        
        return viewModel
    }
}
#endif
