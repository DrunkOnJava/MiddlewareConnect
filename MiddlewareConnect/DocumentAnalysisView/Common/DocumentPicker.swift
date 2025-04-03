import SwiftUI
import UniformTypeIdentifiers
import LLMServiceProvider

/// A versatile document selection component with multi-file support
///
/// Provides a comprehensive interface for selecting documents with robust validation,
/// progress indication, and preview capabilities to enhance document handling.
public struct DocumentPicker: View {
    /// Core view model for document picker functionality
    @StateObject private var viewModel: ViewModel
    
    /// Callback when document selection changes
    private let onDocumentsSelected: ([DocumentFile]) -> Void
    
    /// ViewModel managing document selection state
    public class ViewModel: ObservableObject {
        /// Currently selected documents
        @Published public var selectedDocuments: [DocumentFile] = []
        
        /// Whether a file selection operation is in progress
        @Published public var isSelecting: Bool = false
        
        /// Progress of current file loading operation (0.0-1.0)
        @Published public var loadingProgress: Double = 0.0
        
        /// Current error message if any
        @Published public var errorMessage: String?
        
        /// Currently supported file types
        @Published public var supportedTypes: [UTType] = [
            .pdf,
            .plainText,
            .rtf,
            .docx,
            .json,
            .csv
        ]
        
        /// Maximum allowed file size in bytes
        @Published public var maxFileSize: Int64 = 50 * 1024 * 1024 // 50MB
        
        /// Maximum number of files that can be selected
        @Published public var maxFileCount: Int = 10
        
        /// Whether multiple file selection is enabled
        @Published public var allowMultiple: Bool = true
        
        /// Initializes the view model with options
        /// - Parameters:
        ///   - allowMultiple: Whether to allow multi-file selection
        ///   - maxFileCount: Maximum number of files allowed
        ///   - maxFileSize: Maximum file size in bytes
        ///   - supportedTypes: Array of supported file types
        public init(
            allowMultiple: Bool = true,
            maxFileCount: Int = 10,
            maxFileSize: Int64 = 50 * 1024 * 1024,
            supportedTypes: [UTType] = [.pdf, .plainText, .rtf, .docx, .json, .csv]
        ) {
            self.allowMultiple = allowMultiple
            self.maxFileCount = maxFileCount
            self.maxFileSize = maxFileSize
            self.supportedTypes = supportedTypes
        }
        
        /// Add a document to the selection
        /// - Parameter document: Document to add
        /// - Returns: Boolean indicating success
        @discardableResult
        public func addDocument(_ document: DocumentFile) -> Bool {
            // Check maximum count constraint
            if selectedDocuments.count >= maxFileCount {
                errorMessage = "Maximum number of documents (\(maxFileCount)) reached"
                return false
            }
            
            // Check for duplicate
            if selectedDocuments.contains(where: { $0.id == document.id }) {
                errorMessage = "Document already added"
                return false
            }
            
            selectedDocuments.append(document)
            return true
        }
        
        /// Remove a document from the selection
        /// - Parameter document: Document to remove
        public func removeDocument(_ document: DocumentFile) {
            selectedDocuments.removeAll { $0.id == document.id }
        }
        
        /// Clear all selected documents
        public func clearDocuments() {
            selectedDocuments = []
        }
        
        /// Load documents from URLs
        /// - Parameter urls: Array of document URLs
        /// - Returns: Array of successfully loaded documents
        public func loadDocuments(from urls: [URL]) -> [DocumentFile] {
            var loadedDocuments: [DocumentFile] = []
            
            for (index, url) in urls.enumerated() {
                do {
                    // Report progress
                    loadingProgress = Double(index) / Double(urls.count)
                    
                    // Validate file type
                    guard let contentType = try url.resourceValues(forKeys: [.contentTypeKey]).contentType else {
                        continue
                    }
                    
                    if !supportedTypes.contains(where: { contentType.conforms(to: $0) }) {
                        continue
                    }
                    
                    // Validate file size
                    let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    if fileSize > maxFileSize {
                        continue
                    }
                    
                    // Create document
                    let document = try DocumentFile(url: url)
                    loadedDocuments.append(document)
                    
                    // Check if we've reached the maximum
                    if loadedDocuments.count + selectedDocuments.count >= maxFileCount {
                        break
                    }
                } catch {
                    // Continue with next file on error
                    continue
                }
            }
            
            loadingProgress = 1.0
            return loadedDocuments
        }
        
        /// Get a formatted description of supported file types
        /// - Returns: Human-readable file type description
        public func supportedTypeDescription() -> String {
            let typeNames = supportedTypes.map { type in
                type.localizedDescription ?? type.identifier.components(separatedBy: ".").last ?? "Unknown"
            }
            
            return typeNames.joined(separator: ", ")
        }
        
        /// Get a formatted description of size limit
        /// - Returns: Human-readable size limit
        public func sizeLimitDescription() -> String {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useMB, .useGB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: maxFileSize)
        }
    }
    
    /// Represents a document file for selection
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
        
        /// Thumbnail image if available
        public var thumbnail: UIImage?
        
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
            
            // Generate thumbnail if possible (for PDF documents)
            if UTType(self.contentType)?.conforms(to: .pdf) == true,
               let document = CGPDFDocument(url as CFURL),
               let page = document.page(at: 1) {
                
                let pageRect = page.getBoxRect(.mediaBox)
                let renderer = UIGraphicsImageRenderer(size: pageRect.size)
                
                self.thumbnail = renderer.image { context in
                    UIColor.white.set()
                    context.fill(pageRect)
                    
                    context.cgContext.translateBy(x: 0, y: pageRect.size.height)
                    context.cgContext.scaleBy(x: 1.0, y: -1.0)
                    context.cgContext.drawPDFPage(page)
                }
            }
        }
    }
    
    /// Configuration options for the picker
    public struct Configuration {
        /// Text to display on the picker button
        public let buttonText: String
        
        /// Icon to display on the picker button
        public let buttonIcon: String
        
        /// Text to display when no documents are selected
        public let emptyStateText: String
        
        /// Whether to show document previews
        public let showPreviews: Bool
        
        /// Whether to show a drag & drop area
        public let enableDragAndDrop: Bool
        
        /// Creates a default configuration
        public static let `default` = Configuration(
            buttonText: "Select Documents",
            buttonIcon: "doc.badge.plus",
            emptyStateText: "No documents selected",
            showPreviews: true,
            enableDragAndDrop: true
        )
    }
    
    /// Initializes a document picker with default settings
    /// - Parameter onDocumentsSelected: Callback when selection changes
    public init(
        onDocumentsSelected: @escaping ([DocumentFile]) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: ViewModel())
        self.onDocumentsSelected = onDocumentsSelected
    }
    
    /// Initializes a document picker with custom configuration
    /// - Parameters:
    ///   - viewModel: View model for the picker
    ///   - configuration: Visual configuration
    ///   - onDocumentsSelected: Callback when selection changes
    public init(
        viewModel: ViewModel,
        configuration: Configuration = .default,
        onDocumentsSelected: @escaping ([DocumentFile]) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onDocumentsSelected = onDocumentsSelected
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Document selection controls
            HStack {
                Text("Documents")
                    .font(.headline)
                
                Spacer()
                
                // Document info
                if !viewModel.selectedDocuments.isEmpty {
                    HStack(spacing: 8) {
                        Text("\(viewModel.selectedDocuments.count) selected")
                            .font(.callout)
                            .foregroundColor(.gray)
                        
                        Button(action: viewModel.clearDocuments) {
                            Label("Clear All", systemImage: "xmark.circle")
                                .font(.callout)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                // File picker button
                documentPickerButton
            }
            
            // Main document area
            if viewModel.selectedDocuments.isEmpty {
                emptyStateView
            } else {
                documentListView
            }
            
            // Constraints info
            HStack {
                Label("Formats: \(viewModel.supportedTypeDescription())", systemImage: "doc.text")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Label("Max \(viewModel.sizeLimitDescription())", systemImage: "arrow.up.doc")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if viewModel.allowMultiple {
                    Label("Max \(viewModel.maxFileCount) files", systemImage: "number")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Error message if any
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
            
            // Loading progress
            if viewModel.isSelecting {
                ProgressView(value: viewModel.loadingProgress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
        }
        .padding()
        .onChange(of: viewModel.selectedDocuments) { documents in
            onDocumentsSelected(documents)
        }
    }
    
    /// Document picker button
    private var documentPickerButton: some View {
        DocumentPickerButton(
            allowMultiple: viewModel.allowMultiple,
            supportedTypes: viewModel.supportedTypes
        ) { urls in
            // Start loading process
            viewModel.isSelecting = true
            viewModel.loadingProgress = 0.0
            
            // Process in background
            DispatchQueue.global(qos: .userInitiated).async {
                let documents = viewModel.loadDocuments(from: urls)
                
                // Update on main thread
                DispatchQueue.main.async {
                    // Add documents to selection
                    for document in documents {
                        viewModel.addDocument(document)
                    }
                    
                    viewModel.isSelecting = false
                }
            }
        }
    }
    
    /// Document list view
    private var documentListView: some View {
        List {
            ForEach(viewModel.selectedDocuments) { document in
                documentRow(document)
            }
            .onDelete { indexSet in
                let documentsToRemove = indexSet.map { viewModel.selectedDocuments[$0] }
                for document in documentsToRemove {
                    viewModel.removeDocument(document)
                }
            }
        }
        .listStyle(PlainListStyle())
        .frame(height: 200)
    }
    
    /// Single document row
    private func documentRow(_ document: DocumentFile) -> some View {
        HStack(spacing: 12) {
            // Document thumbnail or icon
            if let thumbnail = document.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
            } else {
                documentIcon(for: document)
                    .frame(width: 40, height: 40)
            }
            
            // Document details
            VStack(alignment: .leading, spacing: 4) {
                Text(document.filename)
                    .font(.body)
                    .lineLimit(1)
                
                HStack {
                    Text(document.contentType)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(formatFileSize(document.fileSize))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Remove button
            Button(action: {
                viewModel.removeDocument(document)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
    
    /// Icon for a document type
    private func documentIcon(for document: DocumentFile) -> some View {
        let (systemName, color) = iconConfiguration(for: document.contentType)
        
        return Image(systemName: systemName)
            .font(.system(size: 24))
            .foregroundColor(color)
            .padding(8)
            .background(color.opacity(0.1))
            .cornerRadius(4)
    }
    
    /// Determines icon and color for a document type
    private func iconConfiguration(for contentType: String) -> (String, Color) {
        if let utType = UTType(contentType) {
            if utType.conforms(to: .pdf) {
                return ("doc.richtext.fill", .red)
            } else if utType.conforms(to: .plainText) || utType.conforms(to: .text) {
                return ("doc.text.fill", .blue)
            } else if utType.conforms(to: .rtf) || utType.conforms(to: .rtfd) {
                return ("doc.richtext.fill", .orange)
            } else if utType.conforms(to: .spreadsheet) || contentType.contains("csv") {
                return ("tablecells.fill", .green)
            } else if contentType.contains("word") || contentType.contains("docx") {
                return ("doc.richtext.fill", .blue)
            } else if contentType.contains("json") {
                return ("curlybraces", .purple)
            }
        }
        
        return ("doc.fill", .gray)
    }
    
    /// Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No documents selected")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Click 'Select Documents' to choose files")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    /// Format file size for display
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

/// UIKit document picker wrapped for SwiftUI
struct DocumentPickerButton: UIViewControllerRepresentable {
    /// Whether multiple files can be selected
    let allowMultiple: Bool
    
    /// Supported file types
    let supportedTypes: [UTType]
    
    /// Callback when files are selected
    let onPick: ([URL]) -> Void
    
    /// Creates the picker view controller
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = allowMultiple
        return picker
    }
    
    /// Updates the picker view controller
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        uiViewController.allowsMultipleSelection = allowMultiple
    }
    
    /// Creates the coordinator for UIKit integration
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Coordinator for UIKit document picker
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        /// Parent picker button
        let parent: DocumentPickerButton
        
        /// Initializes the coordinator
        /// - Parameter parent: Parent picker button
        init(_ parent: DocumentPickerButton) {
            self.parent = parent
        }
        
        /// Called when the user picks documents
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onPick(urls)
        }
    }
}

// MARK: - Preview Support
#if DEBUG
struct DocumentPicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Default document picker
            DocumentPicker { documents in
                // Handle document selection
                print("Selected \(documents.count) documents")
            }
            .padding()
            .previewDisplayName("Default Picker")
            
            // Custom configured picker
            DocumentPicker(
                viewModel: DocumentPicker.ViewModel(
                    allowMultiple: true,
                    maxFileCount: 5,
                    maxFileSize: 10 * 1024 * 1024,
                    supportedTypes: [.pdf, .plainText]
                )
            ) { documents in
                // Handle document selection
                print("Selected \(documents.count) documents")
            }
            .padding()
            .previewDisplayName("Custom Configuration")
        }
    }
}
#endif
