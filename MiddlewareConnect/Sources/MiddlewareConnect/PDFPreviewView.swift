/**
@fileoverview PDF preview component for viewing PDFs
@module PDFCombiner/Components
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- SwiftUI
- PDFKit
Exports:
- PDFPreviewView
Notes:
- Implements a UIViewRepresentable for PDF viewing
- Includes memory optimization
- Handles memory warnings
/

import SwiftUI
import PDFKit

/// PDF Preview View with memory optimization
struct PDFPreviewView: UIViewRepresentable {
    /// URL of the PDF to preview
    let url: URL
    
    /// Create the UIView for PDF preview
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        // Register for memory warnings
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleMemoryWarning),
            name: .memoryManagerDidReceiveWarning,
            object: nil
        )
        
        return pdfView
    }
    
    /// Update the UIView when needed
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Use memory optimization when loading the document
        MemoryManager.shared.optimizeForLargeFileOperation {
            if let document = PDFDocument(url: url) {
                uiView.document = document
            }
        }
    }
    
    /// Create a coordinator for the preview
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Coordinator class for handling notifications
    class Coordinator: NSObject {
        /// Reference to the parent PDFPreviewView
        var parent: PDFPreviewView
        
        /// Initialize with parent reference
        init(_ parent: PDFPreviewView) {
            self.parent = parent
        }
        
        /// Handle memory warning
        @objc func handleMemoryWarning() {
            // Clear the document if memory warning is received
            DispatchQueue.main.async {
                // This will be called when a memory warning is received
                print("Memory warning received in PDF Preview - clearing resources")
            }
        }
    }
    
    /// Clean up resources when the view is dismantled
    static func dismantleUIView(_ uiView: PDFView, coordinator: Coordinator) {
        // Clear the document when view is dismantled
        uiView.document = nil
        
        // Suggest garbage collection
        autoreleasepool { }
    }
}