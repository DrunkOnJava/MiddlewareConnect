/**
 * @fileoverview Document Analysis View
 * @module DocumentAnalysisView
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - SwiftUI
 * - PDFKit
 * 
 * Notes:
 * - UI for document analysis features
 * - Allows users to analyze, summarize, and extract information from PDFs
 */

import SwiftUI
import PDFKit

/// Document analysis view
struct DocumentAnalysisView: View {
    // MARK: - Properties
    
    /// LLM service provider
    @ObservedObject private var llmService = LLMServiceProvider.shared
    
    /// Selected PDF URL
    @State private var selectedPDFURL: URL?
    
    /// Show file picker
    @State private var showingFilePicker = false
    
    /// Summary
    @State private var summary: DocumentSummary?
    
    /// Entities
    @State private var entities: [ExtractedEntity] = []
    
    /// Selected summary length
    @State private var selectedLength: SummaryLength = .moderate
    
    /// Show entity details
    @State private var showingEntityDetails = false
    
    /// Selected entity
    @State private var selectedEntity: ExtractedEntity?
    
    /// Tab selection
    @State private var selectedTab = 0
    
    // MARK: - Views
    
    var body: some View {
        VStack {
            // Header
            headerView
            
            // Content
            if let selectedPDFURL = selectedPDFURL {
                TabView(selection: $selectedTab) {
                    // PDF Preview
                    pdfPreviewView(for: selectedPDFURL)
                        .tabItem {
                            Label("PDF", systemImage: "doc.text")
                        }
                        .tag(0)
                    
                    // Summary
                    summaryView
                        .tabItem {
                            Label("Summary", systemImage: "text.alignleft")
                        }
                        .tag(1)
                    
                    // Entities
                    entitiesView
                        .tabItem {
                            Label("Entities", systemImage: "person.text.rectangle")
                        }
                        .tag(2)
                }
                .padding()
            } else {
                placeholderView
            }
            
            // Loading overlay
            if llmService.status == .processing {
                loadingOverlay
            }
        }
        .sheet(isPresented: $showingFilePicker) {
            // File picker
            DocumentPicker { url in
                self.selectedPDFURL = url
                self.summary = nil
                self.entities = []
            }
        }
        .sheet(isPresented: $showingEntityDetails) {
            // Entity details
            if let entity = selectedEntity {
                EntityDetailView(entity: entity)
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { llmService.status == .error && llmService.errorMessage != nil },
            set: { _ in llmService.errorMessage = nil }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(llmService.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    /// Header view
    private var headerView: some View {
        HStack {
            Text("Document Analysis")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: {
                showingFilePicker = true
            }) {
                Label("Open PDF", systemImage: "doc.badge.plus")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    /// PDF preview view
    private func pdfPreviewView(for url: URL) -> some View {
        VStack {
            Text(url.lastPathComponent)
                .font(.headline)
                .padding(.bottom)
            
            PDFKitView(url: url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    /// Summary view
    private var summaryView: some View {
        VStack {
            // Summary controls
            HStack {
                Text("Summary Length:")
                
                Picker("Length", selection: $selectedLength) {
                    ForEach(SummaryLength.allCases) { length in
                        Text(length.displayName).tag(length)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 300)
                
                Spacer()
                
                Button(action: summarizeDocument) {
                    Label("Summarize", systemImage: "text.badge.plus")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(llmService.status == .processing || selectedPDFURL == nil)
            }
            .padding(.bottom)
            
            // Summary content
            if let summary = summary {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Summary")
                            .font(.headline)
                        
                        Text(summary.summaryText)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Text("Main Topics")
                            .font(.headline)
                        
                        ForEach(summary.mainTopics, id: \.self) { topic in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.blue)
                                
                                Text(topic)
                            }
                            .padding(.leading)
                        }
                        
                        Text("Document Info")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Title:")
                                    .fontWeight(.semibold)
                                Text(summary.documentTitle)
                            }
                            
                            HStack {
                                Text("Language:")
                                    .fontWeight(.semibold)
                                Text(summary.language ?? "Unknown")
                            }
                            
                            HStack {
                                Text("Token Count:")
                                    .fontWeight(.semibold)
                                Text("\(summary.tokenCount)")
                            }
                            
                            HStack {
                                Text("Generated:")
                                    .fontWeight(.semibold)
                                Text(formatDate(summary.createdAt))
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding()
                }
            } else {
                VStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    
                    Text("Click 'Summarize' to generate a document summary")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    /// Entities view
    private var entitiesView: some View {
        VStack {
            // Entities controls
            HStack {
                Text("Extracted Entities")
                    .font(.headline)
                
                Spacer()
                
                Button(action: extractEntities) {
                    Label("Extract Entities", systemImage: "person.text.rectangle")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(llmService.status == .processing || selectedPDFURL == nil)
            }
            .padding(.bottom)
            
            // Entities content
            if entities.isEmpty {
                VStack {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    
                    Text("Click 'Extract Entities' to identify entities in the document")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                entityListView
            }
        }
    }
    
    /// Entity list view
    private var entityListView: some View {
        VStack {
            // Entity type filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(entityTypes, id: \.self) { type in
                        Text(type)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(entityTypeColor(type))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
            }
            
            // Entity list
            List {
                ForEach(entities) { entity in
                    EntityRowView(entity: entity)
                        .onTapGesture {
                            selectedEntity = entity
                            showingEntityDetails = true
                        }
                }
            }
        }
    }
    
    /// Placeholder view
    private var placeholderView: some View {
        VStack {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 96))
                .foregroundColor(.gray)
            
            Text("Open a PDF to analyze")
                .font(.title2)
                .foregroundColor(.gray)
                .padding()
            
            Button(action: {
                showingFilePicker = true
            }) {
                Label("Select PDF", systemImage: "doc.badge.plus")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Loading overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                
                Text("Processing...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if llmService.progress > 0 {
                    ProgressView(value: llmService.progress)
                        .padding()
                        .frame(width: 200)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .shadow(radius: 10)
            )
        }
    }
    
    /// Entity types
    private var entityTypes: [String] {
        Array(Set(entities.map { $0.type.rawValue })).sorted()
    }
    
    // MARK: - Methods
    
    /// Summarizes the document
    private func summarizeDocument() {
        guard let url = selectedPDFURL else { return }
        
        llmService.summarizeDocument(at: url, length: selectedLength) { result in
            switch result {
            case .success(let summary):
                self.summary = summary
                self.selectedTab = 1
            case .failure(let error):
                print("Error summarizing document: \(error.localizedDescription)")
            }
        }
    }
    
    /// Extracts entities
    private func extractEntities() {
        guard let url = selectedPDFURL else { return }
        
        llmService.extractEntities(from: url) { result in
            switch result {
            case .success(let entities):
                self.entities = entities
                self.selectedTab = 2
            case .failure(let error):
                print("Error extracting entities: \(error.localizedDescription)")
            }
        }
    }
    
    /// Formats a date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Gets a color for an entity type
    private func entityTypeColor(_ type: String) -> Color {
        switch type {
        case "person":
            return .blue
        case "organization":
            return .green
        case "location":
            return .orange
        case "date":
            return .purple
        case "money":
            return .green
        case "product":
            return .red
        case "event":
            return .pink
        case "workOfArt":
            return .indigo
        default:
            return .gray
        }
    }
}

/// PDFKit view
struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
    }
}

/// Document picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onPick(url)
        }
    }
}

/// Entity row view
struct EntityRowView: View {
    let entity: ExtractedEntity
    
    var body: some View {
        HStack {
            Circle()
                .fill(entityTypeColor(entity.type.rawValue))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading) {
                Text(entity.name)
                    .font(.headline)
                
                Text(entity.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if let context = entity.context, !context.isEmpty {
                Text("...")
                    .foregroundColor(.gray)
            }
            
            Text(String(format: "%.0f%%", entity.confidence * 100))
                .font(.caption)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.systemGray5))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
    }
    
    /// Gets a color for an entity type
    private func entityTypeColor(_ type: String) -> Color {
        switch type {
        case "person":
            return .blue
        case "organization":
            return .green
        case "location":
            return .orange
        case "date":
            return .purple
        case "money":
            return .green
        case "product":
            return .red
        case "event":
            return .pink
        case "workOfArt":
            return .indigo
        default:
            return .gray
        }
    }
}

/// Entity detail view
struct EntityDetailView: View {
    let entity: ExtractedEntity
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Entity name
                Text(entity.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Entity type
                HStack {
                    Circle()
                        .fill(entityTypeColor(entity.type.rawValue))
                        .frame(width: 12, height: 12)
                    
                    Text(entity.type.rawValue.capitalized)
                        .font(.headline)
                }
                
                // Confidence
                VStack(alignment: .leading) {
                    Text("Confidence")
                        .font(.headline)
                    
                    HStack {
                        Text(String(format: "%.0f%%", entity.confidence * 100))
                            .font(.callout)
                        
                        Spacer()
                        
                        // Confidence meter
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(width: geometry.size.width, height: 8)
                                    .opacity(0.3)
                                    .foregroundColor(Color(.systemGray4))
                                
                                Rectangle()
                                    .frame(width: min(CGFloat(entity.confidence) * geometry.size.width, geometry.size.width), height: 8)
                                    .foregroundColor(confidenceColor(entity.confidence))
                            }
                            .cornerRadius(4)
                        }
                        .frame(height: 8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Context
                if let context = entity.context, !context.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Context")
                            .font(.headline)
                        
                        Text(context)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("Entity Details", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    /// Gets a color for an entity type
    private func entityTypeColor(_ type: String) -> Color {
        switch type {
        case "person":
            return .blue
        case "organization":
            return .green
        case "location":
            return .orange
        case "date":
            return .purple
        case "money":
            return .green
        case "product":
            return .red
        case "event":
            return .pink
        case "workOfArt":
            return .indigo
        default:
            return .gray
        }
    }
    
    /// Gets a color for a confidence value
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

/// Preview provider
struct DocumentAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentAnalysisView()
    }
}
