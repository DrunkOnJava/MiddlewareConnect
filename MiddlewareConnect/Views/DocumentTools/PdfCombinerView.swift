import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import Combine

// This is the actual PdfCombinerView implementation

struct PdfCombinerView: View {
    @State private var selectedPDFs: [PDFDocument] = []
    @State private var selectedPDFURLs: [URL] = []
    @State private var combinedPDFURL: URL? = nil
    @State private var isShowingDocumentPicker = false
    @State private var isShowingPreview = false
    @State private var isProcessing = false
    @State private var errorMessage: String? = nil
    @State private var showMemoryWarning = false
    @State private var memoryUsage: String = ""
    @State private var memoryTimer: Timer? = nil
    
    // Create instance of PDFService directly
    private let pdfService = PDFService()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Banner at the top
                VStack(alignment: .leading, spacing: 10) {
                    Label("PDF Combiner", systemImage: "doc.on.doc.fill")
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(.white)
                    
                    Text("Combine multiple PDF files into a single document")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.red, .red.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Memory usage indicator
                HStack {
                    Spacer()
                    Text(memoryUsage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.trailing)
                        .padding(.top, 8)
                }
                
                // Main content
                VStack(alignment: .leading, spacing: 24) {
                    // Add PDFs Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                            
                            Text("Add PDF Files")
                                .font(DesignSystem.Typography.headline)
                            
                            Spacer()
                            
                            if !selectedPDFs.isEmpty {
                                Text("\(selectedPDFs.count) files")
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        Button(action: {
                            isShowingDocumentPicker = true
                        }) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                Text("Select PDF Files")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(DesignSystem.PrimaryButtonStyle(fullWidth: true))
                    }
                    .padding()
                    .background(DesignSystem.Colors.background)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Selected PDFs Section
                    if !selectedPDFs.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(.red)
                                    .font(.title3)
                                
                                Text("Selected Documents")
                                    .font(DesignSystem.Typography.headline)
                                
                                Spacer()
                                
                                Button(action: {
                                    selectedPDFs.removeAll()
                                    selectedPDFURLs.removeAll()
                                    combinedPDFURL = nil
                                }) {
                                    Label("Clear", systemImage: "trash")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // PDF List with reordering hint
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Files will be combined in the order shown below")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 4)
                                
                                selectedPDFsListView
                            }
                            
                            // Combine Button
                            Button(action: {
                                // Show memory warning if needed before combining
                                if pdfService.mightCauseMemoryIssues(urls: selectedPDFURLs) {
                                    showMemoryWarning = true
                                } else {
                                    combineSelectedPDFs()
                                }
                            }) {
                                if isProcessing {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        Text("Processing...")
                                    }
                                    .frame(maxWidth: .infinity)
                                } else {
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                        Text("Combine PDFs")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(DesignSystem.PrimaryButtonStyle(fullWidth: true))
                            .disabled(selectedPDFs.count < 2 || isProcessing)
                            .alert(isPresented: $showMemoryWarning) {
                                Alert(
                                    title: Text("Large PDF Operation"),
                                    message: Text("Combining these \(selectedPDFs.count) PDFs may require significant memory. Consider closing other apps for better performance."),
                                    primaryButton: .default(Text("Proceed")) {
                                        // Clear memory before proceeding
                                        MemoryManager.shared.clearMemoryCaches()
                                        combineSelectedPDFs()
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                        .padding()
                        .background(DesignSystem.Colors.background)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    
                    if selectedPDFs.isEmpty {
                        emptyStateView
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Result Section
                    if let combinedPDFURL = combinedPDFURL {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                
                                Text("PDF Successfully Combined")
                                    .font(DesignSystem.Typography.headline)
                            }
                            
                            // PDF Preview Card
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    // PDF Icon
                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.red)
                                        .frame(width: 50, height: 50)
                                        .padding(8)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    // File details
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(combinedPDFURL.lastPathComponent)
                                            .font(DesignSystem.Typography.headline)
                                            .lineLimit(1)
                                        
                                        if let pdfInfo = try? pdfService.getPDFInfo(url: combinedPDFURL) {
                                            HStack {
                                                Label("\(pdfInfo.pageCount) pages", systemImage: "doc.text")
                                                    .font(.caption)
                                                
                                                Divider()
                                                    .frame(height: 12)
                                                
                                                Label(pdfInfo.fileSizeFormatted, systemImage: "arrow.down.doc")
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                
                                Divider()
                                
                                // Action buttons
                                HStack {
                                    Button(action: {
                                        isShowingPreview = true
                                    }) {
                                        Label("Preview", systemImage: "eye")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(DesignSystem.SecondaryButtonStyle(fullWidth: true))
                                    
                                    Button(action: {
                                        sharePDF(url: combinedPDFURL)
                                    }) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(DesignSystem.PrimaryButtonStyle(fullWidth: true))
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .padding()
                        .background(DesignSystem.Colors.background)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPicker(
                contentTypes: [UTType.pdf],
                onPick: { urls in
                    loadSelectedPDFs(urls: urls)
                }
            )
        }
        .sheet(isPresented: $isShowingPreview) {
            if let combinedPDFURL = combinedPDFURL {
                PDFPreviewView(url: combinedPDFURL)
            }
        }
        .navigationTitle("PDF Combiner")
        .onAppear {
            startMemoryMonitoring()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 90, height: 90)
                
                VStack(spacing: 8) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Circle().fill(Color.red))
                        .offset(x: 20, y: -20)
                }
            }
            .padding(.top, 20)
            
            Text("No PDF Files Selected")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.text)
            
            Text("Start by adding PDF files that you want to combine into a single document")
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Select multiple PDF files", systemImage: "1.circle.fill")
                    .font(DesignSystem.Typography.headline)
                
                Label("They'll appear in your selected list", systemImage: "2.circle.fill")
                    .font(DesignSystem.Typography.headline)
                
                Label("Click 'Combine PDFs' to merge them", systemImage: "3.circle.fill")
                    .font(DesignSystem.Typography.headline)
            }
            .padding()
            .background(DesignSystem.Colors.background.opacity(0.6))
            .cornerRadius(12)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(DesignSystem.Colors.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var selectedPDFsListView: some View {
        VStack(spacing: 10) {
            ForEach(Array(selectedPDFs.enumerated()), id: \.offset) { index, pdf in
                HStack(spacing: 12) {
                    // Document index number
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.red.opacity(0.15)))
                        .foregroundColor(.red)
                    
                    // Document icon and preview
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 36, height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        
                        Image(systemName: "doc.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                    }
                    
                    // Document details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedPDFURLs[index].lastPathComponent)
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.text)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Label("\(pdf.pageCount) page\(pdf.pageCount == 1 ? "" : "s")", systemImage: "doc.text")
                                .font(.caption)
                                .foregroundColor(DesignSystem.Colors.secondaryText)
                            
                            if let fileSize = try? FileManager.default.attributesOfItem(atPath: selectedPDFURLs[index].path)[.size] as? Int {
                                Text(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))
                                    .font(.caption)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Remove button
                    Button(action: {
                        withAnimation {
                            removeSelectedPDF(at: index)
                        }
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Circle().fill(Color.red.opacity(0.8)))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(DesignSystem.Colors.background)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    private func loadSelectedPDFs(urls: [URL]) {
        // Use memory optimization for loading PDFs
        MemoryManager.shared.optimizeForLargeFileOperation {
            for url in urls {
                // Check if the URL is already in the list
                if selectedPDFURLs.contains(url) {
                    continue
                }
                
                // Try to open the PDF
                if let pdf = PDFDocument(url: url) {
                    selectedPDFs.append(pdf)
                    selectedPDFURLs.append(url)
                }
                
                // Release memory after each PDF is loaded
                autoreleasepool { }
            }
        }
    }
    
    private func removeSelectedPDF(at index: Int) {
        guard index < selectedPDFs.count else { return }
        selectedPDFs.remove(at: index)
        selectedPDFURLs.remove(at: index)
        
        // Clear combined PDF if we've removed a file
        combinedPDFURL = nil
    }
    
    private func combineSelectedPDFs() {
        guard selectedPDFs.count >= 2 else { return }
        
        isProcessing = true
        errorMessage = nil
        
        // Start monitoring memory during the operation
        startMemoryMonitoring()
        
        // Use background thread for processing
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // The PDFService now handles memory optimization internally
                let combinedURL = try pdfService.combineDocuments(urls: selectedPDFURLs)
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    combinedPDFURL = combinedURL
                    isProcessing = false
                    
                    // Clear memory after operation completes
                    MemoryManager.shared.clearMemoryCaches()
                }
            } catch {
                // Handle error on main thread
                DispatchQueue.main.async {
                    errorMessage = "Failed to combine PDFs: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
    
    // Start monitoring memory usage
    private func startMemoryMonitoring() {
        // Stop any existing timer
        memoryTimer?.invalidate()
        
        // Update initial memory usage
        updateMemoryUsage()
        
        // Create a new timer to update memory usage every 2 seconds
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            updateMemoryUsage()
        }
    }
    
    // Update memory usage display
    private func updateMemoryUsage() {
        let manager = MemoryManager.shared
        memoryUsage = "Memory: \(manager.formattedMemoryUsage) (\(String(format: "%.1f", manager.memoryUsagePercentage))%)"
    }
    
    // Clean up when view disappears
    func cleanup() {
        // Stop memory monitoring
        memoryTimer?.invalidate()
        memoryTimer = nil
        
        // Clear memory
        MemoryManager.shared.clearMemoryCaches()
    }
    
    private func sharePDF(url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        // Present the activity view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}


// Document Picker for selecting PDFs
struct DocumentPicker: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onPick: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.allowsMultipleSelection = true
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

// PDF Preview View with memory optimization
struct PDFPreviewView: UIViewRepresentable {
    let url: URL
    
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
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Use memory optimization when loading the document
        MemoryManager.shared.optimizeForLargeFileOperation {
            if let document = PDFDocument(url: url) {
                uiView.document = document
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: PDFPreviewView
        
        init(_ parent: PDFPreviewView) {
            self.parent = parent
        }
        
        @objc func handleMemoryWarning() {
            // Clear the document if memory warning is received
            DispatchQueue.main.async {
                // This will be called when a memory warning is received
                print("Memory warning received in PDF Preview - clearing resources")
            }
        }
    }
    
    static func dismantleUIView(_ uiView: PDFView, coordinator: Coordinator) {
        // Clear the document when view is dismantled
        uiView.document = nil
        
        // Suggest garbage collection
        autoreleasepool { }
    }
}

struct PdfCombinerView_Previews: PreviewProvider {
    static var previews: some View {
        PdfCombinerView()
    }
}
