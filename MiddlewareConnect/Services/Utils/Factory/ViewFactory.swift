import SwiftUI
import Foundation

/// ViewFactory is a centralized place to get views for the application.
/// This helps avoid view redeclaration conflicts and provides a consistent API for
/// creating views throughout the app.
///
/// Usage:
/// ```
/// let factory = ViewFactory.shared
/// let view = factory.getTextChunkerView()
/// ```

// View factory that centralizes access to views
public struct ViewFactory {
    // Singleton instance
    public static let shared = ViewFactory()
    
    // Prevent external instantiation
    private init() {}
    
    // Text Processing Views
    public func getTextChunkerView() -> some View {
        TextChunkerView()
    }
    
    public func getTextCleanerView() -> some View {
        PlaceholderView(title: "Text Cleaner")
    }
    
    public func getMarkdownConverterView() -> some View {
        PlaceholderView(title: "Markdown Converter")
    }
    
    // Document Tools
    public func getDocumentSummarizerView() -> some View {
        PlaceholderView(title: "Document Summarizer")
    }
    
    public func getPdfCombinerView() -> some View {
        PdfCombinerView()
    }
    
    public func getPdfSplitterView() -> some View {
        PdfSplitterView()
    }
    
    // Data Formatting
    public func getCsvFormatterView() -> some View {
        PlaceholderView(title: "CSV Formatter")
    }
    
    public func getImageSplitterView() -> some View {
        PlaceholderView(title: "Image Splitter")
    }
    
    // LLM Analysis
    public func getTokenCostCalculatorView() -> some View {
        PlaceholderView(title: "Token Cost Calculator")
    }
    
    public func getContextWindowVisualizerView() -> some View {
        PlaceholderView(title: "Context Window Visualizer")
    }
    
    // Settings
    public func getCachingSettingsView() -> some View {
        CachingSettingsView()
    }
    
    public func getModelSettingsView() -> some View {
        ModelSettingsView()
    }
    
    public func getThemeSettingsView() -> some View {
        ThemeSettingsView()
    }
    
    public func getApiSettingsView() -> some View {
        PlaceholderView(title: "API Settings")
    }
    
    // Tab Views
    public func getToolsTabView() -> some View {
        EnhancedToolsTabView()
    }
}

// Placeholder view for any view that's not fully implemented
struct PlaceholderView: View {
    let title: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.title)
                .padding()
            
            Text("This feature is coming soon")
                .foregroundColor(.secondary)
            
            Spacer()
                .frame(height: 40)
            
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .opacity(0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}