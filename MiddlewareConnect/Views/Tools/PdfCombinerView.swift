/**
 * @fileoverview PDF combiner tool view
 * @module PdfCombinerView
 * 
 * Created: 2025-03-29
 * Last Modified: 2025-03-29
 * 
 * Dependencies:
 * - SwiftUI
 * - PDFKit
 * 
 * Exports:
 * - PdfCombinerView struct
 */

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

/// View for PDF combining functionality
struct PdfCombinerView: View {
    @State private var pdfDocuments: [PDFDocument] = []
    @State private var documentNames: [String] = []
    @State private var isShowingDocumentPicker = false
    @State private var isExporting = false
    @State private var combinedDocument: PDFDocument?
    @State private var isProcessing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("PDF Combiner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Combine multiple PDF files into a single document")
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // Add files button
                Button(action: {
                    isShowingDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add PDF Files")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .sheet(isPresented: $isShowingDocumentPicker) {
                    DocumentPicker(
                        types: [UTType.pdf],
                        allowsMultiple: true,
                        onDocumentsPicked: { urls in
                            loadPDFs(from: urls)
                        }
                    )
                }
                
                // PDF list
                if !pdfDocuments.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Selected PDFs (\(pdfDocuments.count))")
                            .font(.headline)
                            .padding(.top)
                        
                        ForEach(0..<pdfDocuments.count, id: \.self) { index in
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading) {
                                    Text(documentNames[index])
                                        .lineLimit(1)
                                    
                                    if let pageCount = pdfDocuments[index].pageCount {
                                        Text("\(pageCount) pages")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    removePDF(at: index)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Reorder instructions
                        Text("Drag to reorder files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                }
                
                // Combine button
                if pdfDocuments.count >= 2 {
                    Button(action: combineDocuments) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Combine PDFs")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(isProcessing)
                    .padding(.top)
                }
                
                // Export button
                if combinedDocument != nil {
                    Button(action: {
                        isExporting = true
                    }) {
                        Text("Export Combined PDF")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    /// Load PDFs from URLs
    private func loadPDFs(from urls: [URL]) {
        for url in urls {
            if let document = PDFDocument(url: url) {
                pdfDocuments.append(document)
                documentNames.append(url.lastPathComponent)
            }
        }
    }
    
    /// Remove a PDF at the given index
    private func removePDF(at index: Int) {
        pdfDocuments.remove(at: index)
        documentNames.remove(at: index)
        
        // Reset combined document when PDFs change
        combinedDocument = nil
    }
    
    /// Combine the PDF documents
    private func combineDocuments() {
        guard pdfDocuments.count >= 2 else { return }
        
        isProcessing = true
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let newDocument = PDFDocument()
            
            for document in pdfDocuments {
                guard let pageCount = document.pageCount else { continue }
                
                for i in 0..<pageCount {
                    if let page = document.page(at: i) {
                        newDocument.insert(page, at: newDocument.pageCount)
                    }
                }
            }
            
            combinedDocument = newDocument
            isProcessing = false
        }
    }
}

/// Document picker for selecting PDF files
struct DocumentPicker: UIViewControllerRepresentable {
    let types: [UTType]
    let allowsMultiple: Bool
    let onDocumentsPicked: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = allowsMultiple
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
