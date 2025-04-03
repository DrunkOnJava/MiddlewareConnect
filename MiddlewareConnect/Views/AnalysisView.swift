/**
 * @fileoverview Analysis View
 * @module AnalysisView
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - SwiftUI
 * - Combine
 * 
 * Exports:
 * - AnalysisView
 * 
 * Notes:
 * - Provides analytics and usage insights
 * - Visualizes token usage and cost metrics
 * - Helps optimize LLM costs and efficiency
 */

import SwiftUI
import Combine

/// Analysis view for metrics and usage
struct AnalysisView: View {
    // MARK: - Properties
    
    /// Selected time period
    @State private var selectedPeriod: TimePeriod = .week
    
    /// Token usage
    @State private var tokenUsage: [TokenUsageData] = []
    
    /// Is loading data
    @State private var isLoading = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time period selector
                periodSelector
                
                // Usage summary
                usageSummaryCard
                
                // Token usage chart
                tokenUsageChart
                
                // Model distribution
                modelDistributionSection
                
                // Cost analysis
                costAnalysisSection
                
                // Usage tips
                usageTipsSection
            }
            .padding()
        }
        .navigationTitle("Analysis")
        .onAppear {
            loadData()
        }
    }
    
    /// Period selector
    private var periodSelector: some View {
        Picker("Time Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedPeriod) { _ in
            loadData()
        }
    }
    
    /// Usage summary card
    private var usageSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage Summary")
                .font(.headline)
            
            HStack(spacing: 20) {
                MetricView(
                    title: "Total Tokens",
                    value: formattedTotalTokens,
                    image: "number.circle.fill",
                    color: .blue
                )
                
                MetricView(
                    title: "Estimated Cost",
                    value: formattedCost,
                    image: "dollarsign.circle.fill",
                    color: .green
                )
                
                MetricView(
                    title: "Conversations",
                    value: "\(tokenUsage.reduce(0) { $0 + $1.conversations })",
                    image: "bubble.left.and.bubble.right.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// Token usage chart
    private var tokenUsageChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Token Usage")
                .font(.headline)
            
            if isLoading {
                ProgressView()
                    .frame(height: 200)
            } else if tokenUsage.isEmpty {
                Text("No data available for the selected period")
                    .foregroundColor(.gray)
                    .frame(height: 200)
            } else {
                // Placeholder for the chart
                // In a real app, this would be a chart component
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(tokenUsage) { usage in
                        HStack {
                            Text(usage.date)
                                .font(.caption)
                                .frame(width: 80, alignment: .leading)
                            
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(maxWidth: .infinity, height: 20)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: barWidth(for: usage), height: 20)
                            }
                            .cornerRadius(4)
                            
                            Text("\(usage.tokens)")
                                .font(.caption)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// Model distribution section
    private var modelDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Model Distribution")
                .font(.headline)
            
            HStack(spacing: 20) {
                PieSegmentView(
                    name: "Claude Sonnet",
                    value: 65,
                    color: .blue
                )
                
                PieSegmentView(
                    name: "Claude Haiku",
                    value: 25,
                    color: .purple
                )
                
                PieSegmentView(
                    name: "Claude Opus",
                    value: 10,
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// Cost analysis section
    private var costAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost Analysis")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Input Tokens")
                    Spacer()
                    Text("\(inputTokens) tokens")
                    Text("$\(String(format: "%.3f", inputCost))")
                        .frame(width: 70, alignment: .trailing)
                }
                
                HStack {
                    Text("Output Tokens")
                    Spacer()
                    Text("\(outputTokens) tokens")
                    Text("$\(String(format: "%.3f", outputCost))")
                        .frame(width: 70, alignment: .trailing)
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text("\(totalTokens) tokens")
                        .fontWeight(.bold)
                    Text("$\(String(format: "%.3f", inputCost + outputCost))")
                        .fontWeight(.bold)
                        .frame(width: 70, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    /// Usage tips section
    private var usageTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost Optimization Tips")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                TipView(
                    title: "Use shorter prompts",
                    description: "Be concise in your instructions to reduce input token usage",
                    icon: "text.badge.minus"
                )
                
                TipView(
                    title: "Try Claude Haiku for simpler tasks",
                    description: "Smaller models are cheaper and work well for basic queries",
                    icon: "arrow.down.right.circle"
                )
                
                TipView(
                    title: "Manage context efficiently",
                    description: "Regularly clear context for long-running conversations",
                    icon: "arrow.triangle.2.circlepath"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    /// Formatted total tokens
    private var formattedTotalTokens: String {
        let total = tokenUsage.reduce(0) { $0 + $1.tokens }
        if total > 1_000_000 {
            return String(format: "%.1fM", Double(total) / 1_000_000)
        } else if total > 1_000 {
            return String(format: "%.1fK", Double(total) / 1_000)
        } else {
            return "\(total)"
        }
    }
    
    /// Formatted cost
    private var formattedCost: String {
        let cost = (Double(inputTokens) * 0.000008) + (Double(outputTokens) * 0.000024)
        return "$\(String(format: "%.2f", cost))"
    }
    
    /// Total tokens
    private var totalTokens: Int {
        return tokenUsage.reduce(0) { $0 + $1.tokens }
    }
    
    /// Input tokens (approximate)
    private var inputTokens: Int {
        return Int(Double(totalTokens) * 0.4)
    }
    
    /// Output tokens (approximate)
    private var outputTokens: Int {
        return Int(Double(totalTokens) * 0.6)
    }
    
    /// Input cost
    private var inputCost: Double {
        return Double(inputTokens) * 0.000008
    }
    
    /// Output cost
    private var outputCost: Double {
        return Double(outputTokens) * 0.000024
    }
    
    /// Bar width for token usage
    private func barWidth(for usage: TokenUsageData) -> CGFloat {
        let maxTokens = tokenUsage.map { $0.tokens }.max() ?? 1
        let maxWidth: CGFloat = 200
        
        return CGFloat(usage.tokens) / CGFloat(maxTokens) * maxWidth
    }
    
    // MARK: - Methods
    
    /// Loads data
    private func loadData() {
        isLoading = true
        
        // Simulate loading data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.tokenUsage = Self.generateSampleData(for: self.selectedPeriod)
            self.isLoading = false
        }
    }
    
    /// Generates sample data
    static func generateSampleData(for period: TimePeriod) -> [TokenUsageData] {
        let calendar = Calendar.current
        let today = Date()
        let dateFormatter = DateFormatter()
        
        switch period {
        case .week:
            dateFormatter.dateFormat = "EEE"
            return (0..<7).map { i in
                let date = calendar.date(byAdding: .day, value: -i, to: today)!
                let tokens = Int.random(in: 5000...20000)
                return TokenUsageData(
                    id: UUID(),
                    date: dateFormatter.string(from: date),
                    tokens: tokens,
                    conversations: Int.random(in: 1...5)
                )
            }.reversed()
            
        case .month:
            dateFormatter.dateFormat = "MMM d"
            return (0..<30).filter { $0 % 3 == 0 }.map { i in
                let date = calendar.date(byAdding: .day, value: -i, to: today)!
                let tokens = Int.random(in: 15000...50000)
                return TokenUsageData(
                    id: UUID(),
                    date: dateFormatter.string(from: date),
                    tokens: tokens,
                    conversations: Int.random(in: 3...15)
                )
            }.reversed()
            
        case .year:
            dateFormatter.dateFormat = "MMM"
            return (0..<12).map { i in
                let date = calendar.date(byAdding: .month, value: -i, to: today)!
                let tokens = Int.random(in: 50000...200000)
                return TokenUsageData(
                    id: UUID(),
                    date: dateFormatter.string(from: date),
                    tokens: tokens,
                    conversations: Int.random(in: 10...50)
                )
            }.reversed()
        }
    }
}

/// Time period enum
enum TimePeriod: String, CaseIterable, Identifiable {
    case week = "week"
    case month = "month"
    case year = "year"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .week:
            return "Week"
        case .month:
            return "Month"
        case .year:
            return "Year"
        }
    }
}

/// Token usage data
struct TokenUsageData: Identifiable {
    let id: UUID
    let date: String
    let tokens: Int
    let conversations: Int
}

/// Metric view
struct MetricView: View {
    let title: String
    let value: String
    let image: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: image)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Pie segment view
struct PieSegmentView: View {
    let name: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: CGFloat(value) / 100.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Text("\(value)%")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            
            Text(name)
                .font(.caption)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Tip view
struct TipView: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AnalysisView()
        }
    }
}
