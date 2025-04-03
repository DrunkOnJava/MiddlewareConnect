import SwiftUI
#if canImport(UIKit)
#if canImport(UIKit)
import UIKit
#endif
#endif
import QuickLook
import UniformTypeIdentifiers

/// An enhanced document picker with thumbnails and recent documents
struct EnhancedDocumentPicker: UIViewControllerRepresentable {
    // MARK: - Properties
    
    /// The content types that can be selected
    let contentTypes: [UTType]
    
    /// Whether multiple files can be selected
    let allowsMultipleSelection: Bool
    
    /// Callback when files are picked
    let onPick: ([URL]) -> Void
    
    /// Whether to show recent documents
    let showsRecents: Bool
    
    // MARK: - Initialization
    
    init(
        contentTypes: [UTType],
        allowsMultipleSelection: Bool = true,
        showsRecents: Bool = true,
        onPick: @escaping ([URL]) -> Void
    ) {
        self.contentTypes = contentTypes
        self.allowsMultipleSelection = allowsMultipleSelection
        self.showsRecents = showsRecents
        self.onPick = onPick
    }
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.allowsMultipleSelection = allowsMultipleSelection
        picker.delegate = context.coordinator
        
        // Customize the document picker
        if #available(iOS 16.0, *) {
            // iOS 16+ customization
            picker.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            picker.shouldShowFileExtensions = true
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: EnhancedDocumentPicker
        
        init(_ parent: EnhancedDocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // Save to recents if enabled
            if parent.showsRecents {
                saveToRecentDocuments(urls: urls)
            }
            
            // Call the onPick callback
            parent.onPick(urls)
        }
        
        private func saveToRecentDocuments(urls: [URL]) {
            // Get the current recent documents
            var recentDocuments = UserDefaults.standard.array(forKey: "RecentDocuments") as? [String] ?? []
            
            // Add the new URLs to the recents
            for url in urls {
                let urlString = url.absoluteString
                
                // Remove if it already exists (to move it to the top)
                if let index = recentDocuments.firstIndex(of: urlString) {
                    recentDocuments.remove(at: index)
                }
                
                // Add to the beginning
                recentDocuments.insert(urlString, at: 0)
            }
            
            // Limit to 20 recent documents
            if recentDocuments.count > 20 {
                recentDocuments = Array(recentDocuments.prefix(20))
            }
            
            // Save back to UserDefaults
            UserDefaults.standard.set(recentDocuments, forKey: "RecentDocuments")
        }
    }
}

// MARK: - Recent Documents View

/// A view that displays recent documents with thumbnails
struct RecentDocumentsView: View {
    // MARK: - Properties
    
    /// The content types to filter by
    let contentTypes: [UTType]
    
    /// Callback when a document is selected
    let onSelect: (URL) -> Void
    
    /// The recent document URLs
    @State private var recentDocuments: [URL] = []
    
    /// The document thumbnails
    @State private var thumbnails: [URL: UIImage] = [:]
    
    // MARK: - Initialization
    
    init(contentTypes: [UTType], onSelect: @escaping (URL) -> Void) {
        self.contentTypes = contentTypes
        self.onSelect = onSelect
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            Text("Recent Documents")
                .font(DesignSystem.Typography.headline)
                .padding(.horizontal)
            
            if recentDocuments.isEmpty {
                Text("No recent documents")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        ForEach(recentDocuments, id: \.self) { url in
                            documentThumbnail(for: url)
                                .onTapGesture {
                                    onSelect(url)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            loadRecentDocuments()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadRecentDocuments() {
        // Get the recent document URLs from UserDefaults
        let recentDocumentStrings = UserDefaults.standard.array(forKey: "RecentDocuments") as? [String] ?? []
        
        // Convert to URLs and filter by content type
        recentDocuments = recentDocumentStrings.compactMap { urlString in
            guard let url = URL(string: urlString) else { return nil }
            
            // Check if the URL matches any of the content types
            if let fileType = try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
               let utType = UTType(fileType),
               contentTypes.contains(where: { utType.conforms(to: $0) }) {
                return url
            }
            
            return nil
        }
        
        // Load thumbnails for each document
        for url in recentDocuments {
            loadThumbnail(for: url)
        }
    }
    
    private func loadThumbnail(for url: URL) {
        // Create a thumbnail for the document
        let thumbnail = QLThumbnailGenerator.shared.generateBestRepresentation(
            for: QLFileThumbnailRequest(
                fileAt: url,
                size: CGSize(width: 120, height: 160),
                scale: UIScreen.main.scale,
                representationTypes: .thumbnail
            )
        ) { thumbnail, error in
            guard let thumbnail = thumbnail, error == nil else { return }
            
            // Update the thumbnail on the main thread
            DispatchQueue.main.async {
                thumbnails[url] = thumbnail.uiImage
            }
        }
    }
    
    private func documentThumbnail(for url: URL) -> some View {
        VStack {
            if let thumbnail = thumbnails[url] {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 100)
                    .cornerRadius(DesignSystem.Radius.small)
                    .shadow(radius: 2)
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                    .fill(DesignSystem.Colors.secondaryBackground)
                    .frame(width: 80, height: 100)
                    .overlay(
                        Image(systemName: documentIcon(for: url))
                            .font(.system(size: 30))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    )
            }
            
            Text(url.lastPathComponent)
                .font(DesignSystem.Typography.caption)
                .lineLimit(1)
                .frame(width: 80)
        }
        .accessibleButton(
            label: "Open \(url.lastPathComponent)",
            hint: "Opens this recent document"
        )
    }
    
    private func documentIcon(for url: URL) -> String {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return "doc.text"
        case "jpg", "jpeg", "png", "gif":
            return "photo"
        case "doc", "docx":
            return "doc.fill"
        case "xls", "xlsx":
            return "tablecells"
        case "ppt", "pptx":
            return "chart.bar"
        case "txt":
            return "doc.plaintext"
        case "zip", "rar":
            return "doc.zipper"
        default:
            return "doc"
        }
    }
}

// MARK: - Document Browser Integration

/// A view that integrates with the document browser
struct DocumentBrowserIntegration: UIViewControllerRepresentable {
    // MARK: - Properties
    
    /// The content types that can be selected
    let contentTypes: [UTType]
    
    /// Callback when a document is selected
    let onSelect: (URL) -> Void
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> UIDocumentBrowserViewController {
        let browser = UIDocumentBrowserViewController(forOpening: contentTypes)
        browser.delegate = context.coordinator
        browser.allowsDocumentCreation = false
        browser.allowsPickingMultipleItems = false
        
        return browser
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentBrowserViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UIDocumentBrowserViewControllerDelegate {
        let parent: DocumentBrowserIntegration
        
        init(_ parent: DocumentBrowserIntegration) {
            self.parent = parent
        }
        
        func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
            guard let url = documentURLs.first else { return }
            
            // Start accessing the security-scoped resource
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            // Call the onSelect callback
            parent.onSelect(url)
        }
    }
}

// MARK: - Preview

struct EnhancedDocumentPicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Enhanced Document Picker")
                .font(.headline)
                .padding()
            
            Button("Open Document Picker") {
                // This would show the document picker in a real app
            }
            .buttonStyle(.borderedProminent)
            
            Divider()
                .padding()
            
            RecentDocumentsView(
                contentTypes: [.pdf, .image],
                onSelect: { _ in }
            )
        }
    }
}
