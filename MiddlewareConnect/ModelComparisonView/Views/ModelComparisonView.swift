/**
 * @fileoverview Main Model Comparison View component
 * @module ModelComparisonView
 * 
 * Created: 2025-04-02
 * Last Modified: 2025-04-02
 * 
 * Dependencies:
 * - SwiftUI
 * - Combine
 * - LLMServiceProvider
 * 
 * Exports:
 * - ModelComparisonView
 * 
 * Notes:
 * - Integrated component for LLM model comparison
 * - Supports multiple visualization options and metrics
 */

import SwiftUI
import Combine
import LLMServiceProvider

/// Main view for comparing LLM model performance across different metrics
public struct ModelComparisonView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: ModelComparisonViewModel
    @State private var selectedTab: TabSelection = .setup
    @State private var isShowingSettings = false
    @State private var isShowingExport = false
    
    // MARK: - Initialization
    
    /// Initialize with a view model
    /// - Parameter viewModel: The view model for comparison orchestration
    public init(viewModel: ModelComparisonViewModel = ModelComparisonViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selection
                segmentedTabs
                    .padding(.horizontal)
                    .padding(.top)
                
                // Main content
                tabContent
                    .padding()
            }
            .navigationTitle("Model Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    settingsButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    exportButton
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                ComparisonSettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $isShowingExport) {
                ExportView(viewModel: viewModel)
            }
            .alert(item: alertBinding) { alertInfo in
                Alert(
                    title: Text(alertInfo.title),
                    message: Text(alertInfo.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Segmented control for tab selection
    private var segmentedTabs: some View {
        Picker("Section", selection: $selectedTab) {
            Text("Setup").tag(TabSelection.setup)
            Text("Models").tag(TabSelection.models)
            Text("Metrics").tag(TabSelection.metrics)
            Text("Results").tag(TabSelection.results)
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedTab) { _ in
            // Switch to results tab when comparison is complete
            if case .completed = viewModel.comparisonState, selectedTab != .results {
                withAnimation {
                    selectedTab = .results
                }
            }
        }
    }
    
    /// Content for the selected tab
    private var tabContent: some View {
        ZStack {
            // Setup tab
            if selectedTab == .setup {
                setupTab
            }
            
            // Models tab
            if selectedTab == .models {
                modelsTab
            }
            
            // Metrics tab
            if selectedTab == .metrics {
                metricsTab
            }
            
            // Results tab
            if selectedTab == .results {
                resultsTab
            }
        }
    }
    
    /// Setup tab content
    private var setupTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparison Setup")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Comparison Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Enter comparison name", text: $viewModel.comparisonName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $viewModel.comparisonDescription)
                    .frame(height: 100)
                    .border(Color.gray.opacity(0.2))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Test Prompts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if viewModel.testPrompts.isEmpty {
                    Text("No test prompts added. Add prompts to compare model performance.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    List {
                        ForEach(viewModel.testPrompts) { prompt in
                            PromptListItemView(prompt: prompt) {
                                viewModel.removeTestPrompt(id: prompt.id)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.removeTestPrompt(id: viewModel.testPrompts[index].id)
                            }
                        }
                    }
                    .frame(height: 200)
                    .border(Color.gray.opacity(0.2))
                }
                
                Button(action: {
                    withAnimation {
                        viewModel.addTestPrompt(createSamplePrompt())
                    }
                }) {
                    Label("Add Test Prompt", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
            
            Button(action: startComparison) {
                Text("Start Comparison")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isReadyToCompare)
        }
    }
    
    /// Models tab content
    private var modelsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Models")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Available Models")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.availableModels, id: \.id) { model in
                            ModelSelectButton(
                                model: model,
                                isSelected: viewModel.selectedModels.contains { $0.id == model.id },
                                action: {
                                    if viewModel.selectedModels.contains(where: { $0.id == model.id }) {
                                        viewModel.removeModel(id: model.id)
                                    } else {
                                        viewModel.addModel(model)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected Models")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if viewModel.selectedModels.isEmpty {
                    Text("No models selected. Select at least one model to compare.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    List {
                        ForEach(viewModel.selectedModels) { model in
                            ModelConfigRow(
                                model: model,
                                onRemove: {
                                    viewModel.removeModel(id: model.id)
                                },
                                onUpdateParameters: { parameters in
                                    viewModel.updateModelParameters(id: model.id, parameters: parameters)
                                }
                            )
                        }
                    }
                    .frame(height: 250)
                    .border(Color.gray.opacity(0.2))
                }
            }
            
            Spacer()
            
            Button(action: startComparison) {
                Text("Start Comparison")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isReadyToCompare)
        }
    }
    
    /// Metrics tab content
    private var metricsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Metrics")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Available Metrics")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(viewModel.availableMetrics) { metric in
                            MetricSelectCard(
                                metric: metric,
                                isSelected: viewModel.selectedMetrics.contains { $0.id == metric.id },
                                action: {
                                    if viewModel.selectedMetrics.contains(where: { $0.id == metric.id }) {
                                        viewModel.removeMetric(id: metric.id)
                                    } else {
                                        viewModel.addMetric(metric)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(height: 300)
                .border(Color.gray.opacity(0.2))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected Metrics")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if viewModel.selectedMetrics.isEmpty {
                    Text("No metrics selected. Select at least one metric for evaluation.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.selectedMetrics) { metric in
                                MetricChip(
                                    name: metric.name,
                                    category: metric.category.displayName,
                                    onRemove: {
                                        viewModel.removeMetric(id: metric.id)
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            
            Spacer()
            
            Button(action: startComparison) {
                Text("Start Comparison")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isReadyToCompare)
        }
    }
    
    /// Results tab content
    private var resultsTab: some View {
        Group {
            if case .completed = viewModel.comparisonState, let results = viewModel.comparisonResults {
                ComparisonResultsView(
                    results: results,
                    visualizationSettings: $viewModel.visualizationSettings
                )
            } else if case .comparing(let progress) = viewModel.comparisonState {
                ComparisonProgressView(
                    progress: progress,
                    inProgressResults: viewModel.inProgressResults,
                    onCancel: {
                        viewModel.cancelComparison()
                    }
                )
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No comparison results yet")
                        .font(.title2)
                    
                    Text("Set up and run a comparison to see results here")
                        .foregroundColor(.secondary)
                    
                    Button(action: startComparison) {
                        Text("Start Comparison")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isReadyToCompare)
                    .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    /// Button to open settings
    private var settingsButton: some View {
        Button(action: {
            isShowingSettings = true
        }) {
            Image(systemName: "gear")
        }
    }
    
    /// Button to open export options
    private var exportButton: some View {
        Button(action: {
            isShowingExport = true
        }) {
            Image(systemName: "square.and.arrow.up")
        }
        .disabled(viewModel.comparisonResults == nil)
    }
    
    // MARK: - Alert Handling
    
    /// Structure for alert information
    private struct AlertInfo: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    
    /// Binding for alert presentation
    private var alertBinding: Binding<AlertInfo?> {
        Binding<AlertInfo?>(
            get: {
                if let errorMessage = viewModel.errorMessage {
                    return AlertInfo(
                        title: "Error",
                        message: errorMessage
                    )
                }
                return nil
            },
            set: { _ in
                viewModel.errorMessage = nil
            }
        )
    }
    
    // MARK: - Helper Methods
    
    /// Checks if the comparison is ready to start
    private var isReadyToCompare: Bool {
        !viewModel.selectedModels.isEmpty &&
        !viewModel.selectedMetrics.isEmpty &&
        !viewModel.testPrompts.isEmpty &&
        viewModel.comparisonState != .comparing(progress: 0)
    }
    
    /// Starts the comparison
    private func startComparison() {
        withAnimation {
            selectedTab = .results
            viewModel.startComparison()
        }
    }
    
    /// Creates a sample test prompt
    private func createSamplePrompt() -> ModelComparisonViewModel.TestPrompt {
        ModelComparisonViewModel.TestPrompt(
            name: "Sample Prompt \(viewModel.testPrompts.count + 1)",
            content: "Explain the concept of machine learning in simple terms.",
            category: "General",
            expectedResponse: nil,
            iterations: 1
        )
    }
    
    // MARK: - Tab Selection
    
    /// Available tabs in the view
    private enum TabSelection {
        case setup
        case models
        case metrics
        case results
    }
}

// MARK: - Supporting Views

/// Button for selecting a model
struct ModelSelectButton: View {
    let model: ModelComparisonViewModel.ModelConfig
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.displayName)
                    .font(.headline)
                
                Text(model.modelType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 150, height: 80)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Row for configuring a model
struct ModelConfigRow: View {
    let model: ModelComparisonViewModel.ModelConfig
    let onRemove: () -> Void
    let onUpdateParameters: (ModelComparisonViewModel.ModelParameters) -> Void
    
    @State private var temperature: Double
    @State private var topP: Double
    @State private var isExpanded: Bool = false
    
    init(model: ModelComparisonViewModel.ModelConfig, onRemove: @escaping () -> Void, onUpdateParameters: @escaping (ModelComparisonViewModel.ModelParameters) -> Void) {
        self.model = model
        self.onRemove = onRemove
        self.onUpdateParameters = onUpdateParameters
        _temperature = State(initialValue: model.parameters.temperature)
        _topP = State(initialValue: model.parameters.topP)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.headline)
                    
                    Text(model.modelType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Temperature: \(temperature, specifier: "%.2f")")
                            .font(.caption)
                        
                        Slider(value: $temperature, in: 0...1) { _ in
                            updateParameters()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Top-P: \(topP, specifier: "%.2f")")
                            .font(.caption)
                        
                        Slider(value: $topP, in: 0...1) { _ in
                            updateParameters()
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func updateParameters() {
        var newParameters = model.parameters
        newParameters.temperature = temperature
        newParameters.topP = topP
        onUpdateParameters(newParameters)
    }
}

/// Card for selecting a metric
struct MetricSelectCard: View {
    let metric: ComparisonMetric
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(metric.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Text(metric.category.displayName)
                    .font(.caption)
                    .padding(4)
                    .background(categoryColor.opacity(0.2))
                    .cornerRadius(4)
                
                Text(metric.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding()
            .frame(height: 120)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var categoryColor: Color {
        switch metric.category {
        case .quality:
            return Color.blue
        case .performance:
            return Color.green
        case .reasoning:
            return Color.purple
        case .taskSpecific:
            return Color.orange
        case .consistency:
            return Color.cyan
        case .ethics:
            return Color.indigo
        case .risk:
            return Color.red
        case .custom:
            return Color.gray
        }
    }
}

/// Chip for displaying a selected metric
struct MetricChip: View {
    let name: String
    let category: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.caption)
                .foregroundColor(.white)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue)
        .cornerRadius(16)
    }
}

/// View for a prompt list item
struct PromptListItemView: View {
    let prompt: ModelComparisonViewModel.TestPrompt
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prompt.name)
                    .font(.headline)
                
                Spacer()
                
                Text(prompt.category)
                    .font(.caption)
                    .padding(4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            
            Text(prompt.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 8)
    }
}

/// View for comparison results
struct ComparisonResultsView: View {
    let results: ComparisonResult
    @Binding var visualizationSettings: ModelComparisonViewModel.VisualizationSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparison Results")
                .font(.headline)
            
            visualizationControls
            
            resultContent
        }
    }
    
    private var visualizationControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Visualization")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Picker("Chart Type", selection: $visualizationSettings.chartType) {
                    ForEach(ModelComparisonViewModel.VisualizationSettings.ChartType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            HStack {
                Toggle("Normalize Scores", isOn: $visualizationSettings.normalizeScores)
                
                Spacer()
                
                Toggle("Group by Category", isOn: $visualizationSettings.groupByCategory)
            }
            .font(.caption)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var resultContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Model rankings
            VStack(alignment: .leading, spacing: 8) {
                Text("Model Rankings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(results.summary.modelRankings.sorted(by: { $0.rank < $1.rank }), id: \.modelId) { ranking in
                    if let model = results.models.first(where: { $0.id == ranking.modelId }) {
                        HStack {
                            Text("\(ranking.rank). \(model.name)")
                            
                            Spacer()
                            
                            Text("\(ranking.overallScore, specifier: "%.1f")")
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // Performance by category
            VStack(alignment: .leading, spacing: 8) {
                Text("Performance by Category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(results.summary.categoryPerformance, id: \.category) { category in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.category)
                            .font(.caption)
                            .bold()
                        
                        HStack(spacing: 0) {
                            ForEach(results.models, id: \.id) { model in
                                if let score = category.scoresByModel[model.id] {
                                    let normalizedScore = min(1.0, max(0.0, score))
                                    
                                    VStack {
                                        Rectangle()
                                            .fill(model.id == category.bestModelId ? Color.green : Color.blue)
                                            .frame(height: 20)
                                            .frame(maxWidth: .infinity)
                                            .scaleEffect(x: 1, y: CGFloat(normalizedScore), anchor: .bottom)
                                        
                                        Text(model.name)
                                            .font(.caption2)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(1)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // Key insights
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Insights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(results.summary.analysis.overallInsights, id: \.self) { insight in
                    Text("• \(insight)")
                        .font(.caption)
                        .padding(.vertical, 2)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.top, 8)
    }
}

/// View for comparison progress
struct ComparisonProgressView: View {
    let progress: Double
    let inProgressResults: [ModelComparisonViewModel.ProgressResultItem]
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Comparison in Progress")
                .font(.headline)
            
            ProgressView(value: progress)
                .padding(.horizontal)
            
            Text("\(Int(progress * 100))% Complete")
                .foregroundColor(.secondary)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(inProgressResults) { item in
                        ComparisonProgressItemView(item: item)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal)
            
            Button("Cancel Comparison", action: onCancel)
                .buttonStyle(.bordered)
                .foregroundColor(.red)
        }
        .padding()
    }
}

/// View for a progress item
struct ComparisonProgressItemView: View {
    let item: ModelComparisonViewModel.ProgressResultItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(item.model.displayName)
                        .font(.caption)
                        .bold()
                    
                    Text(" • ")
                        .foregroundColor(.gray)
                    
                    Text(item.metric.name)
                        .font(.caption)
                }
                
                Text(item.prompt.name)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            statusView
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    private var statusView: some View {
        Group {
            switch item.status {
            case .pending:
                Text("Pending")
                    .font(.caption)
                    .foregroundColor(.gray)
                
            case .processing:
                HStack(spacing: 4) {
                    Text("Processing")
                        .font(.caption)
                    
                    ProgressView()
                        .scaleEffect(0.5)
                }
                .foregroundColor(.blue)
                
            case .completed:
                if let score = item.score {
                    Text("\(score, specifier: "%.1f")")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.green)
                } else {
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
            case .failed(let error):
                VStack(alignment: .trailing) {
                    Text("Failed")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }
        }
    }
}

/// View for comparison settings
struct ComparisonSettingsView: View {
    @ObservedObject var viewModel: ModelComparisonViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Comparison Options")) {
                    Stepper(
                        "Test Iterations: \(viewModel.comparisonOptions.iterations)",
                        value: Binding(
                            get: { viewModel.comparisonOptions.iterations },
                            set: { viewModel.comparisonOptions = updateOptions(iterations: $0) }
                        ),
                        in: 1...10
                    )
                    
                    Toggle(
                        "Parallel Execution",
                        isOn: Binding(
                            get: { viewModel.comparisonOptions.useParallelExecution },
                            set: { viewModel.comparisonOptions = updateOptions(useParallelExecution: $0) }
                        )
                    )
                    
                    Toggle(
                        "Cache Results",
                        isOn: Binding(
                            get: { viewModel.comparisonOptions.cacheResults },
                            set: { viewModel.comparisonOptions = updateOptions(cacheResults: $0) }
                        )
                    )
                    
                    Toggle(
                        "Include Analysis",
                        isOn: Binding(
                            get: { viewModel.comparisonOptions.includeAnalysis },
                            set: { viewModel.comparisonOptions = updateOptions(includeAnalysis: $0) }
                        )
                    )
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func updateOptions(
        iterations: Int? = nil,
        useParallelExecution: Bool? = nil,
        cacheResults: Bool? = nil,
        includeAnalysis: Bool? = nil
    ) -> ModelComparisonViewModel.ComparisonOptions {
        ModelComparisonViewModel.ComparisonOptions(
            iterations: iterations ?? viewModel.comparisonOptions.iterations,
            useParallelExecution: useParallelExecution ?? viewModel.comparisonOptions.useParallelExecution,
            cacheResults: cacheResults ?? viewModel.comparisonOptions.cacheResults,
            includeAnalysis: includeAnalysis ?? viewModel.comparisonOptions.includeAnalysis
        )
    }
}

/// View for exporting comparison results
struct ExportView: View {
    @ObservedObject var viewModel: ModelComparisonViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedFormat: ModelComparisonViewModel.ExportFormat = .json
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Comparison Results")
                    .font(.headline)
                
                Picker("Export Format", selection: $selectedFormat) {
                    Text("JSON").tag(ModelComparisonViewModel.ExportFormat.json)
                    Text("CSV").tag(ModelComparisonViewModel.ExportFormat.csv)
                    Text("PDF").tag(ModelComparisonViewModel.ExportFormat.pdf)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if let results = viewModel.comparisonResults {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(results.name)
                            .font(.headline)
                        
                        Text(results.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("\(results.models.count) Models")
                            Text("•")
                            Text("\(results.metrics.count) Metrics")
                            Text("•")
                            Text("\(results.prompts.count) Prompts")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                Button(action: exportResults) {
                    Label("Export Results", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 20)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func exportResults() {
        // In a real app, this would trigger a file export
        if let _ = viewModel.exportResults(format: selectedFormat) {
            // Show success feedback
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview

struct ModelComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        ModelComparisonView()
    }
}
