/**
@fileoverview PDF Splitter tool for dividing PDFs into smaller documents
@module PdfSplitterView
Created: 2025-04-01
Last Modified: 2025-04-01
Dependencies:
- SwiftUI
- PDFKit
Exports:
- PdfSplitterView
/

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

/// PDF Splitter View for dividing PDF files into smaller documents
struct PdfSplitterView: View {
    // MARK: - State Variables
    @State private var selectedPDF: PDFDocument? = nil
    @State private var selectedPDFURL: URL? = nil
    @State private var pageRanges: [PageRange] = []
    @State private var isShowingDocumentPicker = false
    @State private var isProcessing = false
    @State private var showResult = false
    @State private var resultMessage = ""
    @State private var saveLocation: URL? = nil
    @State private var showingSavePicker = false
    @State private var currentPageRange: PageRange = PageRange(startPage: 1, endPage: 1, name: "")
    @State private var showingPageRangeEditor = false
    
    // MARK: - Computed Properties
    private var totalPageCount: Int {
        selectedPDF?.pageCount ?? 0
    }
    
    private var isValidPageRange: Bool {
        guard let pdf = selectedPDF else { return false }
        
        return currentPageRange.startPage > 0 &&
               currentPageRange.startPage <= pdf.pageCount &&
               currentPageRange.endPage >= currentPageRange.startPage &&
               currentPageRange.endPage <= pdf.pageCount &&
               !currentPageRange.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var rangeTotalPages: Int {
        pageRanges.reduce(0) { total, range in
            total + (range.endPage - range.startPage + 1)
        }
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                    
                    Text("PDF Splitter")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(LinearGradient(
                    gradient: Gradient(colors: [.red.opacity(0.7), .red.opacity(0.5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .cornerRadius(12)
                
                // Description
                Text("Split PDF files into smaller documents by defining custom page ranges.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // PDF Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Select PDF File")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if let selectedPDF = selectedPDF, let url = selectedPDFURL {
                        // Selected PDF info
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundColor(.red)
                                
                                Text(url.lastPathComponent)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Button(action: {
                                    self.selectedPDF = nil
                                    self.selectedPDFURL = nil
                                    self.pageRanges = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Text("\(totalPageCount) pages")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    } else {
                        // Select PDF Button
                        Button(action: {
                            isShowingDocumentPicker = true
                        }) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Select PDF File")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Page Range Definition (if PDF is selected)
                if selectedPDF != nil {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("2. Define Page Ranges")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Page ranges list
                        if !pageRanges.isEmpty {
                            VStack(spacing: 10) {
                                ForEach(pageRanges.indices, id: \.self) { index in
                                    pageRangeCard(pageRanges[index], index: index)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Add Range Button
                        Button(action: {
                            currentPageRange = PageRange(startPage: 1, endPage: totalPageCount, name: "Split \(pageRanges.count + 1)")
                            showingPageRangeEditor = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add Page Range")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Range stats
                        if !pageRanges.isEmpty {
                            Text("Pages selected: \(rangeTotalPages) of \(totalPageCount)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                    
                    // Split Button
                    VStack(alignment: .leading, spacing: 10) {
                        Text("3. Split PDF")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Button(action: {
                            splitPDF()
                        }) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Split PDF")
                                    .fontWeight(.semibold)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(pageRanges.isEmpty ? Color.gray : Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(pageRanges.isEmpty || isProcessing)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("PDF Splitter")
        .alert(isPresented: $showResult) {
            Alert(
                title: Text(resultMessage.contains("Error") ? "Error" : "Success"),
                message: Text(resultMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPicker(contentTypes: [UTType.pdf], onPick: { urls in
                if let url = urls.first, let pdf = PDFDocument(url: url) {
                    selectedPDF = pdf
                    selectedPDFURL = url
                    
                    // Default page range for the whole document
                    currentPageRange = PageRange(
                        startPage: 1,
                        endPage: pdf.pageCount,
                        name: "Complete Document"
                    )
                }
            })
        }
        .sheet(isPresented: $showingPageRangeEditor) {
            pageRangeEditorView()
                .presentationDetents([.medium])
        }
    }
    
    // MARK: - Views
    
    private func pageRangeCard(_ range: PageRange, index: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(range.name)
                    .font(.headline)
                
                Text("Pages \(range.startPage) to \(range.endPage) (\(range.endPage - range.startPage + 1) pages)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Delete button
            Button(action: {
                pageRanges.remove(at: index)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
    
    private func pageRangeEditorView() -> some View {
        NavigationView {
            Form {
                Section(header: Text("Range Name")) {
                    TextField("Enter a name for this range", text: $currentPageRange.name)
                }
                
                Section(header: Text("Page Range")) {
                    Stepper("Start Page: \(currentPageRange.startPage)", value: $currentPageRange.startPage, in: 1...totalPageCount)
                    
                    Stepper("End Page: \(currentPageRange.endPage)", value: $currentPageRange.endPage, in: currentPageRange.startPage...totalPageCount)
                    
                    Text("\(currentPageRange.endPage - currentPageRange.startPage + 1) pages selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Page Range")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingPageRangeEditor = false
                },
                trailing: Button("Add") {
                    if isValidPageRange {
                        pageRanges.append(currentPageRange)
                        showingPageRangeEditor = false
                    }
                }
                .disabled(!isValidPageRange)
            )
        }
    }
    
    // MARK: - Logic
    
    private func splitPDF() {
        guard let pdfDocument = selectedPDF, !pageRanges.isEmpty else { return }
        
        isProcessing = true
        
        // Create output folder
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent("PDFSplitter_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            
            // Process each range
            for range in pageRanges {
                let newPDF = PDFDocument()
                
                // Add pages from the range
                for i in (range.startPage-1)..<range.endPage {
                    if let page = pdfDocument.page(at: i) {
                        newPDF.insert(page, at: newPDF.pageCount)
                    }
                }
                
                // Save the PDF
                let sanitizedName = range.name.replacingOccurrences(of: "/", with: "-")
                let fileURL = directoryURL.appendingPathComponent("\(sanitizedName).pdf")
                
                if newPDF.write(to: fileURL) {
                    print("Successfully wrote PDF to \(fileURL.path)")
                } else {
                    throw NSError(domain: "PDFSplitterError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to write PDF file for range \(range.name)"])
                }
            }
            
            // Show success message
            DispatchQueue.main.async {
                isProcessing = false
                resultMessage = "Successfully split PDF into \(pageRanges.count) files."
                showResult = true
                
                // Reset the state
                pageRanges = []
            }
        } catch {
            DispatchQueue.main.async {
                isProcessing = false
                resultMessage = "Error: \(error.localizedDescription)"
                showResult = true
            }
        }
    }
}

// MARK: - Supporting Types

/// Structure for defining a range of pages
struct PageRange {
    var startPage: Int
    var endPage: Int
    var name: String
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onPick: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
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
            parent.onPick(urls)
        }
    }
}

struct PdfSplitterView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PdfSplitterView()
        }
    }
}
