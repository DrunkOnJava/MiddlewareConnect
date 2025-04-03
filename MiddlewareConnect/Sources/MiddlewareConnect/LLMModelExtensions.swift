/**
@fileoverview LLM Model Extensions
@module LLMModelExtensions
Created: 2025-04-02
Last Modified: 2025-04-02
Dependencies:
- Foundation
Exports:
- LLMModel Extensions
/

import Foundation
import SwiftUI

// Add the claudeSonnet model reference
extension LLMModel {
    static var claudeSonnet: LLMModel {
        LLMModel(
            name: "Claude 3.5 Sonnet",
            provider: .anthropic,
            modelId: "claude-3-5-sonnet-20250307",
            contextSize: 200000,
            capabilities: [.chat, .codeGeneration, .reasoning]
        )
    }
}
