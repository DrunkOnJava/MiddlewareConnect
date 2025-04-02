/**
 * @fileoverview Context Window Visualizer for understanding token usage in prompts
 * @module ContextWindowVisualizerView
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - SwiftUI
 * - Charts (iOS 16+)
 * 
 * Exports:
 * - ContextWindowVisualizerView
 */

import SwiftUI
import Charts
import UniformTypeIdentifiers

struct ContextWindowVisualizerView: View {
    // MARK: - State Variables
    @State private var inputText: String = ""
    @State private var selectedModel: LLMModel = .gpt4Turbo
    @State private var showModelSettings: Bool = false
    @State private var includeSystemPrompt: Bool = true
    @State private var includeResponseTokens: Bool = true
    @State private var systemPrompt: String = "You are a helpful AI assistant."
    @State private var expectedOutputSize: OutputSize = .medium
    @State private var customOutputTokens: Int = 500
    @State private var totalTokensUsed: Int = 0
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    @State private var showingInfo: Bool = false
    @State private var showTokenBreakdown: Bool = false
    @State private var isProcessing: Bool = false
    @State private var savedVisualizations: [SavedVisualization] = []
    @State private var showSavedVisualizations: Bool = false
    @State private var saveName: String = ""
    @State private var showSaveDialog: Bool = false
    
    // MARK: - Enums and Structs
    
    enum LLMModel: String, CaseIterable, Identifiable {
        case gpt35Turbo = "GPT-3.5 Turbo (4K)"
        case gpt35Turbo16K = "GPT-3.5 Turbo (16K)"
        case gpt4 = "GPT-4 (8K)"
        case gpt4Turbo = "GPT-4 Turbo (128K)"
        case claude3Sonnet = "Claude 3 Sonnet (200K)"
        case claude3Opus = "Claude 3 Opus (200K)"
        case llama3 = "Llama 3 (8K)"
        case mistral = "Mistral Large (32K)"
        case custom = "Custom Model"
        
        var id: String { self.rawValue }
        
        var contextSize: Int {
            switch self {
            case .gpt35Turbo: return 4096
            case .gpt35Turbo16K: return 16384
            case .gpt4: return 8192
            case .gpt4Turbo: return 128000
            case .claude3Sonnet, .claude3Opus: return 200000
            case .llama3: return 8192
            case .mistral: return 32768
            case .custom: return 8192 // Default for custom
            }
        }
        
        var color: Color {
            switch self {
            case .gpt35Turbo, .gpt35Turbo16K, .gpt4, .gpt4Turbo: return .blue
            case .claude3Sonnet, .claude3Opus: return .purple
            case .llama3: return .orange
            case .mistral: return .cyan
            case .custom: return .gray
            }
        }
    }
    
    enum OutputSize: String, CaseIterable, Identifiable {
        case small = "Small (~200 tokens)"
        case medium = "Medium (~500 tokens)"
        case large = "Large (~1000 tokens)"
        case extraLarge = "Extra Large (~2000 tokens)"
        case custom = "Custom"
        
        var id: String { self.rawValue }
        
        var tokenCount: Int {
            switch self {
            case .small: return 200
            case .medium: return 500
            case .large: return 1000
            case .extraLarge: return 2000
            case .custom: return 0 // Placeholder, will use customOutputTokens
            }
        }
    }
    
    struct TokenUsage: Identifiable {
        let id = UUID()
        let title: String
        let count: Int
        let color: Color
    }
    
    struct SavedVisualization: Identifiable {
        let id = UUID()
        let name: String
        let model: LLMModel
        let inputTokens: Int
        let systemTokens: Int
        let responseTokens: Int
        let contextSize: Int
        let date: Date
    }
    
    // MARK: - Computed Properties
    
    var systemPromptTokens: Int {
        estimateTokens(for: systemPrompt)
    }
    
    var inputTokens: Int {
        estimateTokens(for: inputText)
    }
    
    var outputTokens: Int {
        if expectedOutputSize == .custom {
            return customOutputTokens
        } else {
            return expectedOutputSize.tokenCount
        }
    }
    
    var remainingContextTokens: Int {
        let usedTokens = (includeSystemPrompt ? systemPromptTokens : 0) + inputTokens + (includeResponseTokens ? outputTokens : 0)
        return max(0, selectedModel.contextSize - usedTokens)
    }
    
    var contextUtilizationPercentage: Double {
        let usedTokens = Double((includeSystemPrompt ? systemPromptTokens : 0) + inputTokens + (includeResponseTokens ? outputTokens : 0))
        return min(100, (usedTokens / Double(selectedModel.contextSize)) * 100)
    }
    
    var tokenBreakdown: [TokenUsage] {
        var result: [TokenUsage] = []
        
        if includeSystemPrompt && systemPromptTokens > 0 {
            result.append(TokenUsage(title: "System Prompt", count: systemPromptTokens, color: .purple))
        }
        
        if inputTokens > 0 {
            result.append(TokenUsage(title: "User Input", count: inputTokens, color: .blue))
        }
        
        if includeResponseTokens && outputTokens > 0 {
            result.append(TokenUsage(title: "Expected Response", count: outputTokens, color: .green))
        }
        
        if remainingContextTokens > 0 {
            result.append(TokenUsage(title: "Remaining", count: remainingContextTokens, color: .gray.opacity(0.3)))
        }
        
        return result
    }
    
    var statusMessage: (message: String, color: Color) {
        let usedTokens = (includeSystemPrompt ? systemPromptTokens : 0) + inputTokens + (includeResponseTokens ? outputTokens : 0)
        let remainingPercentage = (Double(remainingContextTokens) / Double(selectedModel.contextSize)) * 100
        
        if remainingPercentage <= 0 {
            return ("Context window exceeded", .red)
        } else if remainingPercentage < 10 {
            return ("Context nearly full", .orange)
        } else if remainingPercentage < 30 {
            return ("Approaching context limit", .yellow)
        } else {
            return ("Context utilization healthy", .green)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "rectangle.and.text.magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    Text("Context Window Visualizer")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showingInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 5)
                
                Text("Understand and optimize your prompt token usage for different LLM models")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // Model Selection Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Select LLM Model")
                        .font(.headline)
                    
                    VStack {
                        Picker("Model", selection: $selectedModel) {
                            ForEach(LLMModel.allCases) { model in
                                Text(model.rawValue).tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                        
                        HStack {
                            Text("Context window size:")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(selectedModel.contextSize.formattedWithCommas) tokens")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
                .padding(.vertical, 5)
                
                // Input Text Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("2. Enter Prompt Text")
                        .font(.headline)
                    
                    // System prompt toggle and input
                    VStack(alignment: .leading, spacing: 5) {
                        Toggle("Include system prompt", isOn: $includeSystemPrompt)
                            .padding(.vertical, 5)
                        
                        if includeSystemPrompt {
                            Text("System Prompt:")
                                .font(.subheadline)
                            
                            TextEditor(text: $systemPrompt)
                                .font(.system(.body, design: .monospaced))
                                .frame(height: 60)
                                .padding(5)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            Text("\(systemPromptTokens) tokens")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    // User prompt input
                    VStack(alignment: .leading, spacing: 5) {
                        Text("User Prompt:")
                            .font(.subheadline)
                        
                        TextEditor(text: $inputText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 150)
                            .padding(5)
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        HStack {
                            Text("\(inputTokens) tokens")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                isImporting = true
                            }) {
                                Label("Import Text", systemImage: "square.and.arrow.down")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    // Output token estimation
                    VStack(alignment: .leading, spacing: 5) {
                        Toggle("Include expected response tokens", isOn: $includeResponseTokens)
                            .padding(.vertical, 5)
                        
                        if includeResponseTokens {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Expected response size:")
                                    .font(.subheadline)
                                
                                Picker("Response Size", selection: $expectedOutputSize) {
                                    ForEach(OutputSize.allCases) { size in
                                        Text(size.rawValue).tag(size)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                
                                if expectedOutputSize == .custom {
                                    HStack {
                                        Text("Custom token count:")
                                        
                                        Stepper("\(customOutputTokens)", value: $customOutputTokens, in: 100...5000, step: 100)
                                    }
                                    .padding(.top, 5)
                                }
                                
                                Text("\(outputTokens) tokens")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
                .padding(.vertical, 5)
                
                // Context Utilization Visualization
                VStack(alignment: .leading, spacing: 10) {
                    Text("3. Context Window Utilization")
                        .font(.headline)
                    
                    // Status indicator
                    HStack {
                        Text(statusMessage.message)
                            .fontWeight(.medium)
                            .foregroundColor(statusMessage.color)
                        
                        Spacer()
                        
                        Text("\(Int(contextUtilizationPercentage))% used")
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    // Visualization bar
                    VStack(alignment: .leading, spacing: 5) {
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                ForEach(tokenBreakdown) { usage in
                                    let width = (Double(usage.count) / Double(selectedModel.contextSize)) * geometry.size.width
                                    
                                    Rectangle()
                                        .fill(usage.color)
                                        .frame(width: max(1, width))
                                        .overlay(
                                            Text(usage.count > selectedModel.contextSize / 20 ? "\(usage.count)" : "")
                                                .font(.system(size: 10))
                                                .foregroundColor(.white)
                                                .padding(2)
                                        )
                                }
                            }
                            .frame(height: 30)
                            .cornerRadius(8)
                        }
                        .frame(height: 30)
                        
                        // Legend
                        HStack {
                            ForEach(tokenBreakdown) { usage in
                                HStack {
                                    Rectangle()
                                        .fill(usage.color)
                                        .frame(width: 12, height: 12)
                                    
                                    Text(usage.title)
                                        .font(.caption2)
                                    
                                    if tokenBreakdown.last?.id != usage.id {
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(.top, 5)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    // Token Breakdown Chart (if supported in iOS 16+)
                    if #available(iOS 16.0, *) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Token Distribution:")
                                .font(.subheadline)
                            
                            Chart {
                                ForEach(tokenBreakdown.filter { $0.title != "Remaining" }) { item in
                                    SectorMark(
                                        angle: .value("Tokens", item.count),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(item.color)
                                    .cornerRadius(5)
                                    .annotation(position: .overlay) {
                                        if Double(item.count) / Double(selectedModel.contextSize - remainingContextTokens) > 0.1 {
                                            Text("\(Int(Double(item.count) / Double(selectedModel.contextSize - remainingContextTokens) * 100))%")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                    
                    // Detailed token breakdown button
                    Button(action: {
                        showTokenBreakdown.toggle()
                    }) {
                        HStack {
                            Image(systemName: showTokenBreakdown ? "chevron.up" : "chevron.down")
                            Text(showTokenBreakdown ? "Hide Detailed Breakdown" : "Show Detailed Breakdown")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                    
                    if showTokenBreakdown {
                        // Detailed breakdown
                        VStack(alignment: .leading, spacing: 10) {
                            Group {
                                HStack {
                                    Text("Model:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(selectedModel.rawValue)
                                }
                                
                                HStack {
                                    Text("Total Context Window:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(selectedModel.contextSize.formattedWithCommas) tokens")
                                }
                                
                                Divider()
                                
                                if includeSystemPrompt {
                                    HStack {
                                        Text("System Prompt:")
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text("\(systemPromptTokens) tokens")
                                    }
                                }
                                
                                HStack {
                                    Text("User Input:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(inputTokens) tokens")
                                }
                                
                                if includeResponseTokens {
                                    HStack {
                                        Text("Expected Response:")
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text("\(outputTokens) tokens")
                                    }
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Total Used:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(selectedModel.contextSize - remainingContextTokens) tokens")
                                }
                                
                                HStack {
                                    Text("Remaining:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(remainingContextTokens) tokens")
                                        .foregroundColor(remainingContextTokens > 0 ? .primary : .red)
                                }
                                
                                HStack {
                                    Text("Context Utilization:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text("\(Int(contextUtilizationPercentage))%")
                                        .foregroundColor(contextUtilizationPercentage < 90 ? .primary : .orange)
                                }
                            }
                            
                            // Model comparison
                            if inputTokens > 0 {
                                Divider()
                                
                                Text("How this would fit in other models:")
                                    .fontWeight(.medium)
                                    .padding(.vertical, 5)
                                
                                ForEach(LLMModel.allCases.filter { $0 != selectedModel && $0 != .custom }, id: \.self) { model in
                                    let usedTokens = (includeSystemPrompt ? systemPromptTokens : 0) + inputTokens + (includeResponseTokens ? outputTokens : 0)
                                    let modelFit = Double(usedTokens) / Double(model.contextSize)
                                    let wouldFit = modelFit <= 1.0
                                    
                                    HStack {
                                        Text(model.rawValue)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        if wouldFit {
                                            Text("\(Int(modelFit * 100))% used")
                                                .font(.subheadline)
                                                .foregroundColor(.green)
                                        } else {
                                            Text("\(Int(modelFit * 100))% needed")
                                                .font(.subheadline)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                    
                    // Action buttons
                    HStack {
                        Button(action: {
                            showSaveDialog = true
                        }) {
                            HStack {
                                Image(systemName: "bookmark")
                                Text("Save")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            showSavedVisualizations = true
                        }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("History")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            shareVisualization()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 5)
                
                // Tips & Recommendations
                if inputTokens > 0 {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tips & Recommendations")
                            .font(.headline)
                        
                        // Optimization tips based on current usage
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(getOptimizationTips(), id: \.self) { tip in
                                HStack(alignment: .top) {
                                    Image(systemName: "lightbulb")
                                        .foregroundColor(.yellow)
                                        .frame(width: 24)
                                    
                                    Text(tip)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding()
        }
        .navigationTitle("Context Visualizer")
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [UTType.plainText, UTType.text],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile = try result.get().first else { return }
                
                if selectedFile.startAccessingSecurityScopedResource() {
                    defer { selectedFile.stopAccessingSecurityScopedResource() }
                    
                    if let data = try? Data(contentsOf: selectedFile),
                       let content = String(data: data, encoding: .utf8) {
                        inputText = content
                    }
                }
            } catch {
                print("Error importing text: \(error.localizedDescription)")
            }
        }
        .alert("Context Window Visualizer", isPresented: $showingInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This tool helps you visualize how your prompts fit within a model's context window. It estimates token usage for system prompts, user inputs, and expected responses, helping you optimize your prompts and avoid hitting context limits.")
        }
        .sheet(isPresented: $showSaveDialog) {
            SaveVisualizationView(
                isPresented: $showSaveDialog,
                saveName: $saveName,
                savedVisualizations: $savedVisualizations,
                currentVisualization: SavedVisualization(
                    name: "",
                    model: selectedModel,
                    inputTokens: inputTokens,
                    systemTokens: includeSystemPrompt ? systemPromptTokens : 0,
                    responseTokens: includeResponseTokens ? outputTokens : 0,
                    contextSize: selectedModel.contextSize,
                    date: Date()
                )
            )
        }
        .sheet(isPresented: $showSavedVisualizations) {
            SavedVisualizationsView(
                isPresented: $showSavedVisualizations,
                savedVisualizations: $savedVisualizations,
                onSelect: loadSavedVisualization
            )
        }
    }
    
    // MARK: - Methods
    
    private func estimateTokens(for text: String) -> Int {
        // Simple token estimation - approximately 4 characters per token for English
        // In a real app, you would use a proper tokenizer specific to each model
        guard !text.isEmpty else { return 0 }
        return max(1, Int(Double(text.count) / 4.0))
    }
    
    private func getOptimizationTips() -> [String] {
        var tips: [String] = []
        
        // Token-based tips
        if contextUtilizationPercentage > 90 {
            tips.append("Your prompt is using over 90% of the available context window. Consider shortening your input or using a model with a larger context window.")
        }
        
        if remainingContextTokens <= 0 {
            tips.append("Your prompt exceeds the model's context window. Reduce your input text or switch to a model with a larger context window like \(getLargerContextModel().rawValue).")
        }
        
        if systemPromptTokens > 100 && Double(systemPromptTokens) / Double(selectedModel.contextSize) > 0.1 {
            tips.append("Your system prompt is using more than 10% of the context window. Consider making it more concise.")
        }
        
        // Model-specific tips
        switch selectedModel {
        case .gpt35Turbo:
            if inputTokens > 2000 {
                tips.append("For longer inputs like yours, consider GPT-3.5 Turbo 16K or GPT-4 Turbo which have larger context windows.")
            }
        case .gpt4:
            if inputTokens > 6000 {
                tips.append("Your input is approaching GPT-4's context limit. Consider using GPT-4 Turbo which has a 128K token context window.")
            }
        case .claude3Sonnet, .claude3Opus:
            if inputTokens > 150000 {
                tips.append("Your input is very large. Even with Claude's 200K context window, consider breaking up your task into smaller chunks for better results.")
            }
        default:
            break
        }
        
        // General tips
        if inputTokens > 0 && tips.isEmpty {
            tips.append("Your prompt fits well within the context window. You have \(remainingContextTokens) tokens remaining for additional content or model responses.")
        }
        
        return tips
    }
    
    private func getLargerContextModel() -> LLMModel {
        let usedTokens = (includeSystemPrompt ? systemPromptTokens : 0) + inputTokens + (includeResponseTokens ? outputTokens : 0)
        
        let models = LLMModel.allCases.filter { $0 != .custom && $0.contextSize > usedTokens }
        
        if let smallestViableModel = models.min(by: { $0.contextSize < $1.contextSize }) {
            return smallestViableModel
        }
        
        // If all models are too small, return the largest one
        return LLMModel.allCases.filter { $0 != .custom }.max(by: { $0.contextSize < $1.contextSize }) ?? .claude3Opus
    }
    
    private func shareVisualization() {
        let usedTokens = (includeSystemPrompt ? systemPromptTokens : 0) + inputTokens + (includeResponseTokens ? outputTokens : 0)
        
        let details = """
        Context Window Analysis:
        
        Model: \(selectedModel.rawValue)
        Context Window Size: \(selectedModel.contextSize) tokens
        
        Used:
        \(includeSystemPrompt ? "- System Prompt: \(systemPromptTokens) tokens\n" : "")- User Input: \(inputTokens) tokens
        \(includeResponseTokens ? "- Expected Response: \(outputTokens) tokens\n" : "")
        Total Used: \(usedTokens) tokens (\(Int(contextUtilizationPercentage))%)
        Remaining: \(remainingContextTokens) tokens
        
        Status: \(statusMessage.message)
        
        Generated with LLM Buddy
        """
        
        let activityVC = UIActivityViewController(activityItems: [details], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func loadSavedVisualization(_ visualization: SavedVisualization) {
        selectedModel = visualization.model
        inputTokens > 0 ? inputText = generatePlaceholderText(tokens: visualization.inputTokens) : nil
        
        if visualization.systemTokens > 0 {
            includeSystemPrompt = true
            systemPrompt = generatePlaceholderText(tokens: visualization.systemTokens)
        } else {
            includeSystemPrompt = false
        }
        
        if visualization.responseTokens > 0 {
            includeResponseTokens = true
            
            // Find closest preset or use custom
            let presets = OutputSize.allCases.filter { $0 != .custom }
            if let closestPreset = presets.min(by: { abs($0.tokenCount - visualization.responseTokens) < abs($1.tokenCount - visualization.responseTokens) }),
               abs(closestPreset.tokenCount - visualization.responseTokens) < 200 {
                expectedOutputSize = closestPreset
            } else {
                expectedOutputSize = .custom
                customOutputTokens = visualization.responseTokens
            }
        } else {
            includeResponseTokens = false
        }
    }
    
    private func generatePlaceholderText(tokens: Int) -> String {
        // Average English word is ~5 characters, and ~0.75 tokens
        // So 1 token is ~6.7 characters
        let characterCount = tokens * 6
        let words = ["lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit", 
                    "sed", "do", "eiusmod", "tempor", "incididunt", "ut", "labore", "et", "dolore", 
                    "magna", "aliqua", "enim", "ad", "minim", "veniam", "quis", "nostrud", 
                    "exercitation", "ullamco", "laboris", "nisi", "ut", "aliquip", "ex", "ea", 
                    "commodo", "consequat"]
        
        var result = ""
        var currentLength = 0
        
        while currentLength < characterCount {
            let randomWord = words.randomElement() ?? "lorem"
            result += result.isEmpty ? randomWord : " \(randomWord)"
            currentLength += randomWord.count + 1
            
            // Add paragraph breaks occasionally
            if result.count > 300 && result.count % 300 < 20 {
                result += "\n\n"
                currentLength += 2
            }
        }
        
        return result
    }
}

// MARK: - Supporting Views

struct SaveVisualizationView: View {
    @Binding var isPresented: Bool
    @Binding var saveName: String
    @Binding var savedVisualizations: [ContextWindowVisualizerView.SavedVisualization]
    let currentVisualization: ContextWindowVisualizerView.SavedVisualization
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Save this visualization for future reference.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Visualization Name", text: $saveName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                
                // Visualization summary
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Model:")
                        Spacer()
                        Text("\(currentVisualization.model.rawValue)")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Total Context Size:")
                        Spacer()
                        Text("\(currentVisualization.contextSize) tokens")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Used Tokens:")
                        Spacer()
                        Text("\(currentVisualization.systemTokens + currentVisualization.inputTokens + currentVisualization.responseTokens) tokens")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Utilization:")
                        Spacer()
                        let percentage = Double(currentVisualization.systemTokens + currentVisualization.inputTokens + currentVisualization.responseTokens) / Double(currentVisualization.contextSize) * 100
                        Text("\(Int(percentage))%")
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                
                Spacer()
                
                Button(action: {
                    saveVisualization()
                }) {
                    Text("Save Visualization")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(saveName.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(saveName.isEmpty)
            }
            .padding()
            .navigationBarTitle("Save Visualization", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    isPresented = false
                }
            )
        }
    }
    
    private func saveVisualization() {
        // Create a new saved visualization with the provided name
        let newSavedVisualization = ContextWindowVisualizerView.SavedVisualization(
            name: saveName,
            model: currentVisualization.model,
            inputTokens: currentVisualization.inputTokens,
            systemTokens: currentVisualization.systemTokens,
            responseTokens: currentVisualization.responseTokens,
            contextSize: currentVisualization.contextSize,
            date: Date()
        )
        
        // Add to the array
        savedVisualizations.append(newSavedVisualization)
        
        // In a real app, you would save this to persistent storage here
        
        // Reset name and dismiss
        saveName = ""
        isPresented = false
    }
}

struct SavedVisualizationsView: View {
    @Binding var isPresented: Bool
    @Binding var savedVisualizations: [ContextWindowVisualizerView.SavedVisualization]
    let onSelect: (ContextWindowVisualizerView.SavedVisualization) -> Void
    
    @State private var showingDeleteAlert = false
    @State private var visualizationToDelete: UUID? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if savedVisualizations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "square.stack.3d.up.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Saved Visualizations")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Save your visualizations to reference them later.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    List {
                        ForEach(savedVisualizations) { visualization in
                            Button(action: {
                                onSelect(visualization)
                                isPresented = false
                            }) {
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(visualization.name)
                                            .font(.headline)
                                        
                                        Spacer()
                                        
                                        Text(formattedDate(visualization.date))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Text(visualization.model.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        let usedTokens = visualization.systemTokens + visualization.inputTokens + visualization.responseTokens
                                        let percentage = Double(usedTokens) / Double(visualization.contextSize) * 100
                                        
                                        Text("\(usedTokens) tokens (\(Int(percentage))%)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // Visual representation
                                    GeometryReader { geometry in
                                        HStack(spacing: 0) {
                                            // System prompt
                                            if visualization.systemTokens > 0 {
                                                let width = (Double(visualization.systemTokens) / Double(visualization.contextSize)) * geometry.size.width
                                                Rectangle()
                                                    .fill(Color.purple)
                                                    .frame(width: max(1, width))
                                            }
                                            
                                            // User input
                                            if visualization.inputTokens > 0 {
                                                let width = (Double(visualization.inputTokens) / Double(visualization.contextSize)) * geometry.size.width
                                                Rectangle()
                                                    .fill(Color.blue)
                                                    .frame(width: max(1, width))
                                            }
                                            
                                            // Response
                                            if visualization.responseTokens > 0 {
                                                let width = (Double(visualization.responseTokens) / Double(visualization.contextSize)) * geometry.size.width
                                                Rectangle()
                                                    .fill(Color.green)
                                                    .frame(width: max(1, width))
                                            }
                                            
                                            // Remaining
                                            let remainingTokens = visualization.contextSize - (visualization.systemTokens + visualization.inputTokens + visualization.responseTokens)
                                            if remainingTokens > 0 {
                                                let width = (Double(remainingTokens) / Double(visualization.contextSize)) * geometry.size.width
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: max(1, width))
                                            }
                                        }
                                        .frame(height: 8)
                                        .cornerRadius(4)
                                    }
                                    .frame(height: 8)
                                    .padding(.top, 5)
                                }
                                .padding(.vertical, 5)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button(role: .destructive, action: {
                                    visualizationToDelete = visualization.id
                                    showingDeleteAlert = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { indexSet in
                            savedVisualizations.remove(atOffsets: indexSet)
                            // In a real app, you would update persistent storage here
                        }
                    }
                }
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Visualization"),
                    message: Text("Are you sure you want to delete this saved visualization?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let id = visualizationToDelete,
                           let index = savedVisualizations.firstIndex(where: { $0.id == id }) {
                            savedVisualizations.remove(at: index)
                            // In a real app, you would update persistent storage here
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .navigationBarTitle("Saved Visualizations", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Extensions

extension Int {
    func formattedWithCommas() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - Preview

struct ContextWindowVisualizerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContextWindowVisualizerView()
        }
    }
}
