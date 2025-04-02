import SwiftUI

/// Analysis tab view
public struct AnalysisTabView: View {
    @EnvironmentObject var appState: AppState
    
    public var body: some View {
        List {
            Section(header: Text("Token Analysis").font(.headline)) {
                NavigationLink(destination: PlaceholderView(title: "Token Cost Calculator")) {
                    AnalysisToolRow(
                        title: "Token Cost Calculator",
                        description: "Calculate costs for different LLM models based on prompt length",
                        systemImage: "dollarsign.circle",
                        color: .green
                    )
                }
                
                NavigationLink(destination: PlaceholderView(title: "Context Window Visualizer")) {
                    AnalysisToolRow(
                        title: "Context Window Visualizer",
                        description: "Visualize context window usage across different models",
                        systemImage: "arrow.up.left.and.arrow.down.right",
                        color: .blue
                    )
                }
            }
            
            Section(header: Text("Performance Analysis").font(.headline)) {
                NavigationLink(destination: PlaceholderView(title: "Response Time Analyzer")) {
                    AnalysisToolRow(
                        title: "Response Time Analyzer",
                        description: "Analyze and compare response times for different models",
                        systemImage: "clock",
                        color: .orange
                    )
                }
                
                NavigationLink(destination: PlaceholderView(title: "Quality Evaluator")) {
                    AnalysisToolRow(
                        title: "Quality Evaluator",
                        description: "Compare output quality across LLM models for the same prompt",
                        systemImage: "star.leadinghalf.filled",
                        color: .purple
                    )
                }
            }
            
            Section(header: Text("Prompt Engineering").font(.headline)) {
                NavigationLink(destination: PlaceholderView(title: "Prompt Optimizer")) {
                    AnalysisToolRow(
                        title: "Prompt Optimizer",
                        description: "Get suggestions to improve your prompts for better results",
                        systemImage: "wand.and.stars",
                        color: .indigo
                    )
                }
                
                NavigationLink(destination: PlaceholderView(title: "Prompt Library")) {
                    AnalysisToolRow(
                        title: "Prompt Library",
                        description: "Browse and use optimized prompts for common tasks",
                        systemImage: "list.bullet.rectangle",
                        color: .teal
                    )
                }
            }
            
            Section(header: Text("Usage Analytics").font(.headline)) {
                NavigationLink(destination: PlaceholderView(title: "API Usage Stats")) {
                    AnalysisToolRow(
                        title: "API Usage Stats",
                        description: "Track your API usage and costs over time",
                        systemImage: "chart.bar",
                        color: .red
                    )
                }
                
                NavigationLink(destination: PlaceholderView(title: "Feature Usage")) {
                    AnalysisToolRow(
                        title: "Feature Usage",
                        description: "See which app features you use most frequently",
                        systemImage: "chart.pie",
                        color: .cyan
                    )
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Analysis")
    }
}

/// Analysis tool row view
struct AnalysisToolRow: View {
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: systemImage)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            // Title and description
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
