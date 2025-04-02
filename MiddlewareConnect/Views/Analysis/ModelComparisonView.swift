/**
 * @fileoverview Model Comparison tool for comparing LLM performance
 * @module ModelComparisonView
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - SwiftUI
 * - AppState (for LLM model information)
 * 
 * Exports:
 * - ModelComparisonView
 * 
 * @example
 * // Basic usage example
 * ModelComparisonView()
 *     .environmentObject(AppState())
 * 
 * Notes:
 * - This view allows users to compare different LLM models across various metrics
 * - Supports both performance benchmarks and custom prompt testing
 */

import SwiftUI
import Charts

/// Model Comparison View for analyzing and comparing LLM model performance
struct ModelComparisonView: View {
    // MARK: - State Variables
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Int = 0
    @State private var selectedModels: Set<LLMModel> = [.claudeSonnet, .gpt4, .mistral7B]
    @State private var promptText: String = "Explain the concept of recursion in computer science as if I'm a high school student."
    @State private var isRunningComparison: Bool = false
    @State private var comparisonResults: [ComparisonResult] = []
    @State private var showModelSelector: Bool = false
    @State private var maximumModelCount: Int = 3
    
    // Comparison metrics
    @State private var selectedMetrics: Set<ComparisonMetric> = [.responseTime, .tokenCost, .tokensPerSecond]
    @State private var benchmarkName: String = "General Knowledge"
    
    // MARK: - Computed Properties
    
    private var availableModels: [LLMModel] {
        LLMModel.allCases.filter { model in
            !selectedModels.contains(model) || selectedModels.count <= maximumModelCount
        }
    }
    
    private var hasEnoughModels: Bool {
        selectedModels.count >= 2
    }
    
    private var hasResults: Bool {
        !comparisonResults.isEmpty
    }
    
    // Sample performance data (would be replaced with real API calls)
    private var sampleModelResults: [ComparisonResult] {
        let models = Array(selectedModels)
        
        return [
            ComparisonResult(
                model: models[0],
                responseTime: 2.3,
                tokenCount: 215,
                tokenCost: 0.0064,
                accuracy: 0.92,
                tokensPerSecond: 93.5
            ),
            ComparisonResult(
                model: models[1],
                responseTime: 1.4,
                tokenCount: 180,
                tokenCost: 0.0027,
                accuracy: 0.88,
                tokensPerSecond: 128.6
            ),
            ComparisonResult(
                model: models.count > 2 ? models[2] : models[0],
                responseTime: 3.1,
                tokenCount: 245,
                tokenCost: 0.0017,
                accuracy: 0.94,
                tokensPerSecond: 79.0
            )
        ]
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                    
                    Text("Model Comparison")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(LinearGradient(
                    gradient: Gradient(colors: [.orange.opacity(0.7), .orange.opacity(0.5)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .cornerRadius(12)
                
                // Description
                Text("Compare the performance of different large language models across key metrics.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Tab Selection
                Picker("Comparison Type", selection: $selectedTab) {
                    Text("Performance Benchmarks").tag(0)
                    Text("Custom Prompt Test").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Model Selection
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Selected Models")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showModelSelector = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    // Selected models chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedModels), id: \.self) { model in
                                ModelChip(model: model) {
                                    // Only allow removal if we have more than 2 models
                                    if selectedModels.count > 2 {
                                        selectedModels.remove(model)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
                
                // Tab Content
                if selectedTab == 0 {
                    benchmarkView
                } else {
                    customPromptView
                }
                
                // Run Comparison Button
                Button(action: runComparison) {
                    if isRunningComparison {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Run Comparison")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(hasEnoughModels ? Color.orange : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(!hasEnoughModels || isRunningComparison)
                .padding(.horizontal)
                
                // Results Section
                if hasResults {
                    resultsSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Model Comparison")
        .sheet(isPresented: $showModelSelector) {
            modelSelectorSheet
        }
    }
    
    // MARK: - View Components
    
    private var benchmarkView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Benchmark Type")
                    .font(.headline)
                
                Picker("Benchmark", selection: $benchmarkName) {
                    Text("General Knowledge").tag("General Knowledge")
                    Text("Coding & Technical").tag("Coding & Technical")
                    Text("Reasoning & Logic").tag("Reasoning & Logic")
                    Text("Creative Writing").tag("Creative Writing")
                    Text("Data Analysis").tag("Data Analysis")
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Metrics to Compare")
                    .font(.headline)
                
                VStack(alignment: .leading) {
                    ForEach(ComparisonMetric.allCases, id: \.self) { metric in
                        Toggle(metric.displayName, isOn: Binding(
                            get: { selectedMetrics.contains(metric) },
                            set: { newValue in
                                if newValue {
                                    selectedMetrics.insert(metric)
                                } else {
                                    if selectedMetrics.count > 1 {
                                        selectedMetrics.remove(metric)
                                    }
                                }
                            }
                        ))
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
    
    private var customPromptView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Test Prompt")
                    .font(.headline)
                
                TextEditor(text: $promptText)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Metrics to Compare")
                    .font(.headline)
                
                VStack(alignment: .leading) {
                    ForEach(ComparisonMetric.allCases, id: \.self) { metric in
                        Toggle(metric.displayName, isOn: Binding(
                            get: { selectedMetrics.contains(metric) },
                            set: { newValue in
                                if newValue {
                                    selectedMetrics.insert(metric)
                                } else {
                                    if selectedMetrics.count > 1 {
                                        selectedMetrics.remove(metric)
                                    }
                                }
                            }
                        ))
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
    
    private var modelSelectorSheet: some View {
        NavigationView {
            List {
                Section(header: Text("Available Models")) {
                    ForEach(LLMModel.allCases, id: \.self) { model in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(model.displayName)
                                    .font(.headline)
                                
                                Text(model.providerName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedModels.contains(model) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedModels.contains(model) {
                                // Only allow removal if we have more than 2 models
                                if selectedModels.count > 2 {
                                    selectedModels.remove(model)
                                }
                            } else {
                                // Only allow adding if we have fewer than maximum
                                if selectedModels.count < maximumModelCount {
                                    selectedModels.insert(model)
                                }
                            }
                        }
                    }
                }
                
                Section(footer: Text("Maximum \(maximumModelCount) models can be compared at once.")) {
                    // Information about selection limits
                }
            }
            .navigationTitle("Select Models")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showModelSelector = false
                },
                trailing: Button("Done") {
                    showModelSelector = false
                }
            )
        }
    }
    
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparison Results")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Use Chart components for each metric
            ForEach(Array(selectedMetrics), id: \.self) { metric in
                metricChartView(for: metric)
            }
            
            // Summary Table
            summaryTableView
        }
    }
    
    @ViewBuilder
    private func metricChartView(for metric: ComparisonMetric) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metric.displayName)
                .font(.headline)
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(comparisonResults) { result in
                        BarMark(
                            x: .value("Model", result.model.displayName),
                            y: .value(metric.displayName, metric.getValue(from: result))
                        )
                        .foregroundStyle(by: .value("Model", result.model.displayName))
                    }
                }
                .frame(height: 200)
                .padding(.vertical)
            } else {
                // Fallback for iOS 15 - simple bar chart
                HStack(alignment: .bottom, spacing: 16) {
                    ForEach(comparisonResults) { result in
                        let value = metric.getValue(from: result)
                        let maxValue = comparisonResults.map { metric.getValue(from: $0) }.max() ?? 1.0
                        let ratio = value / maxValue
                        
                        VStack {
                            Text(String(format: "%.2f", value))
                                .font(.caption)
                                .rotationEffect(.degrees(-90))
                                .frame(height: 20)
                            
                            Rectangle()
                                .fill(colorForModel(result.model))
                                .frame(width: 30, height: 150 * ratio)
                            
                            Text(result.model.displayName)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                        }
                    }
                }
                .frame(height: 200)
                .padding(.vertical)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var summaryTableView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Performance Summary")
                .font(.headline)
            
            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("Model")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(8)
                        .frame(width: 100, alignment: .leading)
                        .background(Color.gray.opacity(0.2))
                    
                    ForEach(Array(selectedMetrics), id: \.self) { metric in
                        Text(metric.shortName)
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(8)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                    }
                }
                
                // Data rows
                ForEach(comparisonResults) { result in
                    HStack {
                        Text(result.model.displayName)
                            .font(.caption)
                            .padding(8)
                            .frame(width: 100, alignment: .leading)
                            .background(colorForModel(result.model).opacity(0.1))
                        
                        ForEach(Array(selectedMetrics), id: \.self) { metric in
                            Text(formatMetricValue(metric.getValue(from: result), for: metric))
                                .font(.caption)
                                .padding(8)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .background(
                                    metric.isLowerBetter
                                        ? (bestForMetric(metric) == result ? Color.green.opacity(0.1) : Color.clear)
                                        : (bestForMetric(metric) == result ? Color.green.opacity(0.1) : Color.clear)
                                )
                        }
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.vertical)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private func runComparison() {
        isRunningComparison = true
        
        // Simulate API call delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // In a real implementation, this would make API calls to run the comparison
            self.comparisonResults = self.sampleModelResults
            self.isRunningComparison = false
        }
    }
    
    private func colorForModel(_ model: LLMModel) -> Color {
        switch model.provider {
        case .anthropic:
            return .red
        case .openai:
            return .green
        case .google:
            return .blue
        case .mistral:
            return .purple
        case .meta:
            return .orange
        case .local:
            return .gray
        }
    }
    
    private func formatMetricValue(_ value: Double, for metric: ComparisonMetric) -> String {
        switch metric {
        case .responseTime:
            return String(format: "%.1fs", value)
        case .tokenCount:
            return String(format: "%.0f", value)
        case .tokenCost:
            return String(format: "$%.4f", value)
        case .accuracy:
            return String(format: "%.1f%%", value * 100)
        case .tokensPerSecond:
            return String(format: "%.1f", value)
        }
    }
    
    private func bestForMetric(_ metric: ComparisonMetric) -> ComparisonResult? {
        if metric.isLowerBetter {
            return comparisonResults.min { metric.getValue(from: $0) < metric.getValue(from: $1) }
        } else {
            return comparisonResults.max { metric.getValue(from: $0) < metric.getValue(from: $1) }
        }
    }
}

// MARK: - Supporting Types

/// Model Chip View
struct ModelChip: View {
    let model: LLMModel
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(model.displayName)
                .font(.caption)
                .padding(.leading, 8)
                .padding(.vertical, 4)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.trailing, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

/// Comparison Metrics
enum ComparisonMetric: String, CaseIterable {
    case responseTime
    case tokenCount
    case tokenCost
    case accuracy
    case tokensPerSecond
    
    var displayName: String {
        switch self {
        case .responseTime:
            return "Response Time"
        case .tokenCount:
            return "Token Count"
        case .tokenCost:
            return "Cost per Response"
        case .accuracy:
            return "Accuracy Score"
        case .tokensPerSecond:
            return "Tokens per Second"
        }
    }
    
    var shortName: String {
        switch self {
        case .responseTime:
            return "Time"
        case .tokenCount:
            return "Tokens"
        case .tokenCost:
            return "Cost"
        case .accuracy:
            return "Accuracy"
        case .tokensPerSecond:
            return "Speed"
        }
    }
    
    var isLowerBetter: Bool {
        switch self {
        case .responseTime, .tokenCost:
            return true
        case .tokenCount, .accuracy, .tokensPerSecond:
            return false
        }
    }
    
    func getValue(from result: ComparisonResult) -> Double {
        switch self {
        case .responseTime:
            return result.responseTime
        case .tokenCount:
            return Double(result.tokenCount)
        case .tokenCost:
            return result.tokenCost
        case .accuracy:
            return result.accuracy
        case .tokensPerSecond:
            return result.tokensPerSecond
        }
    }
}

/// Comparison Result Structure
struct ComparisonResult: Identifiable {
    var id = UUID()
    var model: LLMModel
    var responseTime: Double
    var tokenCount: Int
    var tokenCost: Double
    var accuracy: Double
    var tokensPerSecond: Double
}

struct ModelComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        ModelComparisonView()
            .environmentObject(AppState())
    }
}
