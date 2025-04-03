import SwiftUI
import LLMServiceProvider

/// A specialized view for displaying document summaries with expandable sections and highlights
///
/// Provides a comprehensive interface for viewing and interacting with document summaries,
/// key points, and highlights extracted from the original document.
public struct SummaryView: View {
    /// Core view model for summary display functionality
    @StateObject private var viewModel: ViewModel
    
    /// ViewModel handling summary data and interaction
    public class ViewModel: ObservableObject {
        /// Document summaries to display
        @Published public var summaries: [DocumentSummary] = []
        
        /// Currently selected summary index
        @Published public var selectedSummaryIndex: Int?
        
        /// Whether to show extended content
        @Published public var showFullContent: Bool = false
        
        /// Filter for key points display
        @Published public var keyPointsFilter: String = ""
        
        /// Whether to hide system-generated key points
        @Published public var hideSystemKeyPoints: Bool = false
        
        /// Current display mode for the summary view
        @Published public var displayMode: DisplayMode = .compact
        
        /// Selected highlight if any
        @Published public var selectedHighlight: Highlight?
        
        /// Formatting style for the summary content
        @Published public var formattingStyle: FormattingStyle = .default
        
        /// Initialize the view model with document summaries
        /// - Parameter summaries: Array of summaries to display
        public init(summaries: [DocumentSummary] = []) {
            self.summaries = summaries
            
            if !summaries.isEmpty {
                self.selectedSummaryIndex = 0
            }
        }
        
        /// Current summary based on selected index
        public var currentSummary: DocumentSummary? {
            guard let index = selectedSummaryIndex, index >= 0, index < summaries.count else {
                return nil
            }
            return summaries[index]
        }
        
        /// Selects a summary by index
        /// - Parameter index: Index to select
        public func selectSummary(at index: Int) {
            guard index >= 0, index < summaries.count else {
                return
            }
            selectedSummaryIndex = index
        }
        
        /// Returns filtered key points based on current filters
        /// - Returns: Array of filtered key points
        public func filteredKeyPoints() -> [String] {
            guard let summary = currentSummary else {
                return []
            }
            
            var keyPoints = summary.keyPoints
            
            // Apply system key points filter if needed
            if hideSystemKeyPoints {
                keyPoints = keyPoints.filter { !isSystemGenerated($0) }
            }
            
            // Apply text filter if present
            if !keyPointsFilter.isEmpty {
                keyPoints = keyPoints.filter { 
                    $0.lowercased().contains(keyPointsFilter.lowercased())
                }
            }
            
            return keyPoints
        }
        
        /// Returns all highlights from the current summary
        /// - Returns: Array of highlights
        public func highlights() -> [Highlight] {
            // This would extract highlights from the current summary
            // For now, we'll return a placeholder implementation
            guard let summary = currentSummary else {
                return []
            }
            
            // In a real implementation, highlights would be part of the DocumentSummary model
            // This is just for demonstration purposes
            return [
                Highlight(
                    id: UUID(),
                    text: "A key insight from the document",
                    pageNumber: 1,
                    category: .keyInsight
                ),
                Highlight(
                    id: UUID(),
                    text: "Important fact mentioned in the analysis",
                    pageNumber: 2,
                    category: .factualStatement
                ),
                Highlight(
                    id: UUID(),
                    text: "Significant conclusion drawn by the author",
                    pageNumber: 3,
                    category: .conclusion
                )
            ]
        }
        
        /// Identifies if a key point was system-generated
        /// - Parameter keyPoint: Key point text to check
        /// - Returns: Boolean indicating if system-generated
        private func isSystemGenerated(_ keyPoint: String) -> Bool {
            // In a real implementation, this would check metadata or formatting
            // For now, we'll use a simple heuristic
            return keyPoint.hasPrefix("[System] ")
        }
    }
    
    /// Display modes for the summary view
    public enum DisplayMode {
        /// Compact view showing just essential information
        case compact
        
        /// Full view with all details expanded
        case full
        
        /// Custom view with user-specified sections
        case custom(sections: Set<SectionType>)
    }
    
    /// Section types that can be displayed
    public enum SectionType: String, CaseIterable {
        /// Overall document summary
        case summary
        
        /// Key points extracted from document
        case keyPoints
        
        /// Important highlights from the document
        case highlights
        
        /// Topic modeling results
        case topics
        
        /// Visual representation of content
        case visualization
        
        /// Human-readable section name
        public var displayName: String {
            switch self {
            case .summary: return "Summary"
            case .keyPoints: return "Key Points"
            case .highlights: return "Highlights"
            case .topics: return "Topics"
            case .visualization: return "Visualization"
            }
        }
        
        /// System image name for the section
        public var iconName: String {
            switch self {
            case .summary: return "doc.text"
            case .keyPoints: return "list.bullet"
            case .highlights: return "highlighter"
            case .topics: return "tag"
            case .visualization: return "chart.bar"
            }
        }
    }
    
    /// Formatting style for summary content
    public struct FormattingStyle {
        /// Font for the main summary
        public let summaryFont: Font
        
        /// Font for key points
        public let keyPointsFont: Font
        
        /// Font for highlights
        public let highlightsFont: Font
        
        /// Theme colors for the view
        public let colors: ThemeColors
        
        /// Default formatting style
        public static let `default` = FormattingStyle(
            summaryFont: .body,
            keyPointsFont: .callout,
            highlightsFont: .callout,
            colors: ThemeColors(
                primary: .blue,
                secondary: .gray,
                accent: .orange,
                background: Color(.systemBackground)
            )
        )
    }
    
    /// Theme colors for the view
    public struct ThemeColors {
        /// Primary color for main elements
        public let primary: Color
        
        /// Secondary color for supporting elements
        public let secondary: Color
        
        /// Accent color for highlights
        public let accent: Color
        
        /// Background color for the view
        public let background: Color
    }
    
    /// Represents a highlighted section of text
    public struct Highlight: Identifiable {
        /// Unique identifier
        public let id: UUID
        
        /// Highlighted text content
        public let text: String
        
        /// Page number where highlight appears
        public let pageNumber: Int
        
        /// Category of highlight
        public let category: Category
        
        /// Possible highlight categories
        public enum Category: String, CaseIterable {
            /// Key insight from the document
            case keyInsight
            
            /// Factual statement
            case factualStatement
            
            /// Conclusion drawn in the document
            case conclusion
            
            /// Question raised in the document
            case question
            
            /// Custom highlight category
            case custom(String)
            
            /// Display name for the category
            public var displayName: String {
                switch self {
                case .keyInsight: return "Key Insight"
                case .factualStatement: return "Fact"
                case .conclusion: return "Conclusion"
                case .question: return "Question"
                case .custom(let name): return name
                }
            }
            
            /// Color representing the category
            public var color: Color {
                switch self {
                case .keyInsight: return .blue
                case .factualStatement: return .green
                case .conclusion: return .purple
                case .question: return .orange
                case .custom: return .gray
                }
            }
        }
    }
    
    /// Initializes a summary view
    /// - Parameter summaries: Array of document summaries to display
    public init(summaries: [DocumentSummary] = []) {
        self._viewModel = StateObject(wrappedValue: ViewModel(summaries: summaries))
    }
    
    /// Initializes a summary view with a pre-configured view model
    /// - Parameter viewModel: View model for the summary view
    public init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Document selector if multiple summaries
            if viewModel.summaries.count > 1 {
                documentSelector
            }
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let summary = viewModel.currentSummary {
                        // Summary section
                        if shouldShowSection(.summary) {
                            summarySection(summary)
                        }
                        
                        // Key points section
                        if shouldShowSection(.keyPoints) {
                            keyPointsSection(summary)
                        }
                        
                        // Highlights section
                        if shouldShowSection(.highlights) {
                            highlightsSection()
                        }
                        
                        // Topics section
                        if shouldShowSection(.topics) {
                            topicsSection(summary)
                        }
                        
                        // Visualization section
                        if shouldShowSection(.visualization) {
                            visualizationSection()
                        }
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            
            // View mode control
            displayModeSelector
        }
        .background(viewModel.formattingStyle.colors.background)
    }
    
    /// Document selector for multiple summaries
    private var documentSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<viewModel.summaries.count, id: \.self) { index in
                    Button(action: {
                        viewModel.selectSummary(at: index)
                    }) {
                        Text(viewModel.summaries[index].document)
                            .font(.footnote)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(index == viewModel.selectedSummaryIndex 
                                        ? viewModel.formattingStyle.colors.primary 
                                        : viewModel.formattingStyle.colors.secondary.opacity(0.2))
                            )
                            .foregroundColor(index == viewModel.selectedSummaryIndex 
                                ? .white 
                                : viewModel.formattingStyle.colors.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(viewModel.formattingStyle.colors.background)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(viewModel.formattingStyle.colors.secondary.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    /// Summary section view
    private func summarySection(_ summary: DocumentSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Summary", systemImage: "doc.text")
            
            Text(summary.summary)
                .font(viewModel.formattingStyle.summaryFont)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            
            if !viewModel.showFullContent {
                Button("Show More") {
                    viewModel.showFullContent = true
                }
                .font(.footnote)
                .foregroundColor(viewModel.formattingStyle.colors.primary)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(viewModel.formattingStyle.colors.background)
            .shadow(radius: 1))
    }
    
    /// Key points section view
    private func keyPointsSection(_ summary: DocumentSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Key Points", systemImage: "list.bullet")
            
            // Filter input
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(viewModel.formattingStyle.colors.secondary)
                
                TextField("Filter key points...", text: $viewModel.keyPointsFilter)
                    .font(.footnote)
                
                Toggle("Hide System", isOn: $viewModel.hideSystemKeyPoints)
                    .font(.caption)
                    .toggleStyle(SwitchToggleStyle(tint: viewModel.formattingStyle.colors.primary))
                    .labelsHidden()
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 6)
                .fill(viewModel.formattingStyle.colors.secondary.opacity(0.1)))
            
            // Key points list
            let keyPoints = viewModel.filteredKeyPoints()
            if keyPoints.isEmpty {
                Text("No key points match your filter")
                    .font(.caption)
                    .foregroundColor(viewModel.formattingStyle.colors.secondary)
                    .padding(.vertical, 10)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(keyPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(viewModel.formattingStyle.colors.primary)
                                .padding(.top, 7)
                            
                            Text(point)
                                .font(viewModel.formattingStyle.keyPointsFont)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(viewModel.formattingStyle.colors.background)
            .shadow(radius: 1))
    }
    
    /// Highlights section view
    private func highlightsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Highlights", systemImage: "highlighter")
            
            let highlights = viewModel.highlights()
            if highlights.isEmpty {
                Text("No highlights found")
                    .font(.caption)
                    .foregroundColor(viewModel.formattingStyle.colors.secondary)
                    .padding(.vertical, 10)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(highlights) { highlight in
                        highlightRow(highlight)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(viewModel.formattingStyle.colors.background)
            .shadow(radius: 1))
    }
    
    /// Single highlight row view
    private func highlightRow(_ highlight: Highlight) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Text(highlight.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(highlight.category.color.opacity(0.2))
                    .foregroundColor(highlight.category.color)
                    .cornerRadius(4)
                
                Spacer()
                
                Text("Page \(highlight.pageNumber)")
                    .font(.caption)
                    .foregroundColor(viewModel.formattingStyle.colors.secondary)
            }
            
            Text(""" + highlight.text + """)
                .font(viewModel.formattingStyle.highlightsFont)
                .italic()
                .padding(.vertical, 4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 6)
            .fill(highlight.category.color.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(highlight.category.color.opacity(0.2), lineWidth: 1)
            ))
        .onTapGesture {
            viewModel.selectedHighlight = highlight
        }
    }
    
    /// Topics section view
    private func topicsSection(_ summary: DocumentSummary) -> some View {
        // This would display topic modeling results
        // For now, we'll show a placeholder
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Topics", systemImage: "tag")
            
            Text("Topic modeling results would appear here")
                .font(.caption)
                .foregroundColor(viewModel.formattingStyle.colors.secondary)
                .padding(.vertical, 10)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(viewModel.formattingStyle.colors.background)
            .shadow(radius: 1))
    }
    
    /// Visualization section view
    private func visualizationSection() -> some View {
        // This would display visualizations of the document content
        // For now, we'll show a placeholder
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Visualization", systemImage: "chart.bar")
            
            Rectangle()
                .fill(viewModel.formattingStyle.colors.secondary.opacity(0.1))
                .frame(height: 150)
                .overlay(
                    Text("Content visualization would appear here")
                        .font(.caption)
                        .foregroundColor(viewModel.formattingStyle.colors.secondary)
                )
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(viewModel.formattingStyle.colors.background)
            .shadow(radius: 1))
    }
    
    /// Section header view
    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundColor(viewModel.formattingStyle.colors.primary)
            
            Spacer()
        }
    }
    
    /// Empty state when no summaries are available
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(viewModel.formattingStyle.colors.secondary)
            
            Text("No Summaries Available")
                .font(.headline)
                .foregroundColor(viewModel.formattingStyle.colors.secondary)
            
            Text("Run analysis on a document to generate summaries")
                .font(.caption)
                .foregroundColor(viewModel.formattingStyle.colors.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
    }
    
    /// View mode selector control
    private var displayModeSelector: some View {
        HStack {
            Spacer()
            
            Menu {
                Button {
                    viewModel.displayMode = .compact
                } label: {
                    Label("Compact View", systemImage: "list.bullet.below.rectangle")
                }
                
                Button {
                    viewModel.displayMode = .full
                } label: {
                    Label("Full View", systemImage: "doc.text.fill")
                }
                
                Menu("Custom View") {
                    ForEach(SectionType.allCases, id: \.rawValue) { sectionType in
                        if case .custom(let sections) = viewModel.displayMode {
                            Button {
                                var updatedSections = sections
                                if updatedSections.contains(sectionType) {
                                    updatedSections.remove(sectionType)
                                } else {
                                    updatedSections.insert(sectionType)
                                }
                                viewModel.displayMode = .custom(sections: updatedSections)
                            } label: {
                                Label(
                                    sectionType.displayName,
                                    systemImage: sections.contains(sectionType) ? "checkmark" : ""
                                )
                            }
                        } else {
                            Button {
                                viewModel.displayMode = .custom(sections: [sectionType])
                            } label: {
                                Label(sectionType.displayName, systemImage: "")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.formattingStyle.colors.primary)
            }
            .padding()
        }
        .background(viewModel.formattingStyle.colors.background)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(viewModel.formattingStyle.colors.secondary.opacity(0.2)),
            alignment: .top
        )
    }
    
    /// Determines if a section should be displayed based on current mode
    /// - Parameter section: Section type to check
    /// - Returns: Boolean indicating if section should be shown
    private func shouldShowSection(_ section: SectionType) -> Bool {
        switch viewModel.displayMode {
        case .compact:
            return section == .summary || section == .keyPoints
        case .full:
            return true
        case .custom(let sections):
            return sections.contains(section)
        }
    }
}

// MARK: - CaseIterable Conformance for SectionType
extension SummaryView.SectionType: CaseIterable {
    public static var allCases: [SummaryView.SectionType] {
        return [.summary, .keyPoints, .highlights, .topics, .visualization]
    }
}

// MARK: - Preview Support
#if DEBUG
struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // View with sample data
            SummaryView(
                viewModel: SummaryView.ViewModel(
                    summaries: [
                        DocumentSummary(
                            id: UUID(),
                            document: "Financial Report 2022.pdf",
                            summary: "This financial report outlines the company's performance for fiscal year 2022. It shows a 15% increase in revenue and a 12% increase in profit margins compared to the previous year. The report highlights successful cost-cutting measures and expansion into new markets as key drivers of growth.",
                            keyPoints: [
                                "15% year-over-year revenue increase",
                                "12% improvement in profit margins",
                                "Successful expansion into Asian markets",
                                "Cost reduction initiatives saved $3.2M",
                                "[System] Document contains 42 pages of financial data"
                            ],
                            length: .medium
                        ),
                        DocumentSummary(
                            id: UUID(),
                            document: "Strategic Plan.pdf",
                            summary: "The strategic plan outlines the company's growth strategy for the next five years, focusing on market expansion, product innovation, and operational efficiency.",
                            keyPoints: [
                                "Three-pillar approach to growth",
                                "Target of 20% market share by 2025",
                                "R&D investment to increase by 25%",
                                "[System] Document contains 5 sections"
                            ],
                            length: .brief
                        )
                    ]
                )
            )
            .previewDisplayName("With Data")
            
            // Empty state
            SummaryView()
                .previewDisplayName("Empty State")
        }
    }
}
#endif
