/**
 * @fileoverview Token Cost Calculator for estimating LLM API usage costs
 * @module TokenCostCalculatorView
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - TokenCostCalculatorView
 */

import SwiftUI
import Combine

struct TokenCostCalculatorView: View {
    // MARK: - State Variables
    @State private var inputText: String = ""
    @State private var selectedModel: LLMModel = .gpt4
    @State private var selectedModelVersion: String = ""
    @State private var inputTokenCount: Int = 0
    @State private var outputTokenCount: Int = 0
    @State private var estimatedTokens: Int = 0
    @State private var overrideEstimation: Bool = false
    @State private var manualTokenCount: Int = 0
    @State private var outputTokenRatio: Double = 0.5
    @State private var selectedCurrency: Currency = .usd
    @State private var showingModelInfo: Bool = false
    @State private var showingSaveSheet: Bool = false
    @State private var calculationName: String = ""
    @State private var savedCalculations: [SavedCalculation] = []
    @State private var showingSavedCalculations: Bool = false
    @State private var isCalculating: Bool = false
    
    // MARK: - Enums & Structs
    enum LLMModel: String, CaseIterable, Identifiable {
        case gpt4 = "GPT-4"
        case gpt35 = "GPT-3.5"
        case claude = "Claude"
        case llama = "Llama"
        case mistral = "Mistral"
        case custom = "Custom"
        
        var id: String { self.rawValue }
        
        var versions: [String] {
            switch self {
            case .gpt4:
                return ["GPT-4-turbo", "GPT-4o", "GPT-4-vision"]
            case .gpt35:
                return ["GPT-3.5-turbo", "GPT-3.5-turbo-16k"]
            case .claude:
                return ["Claude 3 Opus", "Claude 3 Sonnet", "Claude 3 Haiku", "Claude 3.5 Sonnet"]
            case .llama:
                return ["Llama 2 (7B)", "Llama 2 (13B)", "Llama 2 (70B)", "Llama 3 (8B)", "Llama 3 (70B)"]
            case .mistral:
                return ["Mistral 7B", "Mistral 8x7B"]
            case .custom:
                return ["Custom Model"]
            }
        }
    }
    
    enum Currency: String, CaseIterable, Identifiable {
        case usd = "USD"
        case eur = "EUR"
        case gbp = "GBP"
        case jpy = "JPY"
        
        var id: String { self.rawValue }
        
        var symbol: String {
            switch self {
            case .usd: return "$"
            case .eur: return "€"
            case .gbp: return "£"
            case .jpy: return "¥"
            }
        }
        
        var exchangeRate: Double {
            switch self {
            case .usd: return 1.0
            case .eur: return 0.93
            case .gbp: return 0.79
            case .jpy: return 151.28
            }
        }
    }
    
    struct ModelPricing {
        let inputPer1000Tokens: Double
        let outputPer1000Tokens: Double
        let contextWindow: Int
        let description: String
    }
    
    struct SavedCalculation: Identifiable {
        let id = UUID()
        let name: String
        let model: LLMModel
        let modelVersion: String
        let tokens: Int
        let outputTokens: Int
        let cost: Double
        let currency: Currency
        let date: Date
    }
    
    // MARK: - Computed Properties
    var currentModelPricing: ModelPricing {
        // Default pricing in USD per 1000 tokens
        let pricing: ModelPricing
        
        switch selectedModel {
        case .gpt4:
            switch selectedModelVersion {
            case "GPT-4-turbo":
                pricing = ModelPricing(
                    inputPer1000Tokens: 10.0,
                    outputPer1000Tokens: 30.0,
                    contextWindow: 128000,
                    description: "Latest GPT-4 model with improved performance and lower cost"
                )
            case "GPT-4o":
                pricing = ModelPricing(
                    inputPer1000Tokens: 5.0,
                    outputPer1000Tokens: 15.0,
                    contextWindow: 128000,
                    description: "Latest multimodal model with optimal performance balance"
                )
            case "GPT-4-vision":
                pricing = ModelPricing(
                    inputPer1000Tokens: 10.0,
                    outputPer1000Tokens: 30.0,
                    contextWindow: 128000,
                    description: "GPT-4 with image understanding capabilities"
                )
            default:
                pricing = ModelPricing(
                    inputPer1000Tokens: 10.0,
                    outputPer1000Tokens: 30.0,
                    contextWindow: 128000,
                    description: "Default GPT-4 model"
                )
            }
            
        case .gpt35:
            switch selectedModelVersion {
            case "GPT-3.5-turbo-16k":
                pricing = ModelPricing(
                    inputPer1000Tokens: 1.0,
                    outputPer1000Tokens: 2.0,
                    contextWindow: 16000,
                    description: "GPT-3.5 with expanded context window"
                )
            default:
                pricing = ModelPricing(
                    inputPer1000Tokens: 0.5,
                    outputPer1000Tokens: 1.5,
                    contextWindow: 4000,
                    description: "Cost-effective general purpose model"
                )
            }
            
        case .claude:
            switch selectedModelVersion {
            case "Claude 3 Opus":
                pricing = ModelPricing(
                    inputPer1000Tokens: 15.0,
                    outputPer1000Tokens: 75.0,
                    contextWindow: 200000,
                    description: "Anthropic's most powerful model with exceptional reasoning"
                )
            case "Claude 3 Sonnet":
                pricing = ModelPricing(
                    inputPer1000Tokens: 3.0,
                    outputPer1000Tokens: 15.0,
                    contextWindow: 200000,
                    description: "Balance of intelligence and speed"
                )
            case "Claude 3 Haiku":
                pricing = ModelPricing(
                    inputPer1000Tokens: 0.25,
                    outputPer1000Tokens: 1.25,
                    contextWindow: 200000,
                    description: "Fastest Claude model for high-throughput applications"
                )
            case "Claude 3.5 Sonnet":
                pricing = ModelPricing(
                    inputPer1000Tokens: 5.0,
                    outputPer1000Tokens: 25.0,
                    contextWindow: 200000,
                    description: "Latest Claude model with improved capabilities"
                )
            default:
                pricing = ModelPricing(
                    inputPer1000Tokens: 8.0,
                    outputPer1000Tokens: 24.0,
                    contextWindow: 100000,
                    description: "Default Claude model"
                )
            }
            
        case .llama:
            switch selectedModelVersion {
            case "Llama 2 (70B)":
                pricing = ModelPricing(
                    inputPer1000Tokens: 0.95,
                    outputPer1000Tokens: 0.95,
                    contextWindow: 4000,
                    description: "Meta's largest Llama 2 model"
                )
            case "Llama 3 (70B)":
                pricing = ModelPricing(
                    inputPer1000Tokens: 2.2,
                    outputPer1000Tokens: 2.2,
                    contextWindow: 8000,
                    description: "Meta's latest and most capable model"
                )
            default:
                pricing = ModelPricing(
                    inputPer1000Tokens: 0.2,
                    outputPer1000Tokens: 0.2,
                    contextWindow: 4000,
                    description: "Open-source model with lower costs"
                )
            }
            
        case .mistral:
            pricing = ModelPricing(
                inputPer1000Tokens: 0.7,
                outputPer1000Tokens: 0.7,
                contextWindow: 8000,
                description: "Efficient open-source model with strong performance"
            )
            
        case .custom:
            pricing = ModelPricing(
                inputPer1000Tokens: 5.0,
                outputPer1000Tokens: 5.0,
                contextWindow: 8000,
                description: "Custom model configuration"
            )
        }
        
        return pricing
    }
    
    var calculatedCost: (inputCost: Double, outputCost: Double, totalCost: Double) {
        let pricing = currentModelPricing
        
        // Token counts to use
        let tokens = overrideEstimation ? manualTokenCount : estimatedTokens
        
        // Calculate input and output token counts
        let inputTokens = inputTokenCount > 0 ? inputTokenCount : tokens
        let outputTokens = outputTokenCount > 0 ? outputTokenCount : Int(Double(tokens) * outputTokenRatio)
        
        // Calculate costs
        let inputCost = Double(inputTokens) / 1000.0 * pricing.inputPer1000Tokens
        let outputCost = Double(outputTokens) / 1000.0 * pricing.outputPer1000Tokens
        
        // Apply currency conversion
        let exchangeRate = selectedCurrency.exchangeRate
        let convertedInputCost = inputCost * exchangeRate
        let convertedOutputCost = outputCost * exchangeRate
        
        return (convertedInputCost, convertedOutputCost, convertedInputCost + convertedOutputCost)
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                    
                    Text("Token Cost Calculator")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // History button
                    Button(action: {
                        showingSavedCalculations = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 5)
                
                Text("Calculate API costs for different LLM models based on token usage")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // Model Selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Select Model")
                        .font(.headline)
                    
                    HStack {
                        Picker("Model", selection: $selectedModel) {
                            ForEach(LLMModel.allCases) { model in
                                Text(model.rawValue).tag(model)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedModel) { _ in
                            // Update selected version when model changes
                            if !selectedModel.versions.isEmpty {
                                selectedModelVersion = selectedModel.versions[0]
                            } else {
                                selectedModelVersion = ""
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showingModelInfo = true
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    // Model version selection
                    if !selectedModel.versions.isEmpty {
                        Picker("Version", selection: $selectedModelVersion) {
                            ForEach(selectedModel.versions, id: \.self) { version in
                                Text(version).tag(version)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 5)
                    }
                    
                    // Model pricing info
                    VStack(alignment: .leading, spacing: 5) {
                        Text(currentModelPricing.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 5)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Input")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(selectedCurrency.symbol)\(String(format: "%.4f", currentModelPricing.inputPer1000Tokens * selectedCurrency.exchangeRate))/1K tokens")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Output")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(selectedCurrency.symbol)\(String(format: "%.4f", currentModelPricing.outputPer1000Tokens * selectedCurrency.exchangeRate))/1K tokens")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Context")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(currentModelPricing.contextWindow.formattedWithCommas) tokens")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.vertical)
                
                // Token Input Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("2. Token Estimation")
                        .font(.headline)
                    
                    // Text input for estimation
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Enter text to estimate tokens")
                            .font(.subheadline)
                        
                        TextEditor(text: $inputText)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 100)
                            .padding(5)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .onChange(of: inputText) { _ in
                                estimateTokens()
                            }
                        
                        if !inputText.isEmpty {
                            Text("Estimated: \(estimatedTokens) tokens")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Override manual input section
                    VStack(alignment: .leading, spacing: 5) {
                        Toggle("Override with manual token count", isOn: $overrideEstimation)
                            .font(.subheadline)
                            .padding(.vertical, 5)
                        
                        if overrideEstimation {
                            HStack {
                                Text("Input tokens:")
                                
                                TextField("", value: $manualTokenCount, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            HStack {
                                Text("Input tokens:")
                                
                                TextField("", value: $inputTokenCount, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            HStack {
                                Text("Output tokens:")
                                
                                TextField("", value: $outputTokenCount, formatter: NumberFormatter())
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        } else {
                            HStack {
                                Text("Output token ratio:")
                                Spacer()
                                Text("\(Int(outputTokenRatio * 100))%")
                            }
                            
                            Slider(value: $outputTokenRatio, in: 0.1...5.0, step: 0.1)
                                .accentColor(.green)
                            
                            Text("Estimated output tokens: \(Int(Double(estimatedTokens) * outputTokenRatio))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
                .padding(.vertical)
                
                // Cost Calculation Results
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("3. Cost Calculation")
                            .font(.headline)
                        
                        Spacer()
                        
                        Picker("", selection: $selectedCurrency) {
                            ForEach(Currency.allCases) { currency in
                                Text(currency.rawValue).tag(currency)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    // Cost summary
                    VStack(spacing: 15) {
                        // Header stats
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Input Tokens")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(overrideEstimation ? inputTokenCount : estimatedTokens)")
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Output Tokens")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(overrideEstimation ? outputTokenCount : Int(Double(estimatedTokens) * outputTokenRatio))")
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Total Tokens")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                let totalTokens = overrideEstimation ? 
                                    (inputTokenCount + outputTokenCount) : 
                                    (estimatedTokens + Int(Double(estimatedTokens) * outputTokenRatio))
                                
                                Text("\(totalTokens)")
                                    .font(.title3)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                        
                        Divider()
                        
                        // Cost breakdown
                        VStack(spacing: 12) {
                            HStack {
                                Text("Input Cost")
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(selectedCurrency.symbol)\(String(format: "%.4f", calculatedCost.inputCost))")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Output Cost")
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(selectedCurrency.symbol)\(String(format: "%.4f", calculatedCost.outputCost))")
                                    .fontWeight(.medium)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total Cost")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(selectedCurrency.symbol)\(String(format: "%.4f", calculatedCost.totalCost))")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                        
                        // Action buttons
                        HStack {
                            Button(action: {
                                // Share calculation
                                let total = overrideEstimation ? 
                                    (inputTokenCount + outputTokenCount) : 
                                    (estimatedTokens + Int(Double(estimatedTokens) * outputTokenRatio))
                                
                                let message = """
                                LLM Cost Calculation:
                                Model: \(selectedModel.rawValue) (\(selectedModelVersion))
                                Input: \(overrideEstimation ? inputTokenCount : estimatedTokens) tokens @ \(selectedCurrency.symbol)\(String(format: "%.4f", currentModelPricing.inputPer1000Tokens * selectedCurrency.exchangeRate))/1K
                                Output: \(overrideEstimation ? outputTokenCount : Int(Double(estimatedTokens) * outputTokenRatio)) tokens @ \(selectedCurrency.symbol)\(String(format: "%.4f", currentModelPricing.outputPer1000Tokens * selectedCurrency.exchangeRate))/1K
                                Total tokens: \(total)
                                Total cost: \(selectedCurrency.symbol)\(String(format: "%.4f", calculatedCost.totalCost))
                                """
                                
                                let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootVC = windowScene.windows.first?.rootViewController {
                                    rootVC.present(activityVC, animated: true)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                showingSaveSheet = true
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
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
                .padding(.vertical)
                
                // Usage examples / Comparison
                if estimatedTokens > 0 || overrideEstimation {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Cost for other models:")
                            .font(.headline)
                        
                        ForEach(LLMModel.allCases.filter { $0 != selectedModel && $0 != .custom }, id: \.self) { model in
                            let pricing = getDefaultPricingFor(model: model)
                            let tokens = overrideEstimation ? manualTokenCount : estimatedTokens
                            let inputTokens = inputTokenCount > 0 ? inputTokenCount : tokens
                            let outputTokens = outputTokenCount > 0 ? outputTokenCount : Int(Double(tokens) * outputTokenRatio)
                            
                            let inputCost = Double(inputTokens) / 1000.0 * pricing.inputPer1000Tokens * selectedCurrency.exchangeRate
                            let outputCost = Double(outputTokens) / 1000.0 * pricing.outputPer1000Tokens * selectedCurrency.exchangeRate
                            let totalCost = inputCost + outputCost
                            
                            HStack {
                                Text(model.rawValue)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text("\(selectedCurrency.symbol)\(String(format: "%.4f", totalCost))")
                                    .fontWeight(.medium)
                                    .foregroundColor(totalCost < calculatedCost.totalCost ? .green : .primary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding(.vertical)
                }
            }
            .padding()
        }
        .navigationTitle("Token Calculator")
        // Sheet for model info
        .sheet(isPresented: $showingModelInfo) {
            ModelInfoView(model: selectedModel, modelVersion: selectedModelVersion)
        }
        // Sheet for saving calculation
        .sheet(isPresented: $showingSaveSheet) {
            SaveCalculationView(
                isPresented: $showingSaveSheet,
                calculationName: $calculationName,
                savedCalculations: $savedCalculations,
                currentCalculation: SavedCalculation(
                    name: "",
                    model: selectedModel,
                    modelVersion: selectedModelVersion,
                    tokens: overrideEstimation ? manualTokenCount : estimatedTokens,
                    outputTokens: overrideEstimation ? outputTokenCount : Int(Double(estimatedTokens) * outputTokenRatio),
                    cost: calculatedCost.totalCost,
                    currency: selectedCurrency,
                    date: Date()
                )
            )
        }
        // Sheet for viewing saved calculations
        .sheet(isPresented: $showingSavedCalculations) {
            SavedCalculationsView(
                isPresented: $showingSavedCalculations,
                savedCalculations: $savedCalculations
            )
        }
        .onAppear {
            // Initialize model version
            if !selectedModel.versions.isEmpty {
                selectedModelVersion = selectedModel.versions[0]
            }
            
            // Load saved calculations
            // In a production app, this would load from UserDefaults or other persistent storage
            // For this example, we'll leave the array empty
        }
    }
    
    // MARK: - Helper Methods
    
    private func estimateTokens() {
        guard !inputText.isEmpty else {
            estimatedTokens = 0
            return
        }
        
        isCalculating = true
        
        // For simplicity, we're using a very simple token estimation
        // In a real app, you'd use a more accurate tokenizer for each model
        let estimatedCount = max(1, Int(Double(inputText.count) / 4.0))
        
        // Simulate a brief calculation delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.estimatedTokens = estimatedCount
            self.isCalculating = false
        }
    }
    
    private func getDefaultPricingFor(model: LLMModel) -> ModelPricing {
        // Return default pricing for models
        switch model {
        case .gpt4:
            return ModelPricing(
                inputPer1000Tokens: 10.0,
                outputPer1000Tokens: 30.0,
                contextWindow: 128000,
                description: "Default GPT-4 model"
            )
        case .gpt35:
            return ModelPricing(
                inputPer1000Tokens: 0.5,
                outputPer1000Tokens: 1.5,
                contextWindow: 4000,
                description: "Cost-effective general purpose model"
            )
        case .claude:
            return ModelPricing(
                inputPer1000Tokens: 8.0,
                outputPer1000Tokens: 24.0,
                contextWindow: 100000,
                description: "Default Claude model"
            )
        case .llama:
            return ModelPricing(
                inputPer1000Tokens: 0.2,
                outputPer1000Tokens: 0.2,
                contextWindow: 4000,
                description: "Open-source model with lower costs"
            )
        case .mistral:
            return ModelPricing(
                inputPer1000Tokens: 0.7,
                outputPer1000Tokens: 0.7,
                contextWindow: 8000,
                description: "Efficient open-source model with strong performance"
            )
        case .custom:
            return ModelPricing(
                inputPer1000Tokens: 5.0,
                outputPer1000Tokens: 5.0,
                contextWindow: 8000,
                description: "Custom model configuration"
            )
        }
    }
}

// MARK: - Supporting Views

struct ModelInfoView: View {
    let model: TokenCostCalculatorView.LLMModel
    let modelVersion: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Model header
                    HStack {
                        VStack(alignment: .leading) {
                            Text(model.rawValue)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text(modelVersion)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Model icon
                        Image(systemName: modelIcon)
                            .font(.system(size: 40))
                            .foregroundColor(modelColor)
                            .frame(width: 80, height: 80)
                            .background(modelColor.opacity(0.2))
                            .cornerRadius(20)
                    }
                    
                    // Model description
                    Text(modelDescription)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    
                    // Model specs
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Model Specifications")
                            .font(.headline)
                        
                        ForEach(modelSpecs, id: \.title) { spec in
                            HStack(alignment: .top) {
                                Image(systemName: spec.icon)
                                    .frame(width: 24)
                                    .foregroundColor(modelColor)
                                
                                VStack(alignment: .leading) {
                                    Text(spec.title)
                                        .fontWeight(.medium)
                                    
                                    Text(spec.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    // Usage recommendations
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Best Used For")
                            .font(.headline)
                        
                        ForEach(usageCases, id: \.self) { useCase in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                
                                Text(useCase)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    
                    // Pricing section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Pricing Information")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Input cost:")
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text("$\(String(format: "%.4f", modelInputCost))/1K tokens")
                            }
                            
                            HStack {
                                Text("Output cost:")
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text("$\(String(format: "%.4f", modelOutputCost))/1K tokens")
                            }
                            
                            HStack {
                                Text("Context window:")
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text("\(modelContextWindow) tokens")
                            }
                            
                            Divider()
                            
                            Text("*Pricing is subject to change. Check the provider's website for the most current pricing.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationBarTitle("Model Information", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // MARK: - Computed Properties
    
    var modelIcon: String {
        switch model {
        case .gpt4: return "cpu"
        case .gpt35: return "server.rack"
        case .claude: return "bubble.left.and.bubble.right"
        case .llama: return "hare"
        case .mistral: return "wind"
        case .custom: return "gearshape.2"
        }
    }
    
    var modelColor: Color {
        switch model {
        case .gpt4: return Color.blue
        case .gpt35: return Color.green
        case .claude: return Color.purple
        case .llama: return Color.orange
        case .mistral: return Color.cyan
        case .custom: return Color.gray
        }
    }
    
    var modelDescription: String {
        switch model {
        case .gpt4:
            return "GPT-4 is OpenAI's most advanced large language model, offering improved accuracy, creativity, and reasoning capabilities compared to previous versions. It's a multimodal model that can understand both text and images."
        case .gpt35:
            return "GPT-3.5 offers a good balance between performance and cost, making it well-suited for a wide range of applications. It's a cost-effective option for many general-purpose AI tasks."
        case .claude:
            return "Claude is Anthropic's family of language models, designed to be helpful, harmless, and honest. Claude models excel at thoughtful dialogue, content creation, and complex reasoning."
        case .llama:
            return "Llama is Meta's open-source large language model designed to be accessible for research and commercial applications. It offers competitive performance while being more accessible than proprietary alternatives."
        case .mistral:
            return "Mistral is an efficient open-source large language model that delivers strong performance across various tasks while being more computationally efficient than many comparable models."
        case .custom:
            return "Custom model configuration for specialized use cases with customized pricing and capabilities."
        }
    }
    
    var modelSpecs: [(title: String, description: String, icon: String)] {
        switch model {
        case .gpt4:
            return [
                ("Training Data", "Trained on data up to April 2023", "calendar"),
                ("Parameter Count", "Estimated >1 trillion parameters", "cpu.fill"),
                ("Max Context Length", "Varies by model version, up to 128K tokens", "text.magnifyingglass"),
                ("Provider", "OpenAI", "building.2")
            ]
        case .gpt35:
            return [
                ("Training Data", "Trained on data up to January 2022", "calendar"),
                ("Parameter Count", "Estimated 175 billion parameters", "cpu.fill"),
                ("Max Context Length", "Varies by model version, 4K-16K tokens", "text.magnifyingglass"),
                ("Provider", "OpenAI", "building.2")
            ]
        case .claude:
            return [
                ("Training Data", "Trained on data up to late 2023", "calendar"),
                ("Parameter Count", "Not publicly disclosed", "cpu.fill"),
                ("Max Context Length", "Up to 200K tokens (Claude 3)", "text.magnifyingglass"),
                ("Provider", "Anthropic", "building.2")
            ]
        case .llama:
            return [
                ("Training Data", "Trained on publicly available data", "calendar"),
                ("Parameter Count", "Varies by model (7B to 70B parameters)", "cpu.fill"),
                ("Max Context Length", "4K-8K tokens depending on version", "text.magnifyingglass"),
                ("Provider", "Meta", "building.2")
            ]
        case .mistral:
            return [
                ("Training Data", "Not fully disclosed", "calendar"),
                ("Parameter Count", "7B to 8x7B parameters", "cpu.fill"),
                ("Max Context Length", "8K tokens", "text.magnifyingglass"),
                ("Provider", "Mistral AI", "building.2")
            ]
        case .custom:
            return [
                ("Training Data", "Custom dataset", "calendar"),
                ("Parameter Count", "Varies", "cpu.fill"),
                ("Max Context Length", "Configurable", "text.magnifyingglass"),
                ("Provider", "Various", "building.2")
            ]
        }
    }
    
    var usageCases: [String] {
        switch model {
        case .gpt4:
            return [
                "Complex reasoning and problem solving",
                "Creative content generation",
                "Understanding and generating code",
                "Research assistance",
                "Image understanding (vision-enabled versions)"
            ]
        case .gpt35:
            return [
                "General conversational AI",
                "Content summarization",
                "Basic customer support",
                "Content creation",
                "Cost-effective high-volume applications"
            ]
        case .claude:
            return [
                "Thoughtful, nuanced conversations",
                "Content analysis and creation",
                "Complex reasoning with factuality",
                "Research support",
                "Handling long documents with context"
            ]
        case .llama:
            return [
                "On-device applications",
                "Privacy-sensitive use cases",
                "Research applications",
                "Cost-effective deployment",
                "Applications requiring model customization"
            ]
        case .mistral:
            return [
                "Efficient AI applications",
                "Conversational AI",
                "General language understanding",
                "Limited-resource environments",
                "Applications requiring open-source models"
            ]
        case .custom:
            return [
                "Domain-specific applications",
                "Specialized use cases",
                "Tasks requiring custom model training",
                "Proprietary applications",
                "Research projects"
            ]
        }
    }
    
    var modelInputCost: Double {
        switch model {
        case .gpt4: return modelVersion.contains("turbo") ? 10.0 : 30.0
        case .gpt35: return modelVersion.contains("16k") ? 1.0 : 0.5
        case .claude: 
            if modelVersion.contains("Opus") {
                return 15.0
            } else if modelVersion.contains("Sonnet") {
                return modelVersion.contains("3.5") ? 5.0 : 3.0
            } else {
                return 0.25 // Haiku
            }
        case .llama: return modelVersion.contains("70B") ? 0.95 : 0.2
        case .mistral: return 0.7
        case .custom: return 5.0
        }
    }
    
    var modelOutputCost: Double {
        switch model {
        case .gpt4: return modelVersion.contains("turbo") ? 30.0 : 60.0
        case .gpt35: return modelVersion.contains("16k") ? 2.0 : 1.5
        case .claude:
            if modelVersion.contains("Opus") {
                return 75.0
            } else if modelVersion.contains("Sonnet") {
                return modelVersion.contains("3.5") ? 25.0 : 15.0
            } else {
                return 1.25 // Haiku
            }
        case .llama: return modelVersion.contains("70B") ? 0.95 : 0.2
        case .mistral: return 0.7
        case .custom: return 5.0
        }
    }
    
    var modelContextWindow: Int {
        switch model {
        case .gpt4: return 128000
        case .gpt35: return modelVersion.contains("16k") ? 16000 : 4000
        case .claude: return 200000
        case .llama: return modelVersion.contains("3") ? 8000 : 4000
        case .mistral: return 8000
        case .custom: return 8000
        }
    }
}

struct SaveCalculationView: View {
    @Binding var isPresented: Bool
    @Binding var calculationName: String
    @Binding var savedCalculations: [TokenCostCalculatorView.SavedCalculation]
    let currentCalculation: TokenCostCalculatorView.SavedCalculation
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Save this calculation for future reference.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Calculation Name", text: $calculationName)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                
                // Calculation summary
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Model:")
                        Spacer()
                        Text("\(currentCalculation.model.rawValue) (\(currentCalculation.modelVersion))")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Total Tokens:")
                        Spacer()
                        Text("\(currentCalculation.tokens + currentCalculation.outputTokens)")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Cost:")
                        Spacer()
                        Text("\(currentCalculation.currency.symbol)\(String(format: "%.4f", currentCalculation.cost))")
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                
                Spacer()
                
                Button(action: {
                    saveCalculation()
                }) {
                    Text("Save Calculation")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(calculationName.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(calculationName.isEmpty)
            }
            .padding()
            .navigationBarTitle("Save Calculation", displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    isPresented = false
                }
            )
        }
    }
    
    private func saveCalculation() {
        // Create a new saved calculation with the provided name
        let newSavedCalculation = TokenCostCalculatorView.SavedCalculation(
            name: calculationName,
            model: currentCalculation.model,
            modelVersion: currentCalculation.modelVersion,
            tokens: currentCalculation.tokens,
            outputTokens: currentCalculation.outputTokens,
            cost: currentCalculation.cost,
            currency: currentCalculation.currency,
            date: Date()
        )
        
        // Add to the array
        savedCalculations.append(newSavedCalculation)
        
        // In a real app, you would save this to persistent storage here
        
        // Reset name and dismiss
        calculationName = ""
        isPresented = false
    }
}

struct SavedCalculationsView: View {
    @Binding var isPresented: Bool
    @Binding var savedCalculations: [TokenCostCalculatorView.SavedCalculation]
    @State private var showingDeleteAlert = false
    @State private var calculationToDelete: UUID? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if savedCalculations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Saved Calculations")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Save your calculations to reference them later.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    List {
                        ForEach(savedCalculations) { calculation in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(calculation.name)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text(formattedDate(calculation.date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("\(calculation.model.rawValue) (\(calculation.modelVersion))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(calculation.tokens + calculation.outputTokens) tokens")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Spacer()
                                    
                                    Text("\(calculation.currency.symbol)\(String(format: "%.4f", calculation.cost))")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 5)
                            .contextMenu {
                                Button(role: .destructive, action: {
                                    calculationToDelete = calculation.id
                                    showingDeleteAlert = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { indexSet in
                            savedCalculations.remove(atOffsets: indexSet)
                            // In a real app, you would update persistent storage here
                        }
                    }
                }
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Delete Calculation"),
                    message: Text("Are you sure you want to delete this saved calculation?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let id = calculationToDelete, 
                           let index = savedCalculations.firstIndex(where: { $0.id == id }) {
                            savedCalculations.remove(at: index)
                            // In a real app, you would update persistent storage here
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .navigationBarTitle("Saved Calculations", displayMode: .inline)
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
    var formattedWithCommas: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - Preview

struct TokenCostCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TokenCostCalculatorView()
        }
    }
}
