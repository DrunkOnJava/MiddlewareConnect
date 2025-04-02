/**
 * @fileoverview Context Window Visualizer for LLM token usage
 * @module ContextWindowVisualizerView
 * 
 * Created: 2025-04-01
 * Last Modified: 2025-04-01
 * 
 * Dependencies:
 * - SwiftUI
 * 
 * Exports:
 * - ContextWindowVisualizerView
 */

import SwiftUI

/// Context Window Visualizer for understanding token usage
struct ContextWindowVisualizerView: View {
    // MARK: - State Variables
    @EnvironmentObject var appState: AppState
    @State private var inputText: String = ""
    @State private var responseText: String = ""
    @State private var instructions: String = ""
    @State private var selectedModel: LLMModel = LLMModel.defaultModels[0]
    @State private var isCalculating: Bool = false
    @State private var inputTokens: Int = 0
    @State private var responseTokens: Int = 0
    @State private var systemTokens: Int = 0
    @State private var showAdvancedOptions: Bool = false
    @State private var maxInputPercentage: Double = 70
    @State private var tokenOverhead: Int = 5
    
    // MARK: - Computed Properties
    private var totalEstimatedTokens: Int {
        inputTokens + responseTokens + systemTokens
    }
    
    private var contextWindowSize: Int {
        selectedModel.contextWindow
    }
    
    private var percentageUsed: Double {
        Double(totalEstimatedTokens) / Double(contextWindowSize) * 100.0
    }
    
    private var tokenUsageColor: Color {
        if percentageUsed < 70 {
            return .green
        } else if percentageUsed < 90 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var inputPercentageOfTotal: Double {
        guard totalEstimatedTokens > 0 else { return 0 }
        return Double(inputTokens) / Double(totalEstimatedTokens) * 100.0
    }
    
    private var responsePercentageOfTotal: Double {
        guard totalEstimatedTokens > 0 else { return 0 }
        return Double(responseTokens) / Double(totalEstimatedTokens) * 100.0
    }
    
    private var systemPercentageOfTotal: Double {
        guard totalEstimatedTokens > 0 else { return 0 }
        return Double(systemTokens) / Double(totalEstimatedTokens) * 100.0
    }
    
    private var maxResponseTokens: Int {
        let availableTokens = contextWindowSize - inputTokens - systemTokens - tokenOverhead
        return max(0, availableTokens)
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Context Window Visualizer")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Understand token usage distribution within LLM context windows")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Model selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Select Model")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(LLMModel.defaultModels, id: \.id) { model in
                                modelButton(model)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Input fields
                VStack(alignment: .leading, spacing: 15) {
                    Text("2. Message Content")
                        .font(.headline)
                    
                    // System instructions field
                    VStack(alignment: .leading) {
                        HStack {
                            Text("System Instructions")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(systemTokens) tokens")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        TextEditor(text: $instructions)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .onChange(of: instructions) { _ in
                                calculateTokens()
                            }
                    }
                    
                    // User input field
                    VStack(alignment: .leading) {
                        HStack {
                            Text("User Message")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(inputTokens) tokens")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        TextEditor(text: $inputText)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .onChange(of: inputText) { _ in
                                calculateTokens()
                            }
                    }
                    
                    // Response estimate field
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Expected Response (est.)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(responseTokens) tokens")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        TextEditor(text: $responseText)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .onChange(of: responseText) { _ in
                                calculateTokens()
                            }
                    }
                }
                .padding(.horizontal)
                
                // Advanced options
                DisclosureGroup(
                    isExpanded: $showAdvancedOptions,
                    content: {
                        VStack(alignment: .leading, spacing: 10) {
                            // Input percentage slider
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Max Input Percentage")
                                    .font(.subheadline)
                                
                                HStack {
                                    Slider(value: $maxInputPercentage, in: 10...90, step: 5)
                                        .onChange(of: maxInputPercentage) { _ in
                                            calculateTokens()
                                        }
                                    
                                    Text("\(Int(maxInputPercentage))%")
                                        .font(.callout)
                                        .frame(width: 50)
                                }
                            }
                            
                            // Token overhead stepper
                            HStack {
                                Text("Token Overhead:")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Stepper("\(tokenOverhead) tokens", value: $tokenOverhead, in: 0...100, step: 5)
                                    .frame(width: 150)
                                    .onChange(of: tokenOverhead) { _ in
                                        calculateTokens()
                                    }
                            }
                        }
                        .padding(.vertical, 10)
                    },
                    label: {
                        Text("Advanced Options")
                            .font(.headline)
                    }
                )
                .padding(.horizontal)
                
                // Visualization section
                VStack(alignment: .leading, spacing: 15) {
                    Text("3. Context Window Visualization")
                        .font(.headline)
                    
                    // Progress bar visualization
                    VStack(alignment: .leading, spacing: 10) {
                        // Usage bar
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                // System tokens
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.purple.opacity(0.7))
                                    .frame(width: max(0, geometry.size.width * CGFloat(systemPercentageOfTotal / 100.0)))
                                
                                // Input tokens
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.blue.opacity(0.7))
                                    .frame(width: max(0, geometry.size.width * CGFloat(inputPercentageOfTotal / 100.0)))
                                
                                // Response tokens
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.green.opacity(0.7))
                                    .frame(width: max(0, geometry.size.width * CGFloat(responsePercentageOfTotal / 100.0)))
                                
                                // Remaining space
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: max(0, geometry.size.width * CGFloat(1.0 - percentageUsed / 100.0)))
                            }
                            .frame(height: 24)
                            .cornerRadius(8)
                        }
                        .frame(height: 24)
                        
                        // Legend
                        HStack(spacing: 12) {
                            // System
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.purple.opacity(0.7))
                                    .frame(width: 12, height: 12)
                                
                                Text("System")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Input
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.7))
                                    .frame(width: 12, height: 12)
                                
                                Text("Input")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Response
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green.opacity(0.7))
                                    .frame(width: 12, height: 12)
                                
                                Text("Response")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Available
                            HStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 12, height: 12)
                                
                                Text("Available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Token statistics
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Tokens")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("\(totalEstimatedTokens)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Context Window")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("\(contextWindowSize)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Used")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("\(Int(percentageUsed))%")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(tokenUsageColor)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Max Response")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text("\(maxResponseTokens)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Distribution breakdown
                if totalEstimatedTokens > 0 {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Token Distribution")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 15) {
                            // System tokens
                            HStack {
                                Text("System Instructions")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(systemTokens) tokens")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("(\(Int(systemPercentageOfTotal))%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            // Input tokens
                            HStack {
                                Text("User Input")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(inputTokens) tokens")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("(\(Int(inputPercentageOfTotal))%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            // Response tokens
                            HStack {
                                Text("Expected Response")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(responseTokens) tokens")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("(\(Int(responsePercentageOfTotal))%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            Divider()
                                .padding(.horizontal)
                            
                            // Available tokens
                            HStack {
                                Text("Available Space")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(contextWindowSize - totalEstimatedTokens) tokens")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("(\(Int(100 - percentageUsed))%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                // Token calculation notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("• Token counts are estimates and may vary by implementation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Actual response lengths may differ from estimates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Some models reserve tokens for internal processing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .navigationTitle("Context Visualizer")
        .onAppear {
            // Initialize with default content
            instructions = "You are a helpful AI assistant that provides concise and accurate information."
            inputText = "What are the key differences between fine-tuning and prompt engineering for LLMs?"
            responseText = "Fine-tuning and prompt engineering are two different approaches to customizing LLM behavior. Fine-tuning involves retraining the model on specific data to adapt its weights and behavior. This requires computational resources but creates persistent model changes. Prompt engineering is about crafting effective instructions within the input text to guide the model's response, without changing the model itself. It's more accessible but may be less consistent for complex tasks."
            
            calculateTokens()
        }
    }
    
    // MARK: - Supporting Views
    
    private func modelButton(_ model: LLMModel) -> some View {
        Button(action: {
            selectedModel = model
            calculateTokens()
        }) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(model.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer(minLength: 4)
                    
                    if model.id == selectedModel.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Text("\(model.contextWindow) tokens")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(minWidth: 150)
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
    
    // MARK: - Methods
    
    /// Calculate token counts for all text inputs
    private func calculateTokens() {
        isCalculating = true
        
        // Estimate system tokens
        systemTokens = estimateTokenCount(instructions)
        
        // Estimate input tokens
        inputTokens = estimateTokenCount(inputText)
        
        // Estimate response tokens
        responseTokens = responseText.isEmpty ? estimateResponseTokens() : estimateTokenCount(responseText)
        
        isCalculating = false
    }
    
    /// Estimate token count for a given text
    private func estimateTokenCount(_ text: String) -> Int {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if text.isEmpty {
            return 0
        }
        
        // Use a simplified approximation
        // In a real app, this would use a more accurate tokenizer like tiktoken
        
        // Split by whitespace and punctuation
        let components = text.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        
        let tokens = components.reduce(0) { count, word in
            // Approximate token count (1 token ~= 4 chars)
            let wordTokens = max(1, Int(Double(word.count) / 4.0))
            return count + wordTokens
        }
        
        // Add tokens for whitespace and punctuation
        let whitespaceCount = text.filter { $0.isWhitespace }.count
        let punctuationCount = text.filter { $0.isPunctuation }.count
        
        return tokens + whitespaceCount + punctuationCount
    }
    
    /// Estimate expected response tokens based on input
    private func estimateResponseTokens() -> Int {
        // Simple heuristic: response is typically 1.5-2x the input for questions
        let baseEstimate = max(Int(Double(inputTokens) * 1.7), 100)
        
        // Ensure it doesn't exceed maximum possible response
        return min(baseEstimate, maxResponseTokens)
    }
}

// MARK: - Previews
struct ContextWindowVisualizerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContextWindowVisualizerView()
                .environmentObject(AppState())
        }
    }
}
