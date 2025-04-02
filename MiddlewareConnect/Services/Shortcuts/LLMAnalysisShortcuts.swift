import Foundation
import UIKit

/// Handler for token cost calculation shortcuts
class TokenCostCalculatorShortcutHandler: LLMAnalysisShortcutHandler {
    let shortcutType: ShortcutsManager.ShortcutType = .tokenCostCalculator
    
    func handle(parameters: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        // Get the parameters
        guard let text = parameters["text"] as? String,
              let model = parameters["model"] as? String else {
            completion(false, nil)
            return
        }
        
        // Estimate token count and cost
        // Simple estimate: ~4 characters per token
        let estimatedTokenCount = max(1, Int(Double(text.count) / 4.0))
        
        // Determine token cost based on the model
        var inputCostPer1KTokens: Double = 0.0
        var outputCostPer1KTokens: Double = 0.0
        var contextWindow: Int = 0
        var modelDisplayName = model
        
        switch model.lowercased() {
        case "claude", "claude-3", "claude-3-opus", "opus":
            inputCostPer1KTokens = 15.0
            outputCostPer1KTokens = 75.0
            contextWindow = 200000
            modelDisplayName = "Claude 3 Opus"
        case "claude-3-sonnet", "sonnet":
            inputCostPer1KTokens = 3.0
            outputCostPer1KTokens = 15.0
            contextWindow = 180000
            modelDisplayName = "Claude 3 Sonnet"
        case "claude-3-haiku", "haiku":
            inputCostPer1KTokens = 0.25
            outputCostPer1KTokens = 1.25
            contextWindow = 150000
            modelDisplayName = "Claude 3 Haiku"
        case "gpt-4", "gpt4":
            inputCostPer1KTokens = 10.0
            outputCostPer1KTokens = 30.0
            contextWindow = 8192
            modelDisplayName = "GPT-4"
        case "gpt-3.5", "gpt3.5", "gpt-3.5-turbo":
            inputCostPer1KTokens = 0.5
            outputCostPer1KTokens = 1.5
            contextWindow = 4096
            modelDisplayName = "GPT-3.5 Turbo"
        default:
            // Default to Claude 3 Sonnet if unknown
            inputCostPer1KTokens = 3.0
            outputCostPer1KTokens = 15.0
            contextWindow = 180000
            modelDisplayName = "Claude 3 Sonnet (default)"
        }
        
        // Calculate cost in cents (assuming this is just the input cost)
        let inputCostCents = Double(estimatedTokenCount) / 1000.0 * inputCostPer1KTokens
        
        // Assume a response of 20% the size of the input
        let estimatedOutputTokens = max(1, Int(Double(estimatedTokenCount) * 0.2))
        let outputCostCents = Double(estimatedOutputTokens) / 1000.0 * outputCostPer1KTokens
        
        // Total cost
        let totalCostCents = inputCostCents + outputCostCents
        
        // Context window usage percentage
        let contextUsage = min(100.0, Double(estimatedTokenCount) / Double(contextWindow) * 100.0)
        
        // Create the result
        let resultDict: [String: Any] = [
            "model": modelDisplayName,
            "inputTokens": estimatedTokenCount,
            "outputTokens": estimatedOutputTokens,
            "totalTokens": estimatedTokenCount + estimatedOutputTokens,
            "inputCostCents": inputCostCents,
            "outputCostCents": outputCostCents,
            "totalCostCents": totalCostCents,
            "contextWindowSize": contextWindow,
            "contextUsagePercent": contextUsage
        ]
        
        // Store the result in UserDefaults
        if let resultData = try? JSONSerialization.data(withJSONObject: resultDict) {
            UserDefaults.standard.set(resultData, forKey: "last_token_calculation_result")
        }
        
        // Create a nicely formatted summary
        let summary = """
        Token Cost Calculation Summary:
        Model: \(modelDisplayName)
        Text Length: \(text.count) characters
        
        Estimated Tokens:
        - Input: \(estimatedTokenCount)
        - Output: \(estimatedOutputTokens)
        - Total: \(estimatedTokenCount + estimatedOutputTokens)
        
        Estimated Cost:
        - Input: $\(String(format: "%.4f", inputCostCents / 100.0))
        - Output: $\(String(format: "%.4f", outputCostCents / 100.0))
        - Total: $\(String(format: "%.4f", totalCostCents / 100.0))
        
        Context Window:
        - Size: \(contextWindow) tokens
        - Usage: \(String(format: "%.1f", contextUsage))%
        """
        
        // Store the formatted summary
        storeResult(summary)
        
        // Create a notification to inform the user
        showNotification(
            title: "Token Cost Calculation Complete",
            body: "Estimated cost: $\(String(format: "%.4f", totalCostCents / 100.0)) for \(estimatedTokenCount + estimatedOutputTokens) tokens",
            success: true
        )
        
        completion(true, nil)
    }
}