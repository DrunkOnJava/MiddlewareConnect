/**
 * @fileoverview Legacy entry point for PDF Combiner
 * @module DocumentTools
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - SwiftUI
 * - PDFKit
 * - UniformTypeIdentifiers
 * - Combine
 * 
 * Notes:
 * - This is a direct implementation of PdfCombinerView to avoid module import issues
 */

import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import Combine

// Import local components directly - fix for "Cannot find in scope" errors
import class MiddlewareConnect.PDFService

// Fix missing types by importing from the right location
@_exported import struct MiddlewareConnect.PDFCombinerViewState

// Local component definitions to fix missing types
typealias DocumentPicker = MiddlewareConnect.DocumentPicker
typealias PDFPreviewView = MiddlewareConnect.PDFPreviewView

// Extension to add the getPDFInfo method that is missing
extension PDFService {
    /// Get PDF info including page count and file size
    /// - Parameter url: URL of the PDF
    /// - Returns: Tuple of page count and formatted file size
    /// - Throws: Error if file cannot be accessed
    func getPDFInfo(url: URL) throws -> (pageCount: Int, fileSizeFormatted: String) {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(domain: "PDFService", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found: \(url.path)"])
        }
        
        // Get PDF document
        guard let pdf = PDFDocument(url: url) else {
            throw NSError(domain: "PDFService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not open PDF: \(url.path)"])
        }
        
        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        let fileSizeFormatted = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        
        return (pageCount: pdf.pageCount, fileSizeFormatted: fileSizeFormatted)
    }
}

// Direct implementation to avoid module import issues
struct PdfCombinerView: View {
    // MARK: - Properties
    
    // UI state - internal to this view
    @State private var selectedPDFs: [PDFDocument] = []
    @State private var isShowingDocumentPicker = false
    @State private var isShowingPreview = false
    @State private var showMemoryWarning = false
    @State private var memoryUsage: String = ""
    @State private var memoryTimer: Timer? = nil
    
    // PDF service instance with dependency injection
    private let pdfService = PDFService()
    
    // ViewModel for PDF operations using View State Container Pattern
    @StateObject private var viewState = PDFCombinerViewState()
    
    // MARK: - Computed Properties
    
    /// Computed property for accessing URLs from the state container
    private var selectedPDFURLs: [URL] { 
        return viewState.selectedPDFURLs 
    }
    
    /// Computed property for accessing combined PDF URL from the state container
    private var combinedPDFURL: URL? { 
        return viewState.combinedPDFURL 
    }
    
    /// Computed property for accessing processing state from the state container
    private var isProcessing: Bool { 
        return viewState.isProcessing 
    }
    
    /// Computed property for accessing error message from the state container
    private var errorMessage: String? { 
        return viewState.errorMessage 
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Banner at the top
                headerBannerView
                
                // Memory usage indicator
                memoryUsageView
                
                // Main content
                VStack(alignment: .leading, spacing: 24) {
                    // Add PDFs Card
                    addPDFsCardView
                    
                    // Selected PDFs Section
                    if !selectedPDFs.isEmpty {
                        selectedPDFsCardView
                    }
                    
                    if selectedPDFs.isEmpty {
                        emptyStateView
                    }
                    
                    if let errorMessage = errorMessage {
                        errorView(message: errorMessage)
                    }
                    
                    // Result Section
                    if let combinedPDFURL = combinedPDFURL {
                        resultCardView(url: combinedPDFURL)
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
    
    // MARK: - View Components
    
    /// Banner at the top of the view
    private var headerBannerView: some View {
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
    }
    
    /// Memory usage indicator view
    private var memoryUsageView: some View {
        HStack {
            Spacer()
            Text(memoryUsage)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.trailing)
                .padding(.top, 8)
        }
    }
    
    /// Card for adding PDFs
    private var addPDFsCardView: some View {
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
    }
    
    /// Card for selected PDFs
    private var selectedPDFsCardView: some View {
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
                    viewState.clearSelectedPDFs()
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
                if viewState.mightCauseMemoryIssues() {
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
    
    /// Empty state view
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
    
    /// Error view
    private func errorView(message: String) -> some View {
        Text(message)
            .foregroundColor(.red)
            .font(.caption)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
    }
    
    /// Result card view
    private func resultCardView(url: URL) -> some View {
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
                        Text(url.lastPathComponent)
                            .font(DesignSystem.Typography.headline)
                            .lineLimit(1)
                        
                        if let pdfInfo = try? pdfService.getPDFInfo(url: url) {
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
                        sharePDF(url: url)
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
    
    /// List view of selected PDFs
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
    
    // MARK: - Methods
    
    /// Load selected PDFs from URLs
    private func loadSelectedPDFs(urls: [URL]) {
        // Use memory optimization for loading PDFs
        MemoryManager.shared.optimizeForLargeFileOperation {
            for url in urls {
                // Add to state container using explicit state transition method
                if viewState.addPDFURL(url) {
                    // Only load the PDF document if it was added successfully
                    if let pdf = PDFDocument(url: url) {
                        selectedPDFs.append(pdf)
                    }
                }
                
                // Release memory after each PDF is loaded
                autoreleasepool { }
            }
        }
    }
    
    /// Remove a selected PDF by index
    private func removeSelectedPDF(at index: Int) {
        guard index < selectedPDFs.count else { return }
        selectedPDFs.remove(at: index)
        
        // Use explicit state transition method from view state container
        viewState.removePDFURL(at: index)
    }
    
    /// Factory method for PDF combining action
    private func pdfCombineAction() -> () -> Void {
        // Explicitly capture required dependencies
        return { [viewState] in
            // Delegate to view state container
            viewState.combineSelectedPDFs()
        }
    }
    
    /// Combine selected PDFs
    private func combineSelectedPDFs() {
        guard selectedPDFs.count >= 2 else { return }
        
        // Start monitoring memory during the operation
        startMemoryMonitoring()
        
        // Delegate to the view state container for state transitions
        viewState.combineSelectedPDFs {
            // Call completion handler to update UI
            MemoryManager.shared.clearMemoryCaches()
        }
    }
    
    /// Start monitoring memory usage
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
    
    /// Update memory usage display
    private func updateMemoryUsage() {
        let manager = MemoryManager.shared
        memoryUsage = "Memory: \(manager.formattedMemoryUsage) (\(String(format: "%.1f", manager.memoryUsagePercentage))%)"
    }
    
    /// Clean up when view disappears
    func cleanup() {
        // Stop memory monitoring
        memoryTimer?.invalidate()
        memoryTimer = nil
        
        // Clear memory
        MemoryManager.shared.clearMemoryCaches()
    }
    
    /// Share a PDF file
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

// MARK: - Preview

struct PdfCombinerView_Previews: PreviewProvider {
    static var previews: some View {
        PdfCombinerView()
    }
}
