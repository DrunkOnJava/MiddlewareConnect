import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct DocumentSummarizerView: View {
    @EnvironmentObject var appState: AppState
    @State private var documentText: String = ""
    @State private var summaryText: String = ""
    @State private var selectedLengthIndex = 1 // Default to moderate
    @State private var isSummarizing: Bool = false
    @State private var error: Error? = nil
    @State private var showError: Bool = false
    @State private var isShowingDocumentPicker = false
    @State private var selectedPDFURL: URL? = nil
    @State private var documentTitle: String = ""
    
    private let anthropicService = AnthropicService()
    private let pdfService = PDFService()
    
    private let summaryLengths: [SummaryLength] = [
        .brief,
        .moderate,
        .detailed
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Document Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Document")
                        .font(.headline)
                    
                    if selectedPDFURL != nil {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(documentTitle)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                
                                if let pdfURL = selectedPDFURL, let pdfInfo = try? pdfService.getPDFInfo(url: pdfURL) {
                                    Text("\(pdfInfo.pageCount) pages • \(pdfInfo.fileSizeFormatted)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                selectedPDFURL = nil
                                documentText = ""
                                documentTitle = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    } else {
                        Button(action: {
                            isShowingDocumentPicker = true
                        }) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Select PDF Document")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
                
                // Text Input (if no PDF is selected)
                if selectedPDFURL == nil {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Text to Summarize")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("\(documentText.count) characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        TextEditor(text: $documentText)
                            .font(.body)
                            .frame(minHeight: 200)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                
                // Summary Length Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary Length")
                        .font(.headline)
                    
                    Picker("Length", selection: $selectedLengthIndex) {
                        Text("Brief").tag(0)
                        Text("Moderate").tag(1)
                        Text("Detailed").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Summarize Button
                Button(action: summarizeDocument) {
                    if isSummarizing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Summarize")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled((documentText.isEmpty && selectedPDFURL == nil) || isSummarizing)
                .padding(.vertical, 10)
                
                // Summary Output
                if !summaryText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Summary")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: copyOutputToClipboard) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        Text(summaryText)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Document Summarizer")
        .errorAlert(error: $error, showError: $showError)
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPicker(
                contentTypes: [UTType.pdf],
                onPick: { urls in
                    if let url = urls.first {
                        loadPDF(url: url)
                    }
                }
            )
        }
    }
    
    private func loadPDF(url: URL) {
        selectedPDFURL = url
        documentTitle = url.lastPathComponent
        
        // Extract text from PDF
        if let pdf = PDFDocument(url: url) {
            var text = ""
            for i in 0..<pdf.pageCount {
                if let page = pdf.page(at: i), let pageText = page.string {
                    text += pageText + "\n\n"
                }
            }
            documentText = text
        }
    }
    
    private func summarizeDocument() {
        guard !documentText.isEmpty || selectedPDFURL != nil else { return }
        
        isSummarizing = true
        
        anthropicService.summarizeDocument(
            text: documentText,
            length: summaryLengths[selectedLengthIndex]
        ) { result in
            isSummarizing = false
            
            switch result {
            case .success(let summary):
                summaryText = summary
            case .failure(let summarizationError):
                error = summarizationError
                showError = true
            }
        }
    }
    
    private func copyOutputToClipboard() {
        UIPasteboard.general.string = summaryText
        
        // Show a haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// Document Picker for selecting PDFs
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

struct DocumentSummarizerView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentSummarizerView()
            .environmentObject(AppState())
    }
}
