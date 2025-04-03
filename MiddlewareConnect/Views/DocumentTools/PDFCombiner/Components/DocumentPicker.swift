/**
 * @fileoverview Document picker component for selecting PDFs
 * @module PDFCombiner/Components
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - SwiftUI
 * - UniformTypeIdentifiers
 * 
 * Exports:
 * - DocumentPicker
 * 
 * Notes:
 * - Implements a UIViewControllerRepresentable for iOS document picking
 * - Supports multiple selection of PDF files
 * - Uses a callback for picked document handling
 */

import SwiftUI
import UniformTypeIdentifiers

/// Document Picker for selecting PDFs
struct DocumentPicker: UIViewControllerRepresentable {
    /// Content types the picker can select
    let contentTypes: [UTType]
    
    /// Callback for when documents are picked
    let onPick: ([URL]) -> Void
    
    /// Create the UIViewController
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    /// Update the UIViewController
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No updates needed here
    }
    
    /// Create a coordinator for the picker
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Coordinator class for handling UIDocumentPickerViewController delegate methods
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        /// Reference to the parent DocumentPicker
        let parent: DocumentPicker
        
        /// Initialize with parent reference
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        /// Handle picked documents
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onPick(urls)
        }
    }
}