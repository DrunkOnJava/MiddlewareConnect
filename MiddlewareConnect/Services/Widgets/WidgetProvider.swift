import SwiftUI
import WidgetKit

/// Provider for the app's widgets
struct WidgetProvider: TimelineProvider {
    // MARK: - TimelineProvider
    
    /// Provides a placeholder widget
    /// - Parameter context: The context
    /// - Returns: A placeholder entry
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), widgetType: .recentDocuments, recentDocuments: [])
    }
    
    /// Gets a snapshot of the widget
    /// - Parameters:
    ///   - context: The context
    ///   - completion: The completion handler
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let entry = WidgetEntry(
            date: Date(),
            widgetType: .recentDocuments,
            recentDocuments: getSampleRecentDocuments()
        )
        completion(entry)
    }
    
    /// Gets a timeline of widget entries
    /// - Parameters:
    ///   - context: The context
    ///   - completion: The completion handler
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        // Get the widget type from the configuration
        let widgetType: WidgetType = context.family == .systemLarge ? .tokenUsage : .recentDocuments
        
        // Create the entry
        var entry: WidgetEntry
        
        switch widgetType {
        case .recentDocuments:
            entry = WidgetEntry(
                date: Date(),
                widgetType: .recentDocuments,
                recentDocuments: getRecentDocuments()
            )
        case .tokenUsage:
            entry = WidgetEntry(
                date: Date(),
                widgetType: .tokenUsage,
                tokenUsage: getTokenUsage()
            )
        case .quickActions:
            entry = WidgetEntry(
                date: Date(),
                widgetType: .quickActions,
                quickActions: getQuickActions()
            )
        }
        
        // Create the timeline
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        
        // Return the timeline
        completion(timeline)
    }
    
    // MARK: - Private Methods
    
    /// Gets recent documents
    /// - Returns: The recent documents
    private func getRecentDocuments() -> [RecentDocument] {
        // Get the recent documents from UserDefaults
        let recentDocumentStrings = UserDefaults(suiteName: "group.com.yourcompany.llmbuddy")?
            .array(forKey: "RecentDocuments") as? [String] ?? []
        
        // Convert to RecentDocument objects
        let recentDocuments = recentDocumentStrings.prefix(5).compactMap { urlString -> RecentDocument? in
            guard let url = URL(string: urlString) else { return nil }
            
            return RecentDocument(
                name: url.lastPathComponent,
                url: url,
                date: Date() // In a real app, you would store the date with the document
            )
        }
        
        return recentDocuments
    }
    
    /// Gets sample recent documents for the snapshot
    /// - Returns: Sample recent documents
    private func getSampleRecentDocuments() -> [RecentDocument] {
        return [
            RecentDocument(
                name: "Document 1.pdf",
                url: URL(string: "file:///document1.pdf")!,
                date: Date()
            ),
            RecentDocument(
                name: "Document 2.pdf",
                url: URL(string: "file:///document2.pdf")!,
                date: Date().addingTimeInterval(-3600)
            ),
            RecentDocument(
                name: "Document 3.pdf",
                url: URL(string: "file:///document3.pdf")!,
                date: Date().addingTimeInterval(-7200)
            )
        ]
    }
    
    /// Gets token usage
    /// - Returns: The token usage
    private func getTokenUsage() -> TokenUsage {
        // Get the token usage from UserDefaults
        let userDefaults = UserDefaults(suiteName: "group.com.yourcompany.llmbuddy")
        
        let totalTokens = userDefaults?.integer(forKey: "TotalTokens") ?? 0
        let totalCost = userDefaults?.double(forKey: "TotalCost") ?? 0.0
        let lastUpdated = userDefaults?.object(forKey: "LastTokenUpdate") as? Date ?? Date()
        
        return TokenUsage(
            totalTokens: totalTokens,
            totalCost: totalCost,
            lastUpdated: lastUpdated
        )
    }
    
    /// Gets quick actions
    /// - Returns: The quick actions
    private func getQuickActions() -> [QuickAction] {
        return [
            QuickAction(
                name: "Text Chunker",
                icon: "text.insert",
                deepLink: URL(string: "llmbuddy://textchunker")!
            ),
            QuickAction(
                name: "Text Cleaner",
                icon: "text.badge.checkmark",
                deepLink: URL(string: "llmbuddy://textcleaner")!
            ),
            QuickAction(
                name: "PDF Combiner",
                icon: "doc.on.doc",
                deepLink: URL(string: "llmbuddy://pdfcombiner")!
            ),
            QuickAction(
                name: "Token Calculator",
                icon: "dollarsign.circle",
                deepLink: URL(string: "llmbuddy://tokencalculator")!
            )
        ]
    }
}

// MARK: - Widget Entry

/// An entry for a widget
struct WidgetEntry: TimelineEntry {
    /// The date of the entry
    let date: Date
    
    /// The type of widget
    let widgetType: WidgetType
    
    /// The recent documents (for the recent documents widget)
    var recentDocuments: [RecentDocument] = []
    
    /// The token usage (for the token usage widget)
    var tokenUsage: TokenUsage? = nil
    
    /// The quick actions (for the quick actions widget)
    var quickActions: [QuickAction] = []
}

// MARK: - Widget Type

/// The type of widget
enum WidgetType {
    /// Recent documents widget
    case recentDocuments
    
    /// Token usage widget
    case tokenUsage
    
    /// Quick actions widget
    case quickActions
}

// MARK: - Models

/// A recent document
struct RecentDocument: Identifiable {
    /// The unique identifier
    var id: String { url.absoluteString }
    
    /// The name of the document
    let name: String
    
    /// The URL of the document
    let url: URL
    
    /// The date the document was last accessed
    let date: Date
}

/// Token usage information
struct TokenUsage {
    /// The total number of tokens used
    let totalTokens: Int
    
    /// The total cost of tokens used
    let totalCost: Double
    
    /// The date the token usage was last updated
    let lastUpdated: Date
    
    /// The formatted total cost
    var formattedTotalCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalCost)) ?? "$0.00"
    }
    
    /// The formatted last updated date
    var formattedLastUpdated: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: lastUpdated)
    }
}

/// A quick action
struct QuickAction: Identifiable {
    /// The unique identifier
    var id: String { name }
    
    /// The name of the action
    let name: String
    
    /// The icon for the action
    let icon: String
    
    /// The deep link URL for the action
    let deepLink: URL
}

// MARK: - Widget Views

/// The recent documents widget view
struct RecentDocumentsWidgetView: View {
    /// The entry for the widget
    var entry: WidgetProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                
                Text("Recent Documents")
                    .font(.headline)
                
                Spacer()
            }
            .padding(.bottom, 4)
            
            if entry.recentDocuments.isEmpty {
                Text("No recent documents")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(entry.recentDocuments.prefix(3)) { document in
                    Link(destination: document.url) {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(document.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                
                                Text(document.date, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if document.id != entry.recentDocuments.prefix(3).last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "llmbuddy://documents"))
    }
}

/// The token usage widget view
struct TokenUsageWidgetView: View {
    /// The entry for the widget
    var entry: WidgetProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                
                Text("Token Usage")
                    .font(.headline)
                
                Spacer()
            }
            
            if let tokenUsage = entry.tokenUsage {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Tokens")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(tokenUsage.totalTokens)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Cost")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(tokenUsage.formattedTotalCost)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    
                    // Token usage chart (simplified for the widget)
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(0..<7) { i in
                            let height = Double.random(in: 0.2...1.0)
                            
                            Rectangle()
                                .fill(Color.blue.opacity(0.7))
                                .frame(height: CGFloat(height * 100))
                                .frame(maxWidth: .infinity)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 100)
                    
                    Text("Last updated: \(tokenUsage.formattedLastUpdated)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No token usage data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .widgetURL(URL(string: "llmbuddy://tokencalculator"))
    }
}

/// The quick actions widget view
struct QuickActionsWidgetView: View {
    /// The entry for the widget
    var entry: WidgetProvider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.blue)
                
                Text("Quick Actions")
                    .font(.headline)
                
                Spacer()
            }
            .padding(.bottom, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(entry.quickActions) { action in
                    Link(destination: action.deepLink) {
                        VStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 44)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            
                            Text(action.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "llmbuddy://"))
    }
}

// MARK: - Widget Configuration

/// The widget configuration
struct LLMBuddyWidget: Widget {
    /// The kind of widget
    let kind: String = "LLMBuddyWidget"
    
    /// The configuration of the widget
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            switch entry.widgetType {
            case .recentDocuments:
                RecentDocumentsWidgetView(entry: entry)
            case .tokenUsage:
                TokenUsageWidgetView(entry: entry)
            case .quickActions:
                QuickActionsWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("LLM Buddy")
        .description("Access recent documents and quick actions.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle

/// The widget bundle
@main
struct LLMBuddyWidgetBundle: WidgetBundle {
    /// The widgets in the bundle
    var body: some Widget {
        LLMBuddyWidget()
    }
}
