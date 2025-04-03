import SwiftUI

struct ModelComparisonView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedModels: [LLMModel] = []
    @State private var isComparing: Bool = false
    @State private var showResults: Bool = false
    @State private var prompt: String = ""
    
    private let defaultPrompt = "Explain the concept of recursion as if you were teaching a beginner programmer."
    
    // Sample comparison metrics
    @State private var comparisonResults: [ComparisonResult] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HeaderView(title: "Model Comparison", 
                           description: "Compare different LLM models side by side")
                
                // Model selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Models to Compare")
                        .font(.headline)
                    
                    ForEach(LLMModel.defaultModels) { model in
                        ModelSelectionRow(
                            model: model,
                            isSelected: selectedModels.contains(where: { $0.id == model.id }),
                            onToggle: {
                                toggleModelSelection(model)
                            }
                        )
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Prompt input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Test Prompt")
                        .font(.headline)
                    
                    TextEditor(text: $prompt)
                        .font(.body)
                        .padding(8)
                        .frame(minHeight: 120)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Button(action: {
                        resetPrompt()
                    }) {
                        Text("Reset to Default Prompt")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Compare button
                Button(action: {
                    compareModels()
                }) {
                    if isComparing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding(.horizontal)
                    } else {
                        Text("Compare Models")
                            .fontWeight(.medium)
                            .padding(.horizontal)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(selectedModels.count >= 2 ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(selectedModels.count < 2 || isComparing || prompt.isEmpty)
                
                // Comparison results
                if showResults {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Comparison Results")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        // Metrics cards
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(comparisonResults) { result in
                                MetricCard(result: result)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical)
                        
                        // Response comparison
                        Text("Response Samples")
                            .font(.headline)
                        
                        ForEach(selectedModels) { model in
                            ResponseCard(model: model)
                                .padding(.bottom)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Model Comparison")
        .onAppear {
            resetPrompt()
        }
    }
    
    private func toggleModelSelection(_ model: LLMModel) {
        if let index = selectedModels.firstIndex(where: { $0.id == model.id }) {
            selectedModels.remove(at: index)
        } else {
            // Limit to max 3 models
            if selectedModels.count < 3 {
                selectedModels.append(model)
            }
        }
    }
    
    private func resetPrompt() {
        prompt = defaultPrompt
    }
    
    private func compareModels() {
        guard selectedModels.count >= 2 else { return }
        
        isComparing = true
        
        // Simulate API calls and processing time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            // Generate mock comparison results
            generateMockResults()
            
            isComparing = false
            showResults = true
        }
    }
    
    private func generateMockResults() {
        comparisonResults = [
            ComparisonResult(
                id: UUID(),
                title: "Response Time",
                metrics: selectedModels.map { model in
                    MetricValue(
                        modelID: model.id,
                        modelName: model.name,
                        value: Double.random(in: 1.2...8.5),
                        unit: "seconds",
                        isLowerBetter: true
                    )
                }
            ),
            ComparisonResult(
                id: UUID(),
                title: "Output Length",
                metrics: selectedModels.map { model in
                    MetricValue(
                        modelID: model.id,
                        modelName: model.name,
                        value: Double(Int.random(in: 120...580)),
                        unit: "words",
                        isLowerBetter: false
                    )
                }
            ),
            ComparisonResult(
                id: UUID(),
                title: "Tokens Used",
                metrics: selectedModels.map { model in
                    MetricValue(
                        modelID: model.id,
                        modelName: model.name,
                        value: Double(Int.random(in: 200...1200)),
                        unit: "tokens",
                        isLowerBetter: true
                    )
                }
            ),
            ComparisonResult(
                id: UUID(),
                title: "Estimated Cost",
                metrics: selectedModels.map { model in
                    MetricValue(
                        modelID: model.id,
                        modelName: model.name,
                        value: Double.random(in: 0.01...0.15),
                        unit: "$",
                        isLowerBetter: true
                    )
                }
            )
        ]
    }
}

struct HeaderView: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ModelSelectionRow: View {
    let model: LLMModel
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? model.provider.color : Color.gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(model.provider.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(model.contextSize / 1000)K context")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MetricCard: View {
    let result: ComparisonResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(result.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                // Sort metrics based on whether lower or higher is better
                ForEach(sortedMetrics()) { metric in
                    HStack {
                        Rectangle()
                            .fill(getBestModelMetric() == metric ? Color.green : Color.gray.opacity(0.5))
                            .frame(width: 4)
                            .cornerRadius(2)
                        
                        Text(metric.modelName)
                            .font(.subheadline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(formatValue(metric.value, unit: metric.unit))
                            .font(.subheadline)
                            .fontWeight(getBestModelMetric() == metric ? .bold : .regular)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func sortedMetrics() -> [MetricValue] {
        return result.metrics.sorted { first, second in
            if result.metrics[0].isLowerBetter {
                return first.value < second.value
            } else {
                return first.value > second.value
            }
        }
    }
    
    private func getBestModelMetric() -> MetricValue {
        return sortedMetrics().first!
    }
    
    private func formatValue(_ value: Double, unit: String) -> String {
        if unit == "$" {
            return unit + String(format: "%.3f", value)
        } else if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value) + " " + unit
        } else {
            return String(format: "%.1f", value) + " " + unit
        }
    }
}

struct ResponseCard: View {
    let model: LLMModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(model.name)
                    .font(.headline)
                
                Spacer()
                
                Text(model.provider.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(model.provider.color.opacity(0.1))
                    .foregroundColor(model.provider.color)
                    .cornerRadius(4)
            }
            
            Text(generateMockResponse())
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack {
                Spacer()
                
                Button(action: {}) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func generateMockResponse() -> String {
        return "Recursion is like looking at yourself in a mirror that reflects another mirror, creating an infinite loop of reflections. In programming, it's when a function calls itself to solve smaller instances of the same problem. Each call creates a new layer, and when the smallest case is solved, the results cascade back up through the layers."
    }
}

// Model for comparison results
struct ComparisonResult: Identifiable {
    let id: UUID
    let title: String
    let metrics: [MetricValue]
}

struct MetricValue: Identifiable {
    var id: UUID {
        return modelID
    }
    let modelID: UUID
    let modelName: String
    let value: Double
    let unit: String
    let isLowerBetter: Bool
}

struct ModelComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        ModelComparisonView()
            .environmentObject(AppState())
    }
}
