import SwiftUI

public struct ToolsTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedCategory: ToolCategory = .all
    @State private var showingToolDetail: Bool = false
    @State private var selectedTool: ToolModel?
    
    // Tool categories
    enum ToolCategory: String, CaseIterable, Identifiable {
        case all = "All Tools"
        case document = "Document Tools"
        case text = "Text Processing"
        case data = "Data Formatting"
        case analysis = "Analysis Tools"
        case utilities = "Utilities"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .document: return "doc.fill"
            case .text: return "text.badge.plus"
            case .data: return "tablecells"
            case .analysis: return "chart.bar.fill"
            case .utilities: return "wrench.and.screwdriver.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .gray
            case .document: return .red
            case .text: return .blue
            case .data: return .purple
            case .analysis: return .orange
            case .utilities: return .green
            }
        }
    }
    
    // All available tools
    private let allTools: [ToolModel] = [
        // Document Tools
        ToolModel(
            id: UUID(),
            name: "PDF Combiner",
            description: "Merge multiple PDF files into a single document",
            icon: "doc.on.doc",
            category: .document,
            destination: .pdfCombiner,
            isPremium: false
        ),
        ToolModel(
            id: UUID(),
            name: "PDF Splitter",
            description: "Split large PDF files into smaller documents by pages",
            icon: "doc.on.doc.fill",
            category: .document,
            destination: .pdfSplitter,
            isPremium: false
        ),
        ToolModel(
            id: UUID(),
            name: "Document Summarizer",
            description: "Generate concise summaries of documents using LLMs",
            icon: "doc.text.magnifyingglass",
            category: .document,
            destination: .documentSummarizer,
            isPremium: true
        ),
        
        // Text Processing Tools
        ToolModel(
            id: UUID(),
            name: "Text Chunker",
            description: "Split text into manageable chunks for LLM processing",
            icon: "text.insert",
            category: .text,
            destination: .textChunker,
            isPremium: false
        ),
        ToolModel(
            id: UUID(),
            name: "Text Cleaner",
            description: "Remove formatting, fix spacing, and normalize text",
            icon: "sparkles.rectangle.stack",
            category: .text,
            destination: .textCleaner,
            isPremium: false
        ),
        ToolModel(
            id: UUID(),
            name: "Markdown Converter",
            description: "Convert between Markdown and other text formats",
            icon: "arrow.triangle.2.circlepath",
            category: .text,
            destination: .markdownConverter,
            isPremium: false
        ),
        ToolModel(
            id: UUID(),
            name: "Prompt Templates",
            description: "Create and manage reusable prompt templates",
            icon: "square.text.square",
            category: .text,
            destination: .promptTemplates,
            isPremium: true
        ),
        
        // Data Formatting Tools
        ToolModel(
            id: UUID(),
            name: "CSV Formatter",
            description: "Clean, format, and transform CSV data",
            icon: "tablecells",
            category: .data,
            destination: .csvFormatter,
            isPremium: false
        ),
        ToolModel(
            id: UUID(),
            name: "JSON Formatter",
            description: "Format, validate, and transform JSON data",
            icon: "curlybraces.square",
            category: .data,
            destination: .jsonFormatter,
            isPremium: false
        ),
        
        // Analysis Tools
        ToolModel(
            id: UUID(),
            name: "Token Calculator",
            description: "Calculate token usage and API costs",
            icon: "dollarsign.circle",
            category: .analysis,
            destination: .tokenCalculator,
            isPremium: false
        ),
        ToolModel(
            id: UUID(),
            name: "Context Visualizer",
            description: "Visualize token usage within context windows",
            icon: "chart.bar.doc.horizontal",
            category: .analysis,
            destination: .contextVisualizer,
            isPremium: false
        ),
        ToolModel(
            id: UUID(),
            name: "Model Comparison",
            description: "Compare performance of different LLM models",
            icon: "arrow.left.arrow.right",
            category: .analysis,
            destination: .modelComparison,
            isPremium: true
        ),
        
        // Utility Tools
        ToolModel(
            id: UUID(),
            name: "Batch Processor",
            description: "Process multiple files or requests in batch mode",
            icon: "square.stack",
            category: .utilities,
            destination: .batchProcessor,
            isPremium: true
        ),
        ToolModel(
            id: UUID(),
            name: "Import/Export",
            description: "Import and export data between various formats",
            icon: "square.and.arrow.up.on.square",
            category: .utilities,
            destination: .importExport,
            isPremium: false
        )
    ]
    
    // Filtered tools based on search and category
    private var filteredTools: [ToolModel] {
        var result = allTools
        
        // Apply category filter
        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(searchText.lowercased()) ||
                $0.description.lowercased().contains(searchText.lowercased())
            }
        }
        
        return result
    }
    
    // Group tools by category
    private var toolsByCategory: [ToolCategory: [ToolModel]] {
        Dictionary(grouping: filteredTools) { $0.category }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Search bar
                        searchBar
                        
                        if searchText.isEmpty {
                            // Category filter
                            categoryFilter
                            
                            // Featured tools section
                            featuredToolsSection
                        }
                        
                        // Tools grid or list
                        if searchText.isEmpty && selectedCategory == .all {
                            // Show tools by category
                            ForEach(ToolCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                                if let tools = toolsByCategory[category], !tools.isEmpty {
                                    toolCategorySection(category: category, tools: tools)
                                }
                            }
                        } else {
                            // Show filtered tools
                            if filteredTools.isEmpty {
                                noResultsView
                            } else {
                                filteredToolsGrid
                            }
                        }
                        
                        // Bottom padding
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Tools")
            .navigationDestination(isPresented: $showingToolDetail) {
                if let tool = selectedTool {
                    toolDestinationView(for: tool)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search tools...", text: $searchText)
                .font(.body)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ToolCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation {
                            selectedCategory = category
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.subheadline)
                            
                            Text(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(selectedCategory == category ? category.color.opacity(0.1) : Color(UIColor.secondarySystemBackground))
                        .foregroundColor(selectedCategory == category ? category.color : .primary)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedCategory == category ? category.color : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var featuredToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured Tools")
                .font(.headline)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(allTools.filter { $0.isPremium }, id: \.id) { tool in
                        featuredToolCard(tool: tool)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func featuredToolCard(tool: ToolModel) -> some View {
        Button(action: {
            selectedTool = tool
            showingToolDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(tool.category.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: tool.icon)
                        .font(.system(size: 22))
                        .foregroundColor(tool.category.color)
                    
                    if tool.isPremium {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                            .background(Circle().fill(Color.white).frame(width: 18, height: 18))
                            .offset(x: 2, y: -2)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tool.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(tool.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(width: 150)
                    
                    Text(tool.category.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tool.category.color.opacity(0.1))
                        .foregroundColor(tool.category.color)
                        .cornerRadius(4)
                }
            }
            .frame(width: 170, height: 140)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func toolCategorySection(category: ToolCategory, tools: [ToolModel]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                    
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        selectedCategory = category
                    }
                }) {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(category.color)
                }
            }
            .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(tools.prefix(4), id: \.id) { tool in
                    toolCard(tool: tool)
                }
            }
        }
    }
    
    private var filteredToolsGrid: some View {
        VStack(alignment: .leading) {
            Text("\(filteredTools.count) tools found")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(filteredTools, id: \.id) { tool in
                    toolCard(tool: tool)
                }
            }
        }
    }
    
    private func toolCard(tool: ToolModel) -> some View {
        Button(action: {
            selectedTool = tool
            showingToolDetail = true
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(tool.category.color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: tool.icon)
                            .font(.system(size: 16))
                            .foregroundColor(tool.category.color)
                    }
                    
                    Spacer()
                    
                    if tool.isPremium {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                    }
                }
                
                Text(tool.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(tool.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(height: 32, alignment: .top)
                
                Spacer()
                
                HStack {
                    Text(tool.category.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tool.category.color.opacity(0.1))
                        .foregroundColor(tool.category.color)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 130)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No matching tools found")
                .font(.headline)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                searchText = ""
                selectedCategory = .all
            }) {
                Text("Clear Filters")
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Tool Destinations
    
    @ViewBuilder
    private func toolDestinationView(for tool: ToolModel) -> some View {
        switch tool.destination {
        case .pdfCombiner:
            PdfCombinerView()
        case .pdfSplitter:
            PdfSplitterView()
        case .documentSummarizer:
            DocumentSummarizerView()
        case .textChunker:
            TextChunkerView()
        case .textCleaner:
            TextCleanerView()
        case .markdownConverter:
            MarkdownConverterView()
                .environmentObject(appState)
        case .promptTemplates:
            PromptTemplatesView()
        case .csvFormatter:
            CsvFormatterView()
        case .jsonFormatter:
            JSONFormatterView()
        case .tokenCalculator:
            TokenCostCalculatorView()
        case .contextVisualizer:
            ContextWindowVisualizerView()
        case .modelComparison:
            ModelComparisonView()
                .environmentObject(appState)
        case .batchProcessor:
            BatchProcessorView()
                .environmentObject(appState)
        case .importExport:
            ImportExportToolView()
        }
    }
}

// MARK: - Supporting Types

/// Tool model for list items
struct ToolModel: Identifiable {
    var id: UUID
    var name: String
    var description: String
    var icon: String
    var category: ToolsTabView.ToolCategory
    var destination: ToolDestination
    var isPremium: Bool
    
    enum ToolDestination {
        case pdfCombiner
        case pdfSplitter
        case documentSummarizer
        case textChunker
        case textCleaner
        case markdownConverter
        case promptTemplates
        case csvFormatter
        case jsonFormatter
        case tokenCalculator
        case contextVisualizer
        case modelComparison
        case batchProcessor
        case importExport
    }
}

// MARK: - Placeholder Views

/// Placeholder for JSON Formatter
struct JSONFormatterView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "curlybraces.square")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("JSON Formatter")
                .font(.title)
                .fontWeight(.bold)
            
            Text("This tool is coming soon!")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("The JSON Formatter will help you validate, format, and transform JSON data.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("JSON Formatter")
    }
}

struct ToolsTabView_Previews: PreviewProvider {
    static var previews: some View {
        ToolsTabView()
            .environmentObject(AppState())
    }
}
