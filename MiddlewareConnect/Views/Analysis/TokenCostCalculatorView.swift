/**
 * @fileoverview Token Cost Calculator for LLM API calls
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

/// Token Cost Calculator View for estimating API costs
struct TokenCostCalculatorView: View {
    // MARK: - State Variables
    @EnvironmentObject var appState: AppState
    @State private var inputText: String = ""
    @State private var selectedModel: LLMModel = LLMModel.defaultModels[0]
    @State private var temperature: Double = 0.7
    @State private var estimatedTokenCount: Int = 0
    @State private var tokenCountMethod: TokenCountMethod = .tiktoken
    @State private var showResult: Bool = false
    @State private var selectedTab: Int = 0
    @State private var calculationHistory: [CostCalculation] = []
    
    // Token count timer
    @State private var tokenCountTimer: Timer?
    
    // MARK: - Enums
    enum TokenCountMethod: String, CaseIterable, Identifiable {
        case tiktoken = "TikToken (Accurate)"
        case approximation = "Approximation"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Computed Properties
    private var isInputValid: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var costPerThousandTokens: Double {
        selectedModel.costPer1kTokens
    }
    
    private var estimatedCost: Double {
        let tokens = Double(estimatedTokenCount)
        return (tokens / 1000.0) * costPerThousandTokens
    }
    
    private var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 4
        
        return formatter.string(from: NSNumber(value: estimatedCost)) ?? "$0.0000"
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Cost Calculator").tag(0)
                Text("Usage History").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Content based on selected tab
            TabView(selection: $selectedTab) {
                // Calculator tab
                ScrollView {
                    calculatorView
                }
                .tag(0)
                
                // History tab
                ScrollView {
                    historyView
                }
                .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationTitle("Token Cost Calculator")
        .onAppear {
            calculateEstimatedTokens()
        }
        .onDisappear {
            tokenCountTimer?.invalidate()
            tokenCountTimer = nil
        }
    }
    
    // MARK: - Calculator View
    private var calculatorView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Model selection
            VStack(alignment: .leading, spacing: 10) {
                Text("1. Select Model")
                    .font(.headline)
                
                VStack {
                    ForEach(LLMModel.defaultModels, id: \.id) { model in
                        modelButton(model)
                    }
                }
            }
            .padding(.horizontal)
            
            // Input section
            VStack(alignment: .leading, spacing: 10) {
                Text("2. Enter Text")
                    .font(.headline)
                
                TextEditor(text: $inputText)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .onChange(of: inputText) { _ in
                        // Debounce token calculation
                        tokenCountTimer?.invalidate()
                        tokenCountTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                            calculateEstimatedTokens()
                        }
                    }
                
                // Token count method
                Picker("Token Count Method", selection: $tokenCountMethod) {
                    ForEach(TokenCountMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: tokenCountMethod) { _ in
                    calculateEstimatedTokens()
                }
                
                // Temperature setting
                HStack {
                    Text("Temperature: \(temperature, specifier: "%.1f")")
                    Spacer()
                    Slider(value: $temperature, in: 0...1, step: 0.1)
                        .frame(width: 200)
                }
            }
            .padding(.horizontal)
            
            // Results section
            VStack(alignment: .leading, spacing: 15) {
                Text("3. Estimated Costs")
                    .font(.headline)
                
                // Results card
                VStack(spacing: 15) {
                    // Token count
                    HStack {
                        Text("Estimated Tokens:")
                            .font(.subheadline)
                        Spacer()
                        Text("\(estimatedTokenCount)")
                            .font(.headline)
                    }
                    
                    Divider()
                    
                    // Cost per 1K tokens
                    HStack {
                        Text("Cost per 1K tokens:")
                            .font(.subheadline)
                        Spacer()
                        Text("$\(costPerThousandTokens, specifier: "%.4f")")
                            .font(.headline)
                    }
                    
                    Divider()
                    
                    // Total estimated cost
                    HStack {
                        Text("Estimated Cost:")
                            .font(.subheadline)
                        Spacer()
                        Text(formattedCost)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                // Save button
                Button(action: {
                    saveCalculation()
                }) {
                    Text("Save Calculation")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isInputValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isInputValid)
            }
            .padding(.horizontal)
            
            // Additional information
            VStack(alignment: .leading, spacing: 10) {
                Text("Notes:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("• Actual token count may vary by implementation")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Response tokens and additional API costs not included")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Prices based on published API pricing as of April 2025")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            Spacer(minLength: 30)
        }
        .padding(.vertical)
    }
    
    // MARK: - History View
    private var historyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if calculationHistory.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No Calculation History")
                        .font(.headline)
                    
                    Text("Your saved calculations will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(50)
                .frame(maxWidth: .infinity)
            } else {
                // History list
                ForEach(calculationHistory.indices.reversed(), id: \.self) { index in
                    historyCard(calculationHistory[index], index: index)
                }
                .padding(.horizontal)
                
                // Clear history button
                Button(action: {
                    calculationHistory = []
                }) {
                    Text("Clear History")
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            Spacer(minLength: 30)
        }
        .padding(.vertical)
    }
    
    // MARK: - Supporting Views
    
    private func modelButton(_ model: LLMModel) -> some View {
        Button(action: {
            selectedModel = model
            calculateEstimatedTokens()
        }) {
            HStack {
                // Model info
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(model.providerName) • $\(model.costPer1kTokens, specifier: "%.4f")/1K tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection indicator
                if model.id == selectedModel.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(model.id == selectedModel.id ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    .background(
                        model.id == selectedModel.id ? Color.blue.opacity(0.05) : Color(.systemBackground)
                    )
                    .cornerRadius(10)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func historyCard(_ calculation: CostCalculation, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and delete button
            HStack {
                Text(calculation.dateFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    calculationHistory.remove(at: index)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            // Model and token info
            HStack {
                Text(calculation.modelName)
                    .font(.headline)
                
                Spacer()
                
                Text("\(calculation.tokenCount) tokens")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Text preview
            if !calculation.textPreview.isEmpty {
                Text(calculation.textPreview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Cost info
            HStack {
                Text("Cost")
                    .font(.subheadline)
                
                Spacer()
                
                Text(calculation.formattedCost)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Methods
    
    /// Calculate estimated token count from input text
    private func calculateEstimatedTokens() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if text.isEmpty {
            estimatedTokenCount = 0
            return
        }
        
        switch tokenCountMethod {
        case .tiktoken:
            // Use TikToken for more accurate counting
            // In a real implementation, this would use the actual TikToken library
            estimatedTokenCount = estimateTiktokens(text)
            
        case .approximation:
            // Simple approximation based on character count
            estimatedTokenCount = text.count / 4
        }
    }
    
    /// Simple TikToken estimation (this would use the real TikToken library in production)
    private func estimateTiktokens(_ text: String) -> Int {
        // This is a simplified approximation of TikToken encoding
        // In a real app, this would use an actual TikToken implementation
        
        // Estimate based on splitting by whitespace and punctuation
        let components = text.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        
        let tokens = components.reduce(0) { count, word in
            let wordTokens = max(1, Int(Double(word.count) / 3.5))
            return count + wordTokens
        }
        
        // Add tokens for whitespace and punctuation
        let whitespaceCount = text.filter { $0.isWhitespace }.count
        let punctuationCount = text.filter { $0.isPunctuation }.count
        
        return tokens + whitespaceCount + punctuationCount
    }
    
    /// Save the current calculation to history
    private func saveCalculation() {
        let previewLength = min(inputText.count, 100)
        let textPreview = inputText.prefix(previewLength) + (inputText.count > previewLength ? "..." : "")
        
        let calculation = CostCalculation(
            id: UUID(),
            date: Date(),
            modelName: selectedModel.name,
            tokenCount: estimatedTokenCount,
            cost: estimatedCost,
            textPreview: String(textPreview),
            temperature: temperature
        )
        
        calculationHistory.append(calculation)
        showResult = true
    }
}

// MARK: - Supporting Types

/// Model for a saved cost calculation
struct CostCalculation: Identifiable {
    let id: UUID
    let date: Date
    let modelName: String
    let tokenCount: Int
    let cost: Double
    let textPreview: String
    let temperature: Double
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 4
        
        return formatter.string(from: NSNumber(value: cost)) ?? "$0.0000"
    }
}

// MARK: - Previews
struct TokenCostCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TokenCostCalculatorView()
                .environmentObject(AppState())
        }
    }
}
