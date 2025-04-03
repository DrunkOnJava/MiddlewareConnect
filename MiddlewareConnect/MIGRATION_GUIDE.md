# Migration Guide: Adopting the Modular Framework

This guide provides practical examples for migrating existing code to the new modular architecture. Each section includes before/after examples to illustrate the migration process.

## Table of Contents

1. [Introduction](#introduction)
2. [Core Principles](#core-principles)
3. [Migration Patterns](#migration-patterns)
4. [LLM Service Integration](#llm-service-integration)
5. [Model Comparison Framework](#model-comparison-framework)
6. [PDF Processing](#pdf-processing)
7. [Testing Migrations](#testing-migrations)
8. [Troubleshooting](#troubleshooting)

## Introduction

The new modular architecture improves maintainability, testability, and code reuse by organizing functionality into self-contained modules with clear boundaries. This guide helps developers transition from the previous monolithic approach to the new modular structure.

## Core Principles

The modular framework is built on these principles:

1. **Encapsulation**: Modules hide their implementation details and expose only clean public interfaces.
2. **Single Responsibility**: Each module has a clearly defined purpose and scope.
3. **Dependency Management**: Modules declare explicit dependencies on other modules.
4. **Testability**: Modules are designed for easy unit testing with mock dependencies.
5. **API Stability**: Public interfaces are stable and backward-compatible.

## Migration Patterns

### Direct API Access Replacement

**Before:**
```swift
// Directly accessing internal components with implementation details exposed
func processUserPrompt(_ prompt: String) {
    let tokenizer = Tokenizer()
    let tokens = tokenizer.tokenize(prompt)
    
    let claude = ClaudeAPI(apiKey: "your_api_key")
    let parameters = ClaudeParameters(
        temperature: 0.7,
        maxTokens: 1000
    )
    
    claude.generateResponse(tokens: tokens, parameters: parameters) { result in
        switch result {
        case .success(let response):
            self.displayResponse(response.text)
        case .failure(let error):
            self.handleError(error)
        }
    }
}
```

**After:**
```swift
// Using the clean module API with implementation details hidden
import LLMServiceProvider

func processUserPrompt(_ prompt: String) {
    let service = LLMServiceProvider.shared
    
    let options = TextGenerationOptions(
        temperature: 0.7,
        maxTokens: 1000
    )
    
    Task {
        do {
            let response = try await service.generateText(
                prompt: prompt,
                model: .claude3Sonnet,
                options: options
            )
            await MainActor.run {
                self.displayResponse(response.text)
            }
        } catch {
            await MainActor.run {
                self.handleError(error)
            }
        }
    }
}
```

### Dependency Injection Adoption

**Before:**
```swift
// Hard-coded dependencies
class DocumentProcessor {
    private let claude = ClaudeAPI(apiKey: "your_api_key")
    private let tokenCounter = TokenCounter()
    
    func processDocument(_ url: URL) {
        // Implementation
    }
}
```

**After:**
```swift
// Using dependency injection for testability
import LLMServiceProvider

class DocumentProcessor {
    private let llmService: LLMService
    
    init(llmService: LLMService = LLMServiceProvider.shared) {
        self.llmService = llmService
    }
    
    func processDocument(_ url: URL) async throws -> DocumentProcessingResult {
        return try await llmService.processDocument(
            url: url,
            model: .claude3Opus,
            processingOptions: .default
        )
    }
}
```

### Component Composition

**Before:**
```swift
// Monolithic view containing mixed concerns
struct ModelCompareView: View {
    @State private var prompt = ""
    @State private var responses: [String] = []
    @State private var models = ["Claude Haiku", "Claude Sonnet", "Claude Opus"]
    @State private var selectedModels: [String] = []
    
    var body: some View {
        VStack {
            // Model selection UI
            ForEach(models, id: \.self) { model in
                Button(action: {
                    if selectedModels.contains(model) {
                        selectedModels.removeAll { $0 == model }
                    } else {
                        selectedModels.append(model)
                    }
                }) {
                    HStack {
                        Text(model)
                        Spacer()
                        if selectedModels.contains(model) {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                .padding()
            }
            
            // Prompt input
            TextField("Enter prompt", text: $prompt)
            
            // Compare button
            Button("Compare Models") {
                responses = []
                for model in selectedModels {
                    // API calls mixed directly in the view
                    callModelAPI(model, prompt: prompt) { response in
                        responses.append(response)
                    }
                }
            }
            
            // Results display
            ForEach(Array(zip(selectedModels, responses)), id: \.0) { model, response in
                Text(model).bold()
                Text(response)
                Divider()
            }
        }
        .padding()
    }
    
    func callModelAPI(_ model: String, prompt: String, completion: @escaping (String) -> Void) {
        // Direct API call implementation
    }
}
```

**After:**
```swift
// Using modular components with clean separation of concerns
import SwiftUI
import ModelComparisonView
import LLMServiceProvider

struct ModelComparisonScreen: View {
    @StateObject private var viewModel = ModelComparisonViewModel()
    
    var body: some View {
        ModelComparisonView(viewModel: viewModel)
    }
}

// Or with custom setup:
struct CustomModelComparisonScreen: View {
    @StateObject private var viewModel = ModelComparisonViewModel()
    
    var body: some View {
        VStack {
            Text("Custom Model Comparison").font(.title)
            
            // Use pre-built components from the module
            ModelComparisonView(viewModel: viewModel)
                .padding()
                
            // Add custom UI elements if needed
            Button("Save Comparison") {
                saveComparison()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func saveComparison() {
        // Custom saving logic
    }
}
```

## LLM Service Integration

### Text Generation

**Before:**
```swift
// Direct API access with custom handling
func generateText() {
    let prompt = "Explain quantum computing."
    let apiKey = KeychainManager.shared.getAPIKey()
    
    let url = URL(string: "https://api.anthropic.com/v1/complete")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let parameters: [String: Any] = [
        "prompt": "\n\nHuman: \(prompt)\n\nAssistant:",
        "model": "claude-3-opus-20240229",
        "max_tokens_to_sample": 1000,
        "temperature": 0.7
    ]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            return
        }
        
        guard let data = data else {
            print("No data received")
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let completion = json["completion"] as? String {
                DispatchQueue.main.async {
                    self.responseTextView.text = completion
                }
            }
        } catch {
            print("JSON parsing error: \(error.localizedDescription)")
        }
    }.resume()
}
```

**After:**
```swift
import LLMServiceProvider

// Simplified integration using the service module
func generateText() {
    let prompt = "Explain quantum computing."
    
    Task {
        do {
            let response = try await LLMServiceProvider.shared.generateText(
                prompt: prompt,
                model: .claude3Opus,
                options: TextGenerationOptions(
                    temperature: 0.7,
                    maxTokens: 1000
                )
            )
            
            await MainActor.run {
                self.responseTextView.text = response.text
            }
        } catch {
            await MainActor.run {
                self.handleError(error)
            }
        }
    }
}
```

### Streaming Responses

**Before:**
```swift
// Custom streaming implementation
func streamResponse() {
    let prompt = "Write a short story about time travel."
    let apiKey = KeychainManager.shared.getAPIKey()
    
    let url = URL(string: "https://api.anthropic.com/v1/complete")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let parameters: [String: Any] = [
        "prompt": "\n\nHuman: \(prompt)\n\nAssistant:",
        "model": "claude-3-sonnet-20240229",
        "max_tokens_to_sample": 2000,
        "temperature": 0.7,
        "stream": true
    ]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        // Complex streaming handling code
        // ...
    }
    task.resume()
}
```

**After:**
```swift
import LLMServiceProvider

// Clean streaming with async/await
func streamResponse() {
    let prompt = "Write a short story about time travel."
    
    Task {
        do {
            let stream = try await LLMServiceProvider.shared.generateTextStream(
                prompt: prompt,
                model: .claude3Sonnet,
                options: TextGenerationOptions(
                    temperature: 0.7,
                    maxTokens: 2000
                )
            )
            
            var fullText = ""
            for try await item in stream {
                fullText += item.text
                await MainActor.run {
                    self.responseTextView.text = fullText
                }
            }
        } catch {
            await MainActor.run {
                self.handleError(error)
            }
        }
    }
}
```

## Model Comparison Framework

### Comparing Model Outputs

**Before:**
```swift
// Custom comparison code throughout the application
func compareModels() {
    let prompt = promptTextField.text ?? ""
    let models = ["claude-3-haiku", "claude-3-sonnet", "claude-3-opus"]
    
    var responses: [String: String] = [:]
    let group = DispatchGroup()
    
    for model in models {
        group.enter()
        callAPI(prompt: prompt, model: model) { result in
            responses[model] = result
            group.leave()
        }
    }
    
    group.notify(queue: .main) {
        self.displayResults(responses)
    }
}

func callAPI(prompt: String, model: String, completion: @escaping (String) -> Void) {
    // API call implementation
}

func displayResults(_ results: [String: String]) {
    for (model, response) in results {
        let label = UILabel()
        label.text = "Model: \(model)"
        resultStackView.addArrangedSubview(label)
        
        let textView = UITextView()
        textView.text = response
        resultStackView.addArrangedSubview(textView)
    }
}
```

**After:**
```swift
import SwiftUI
import ModelComparisonView

// Using the dedicated comparison module
struct ModelComparisonScreen: View {
    var body: some View {
        NavigationView {
            ModelComparisonView()
                .navigationTitle("Model Comparison")
        }
    }
}
```

### Benchmark Framework

**Before:**
```swift
// Manual benchmark implementation
class ModelBenchmarker {
    func runBenchmark() {
        let prompts = [
            "Explain quantum computing.",
            "Write a poem about the moon.",
            "Solve this math problem: If x + y = 10 and x - y = 4, what are x and y?"
        ]
        
        let models = ["claude-3-haiku", "claude-3-sonnet", "claude-3-opus"]
        
        var results: [String: [String: String]] = [:]
        
        for model in models {
            results[model] = [:]
            for prompt in prompts {
                // Synchronous API call for simplicity
                let response = callAPISync(prompt: prompt, model: model)
                results[model]?[prompt] = response
            }
        }
        
        // Manual results analysis
        // ...
    }
}
```

**After:**
```swift
import SwiftUI
import ModelComparisonView

// Using the built-in benchmark module
struct BenchmarkScreen: View {
    var body: some View {
        BenchmarkView(viewModel: BenchmarkViewModel())
    }
}

// Or for programmatic use:
func runCustomBenchmark() {
    let benchmarkViewModel = BenchmarkViewModel()
    
    // Configure the benchmark
    benchmarkViewModel.loadBenchmark(.reasoning)
    
    // Select specific models
    let availableModels = benchmarkViewModel.availableModels
    benchmarkViewModel.toggleModelSelection(availableModels[0].id)
    benchmarkViewModel.toggleModelSelection(availableModels[1].id)
    
    // Run the benchmark
    benchmarkViewModel.runBenchmark { success in
        if success {
            presentResults(benchmarkViewModel.benchmarkResults)
        }
    }
}
```

## PDF Processing

### PDF Splitting

**Before:**
```swift
// Manual PDF processing
func splitPDF() {
    guard let pdf = PDFDocument(url: pdfURL) else { return }
    
    // Split by page count
    let totalPages = pdf.pageCount
    let pagesPerChunk = 5
    
    for i in stride(from: 0, to: totalPages, by: pagesPerChunk) {
        let newPDF = PDFDocument()
        for j in i..<min(i + pagesPerChunk, totalPages) {
            if let page = pdf.page(at: j) {
                newPDF.insert(page, at: newPDF.pageCount)
            }
        }
        
        // Save the chunk
        let outputURL = documentsDirectory.appendingPathComponent("chunk_\(i/pagesPerChunk).pdf")
        newPDF.write(to: outputURL)
    }
}
```

**After:**
```swift
import SwiftUI
import PdfSplitterView

// Using the dedicated PDF processing module
struct PDFProcessingScreen: View {
    var body: some View {
        PdfSplitterView()
    }
}

// Or for programmatic use:
func splitPDF(url: URL) {
    let viewModel = PdfSplitterViewModel()
    
    // Load and configure
    viewModel.loadPdf(from: url)
    viewModel.selectedStrategy = SplitStrategy.byPage(name: "5 Pages Per Chunk")
    viewModel.pagesPerChunk = 5
    
    // Process the PDF
    viewModel.processPdf()
    
    // Access results
    let results = viewModel.splitResults
    // Use results as needed
}
```

## Testing Migrations

The modular architecture enables more effective testing. Here's how to update your tests:

### Before:

```swift
class ApiTests: XCTestCase {
    func testApiResponse() {
        // Hard to test due to direct API dependencies
        let expectation = XCTestExpectation(description: "API call")
        
        let api = ClaudeAPI(apiKey: "test_key")
        api.generateResponse(prompt: "Test", parameters: testParams) { result in
            // Assert on real API results
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}
```

### After:

```swift
import XCTest
@testable import LLMServiceProvider

class LLMServiceTests: XCTestCase {
    func testTextGeneration() async throws {
        // Create a mock service
        let mockService = MockLLMService()
        mockService.mockGenerateTextResponse = TextGenerationResponse(
            text: "Mock response",
            finishReason: .complete,
            usage: UsageMetrics(promptTokens: 10, completionTokens: 20, totalTokens: 30)
        )
        
        // Test with the mock
        let result = try await mockService.generateText(
            prompt: "Test prompt",
            model: .claude3Sonnet,
            options: .default
        )
        
        // Assert on predictable mock results
        XCTAssertEqual(result.text, "Mock response")
        XCTAssertEqual(result.finishReason, .complete)
        XCTAssertEqual(result.usage.totalTokens, 30)
    }
}

// Mock implementation for testing
class MockLLMService: LLMService {
    var mockGenerateTextResponse: TextGenerationResponse?
    
    func generateText(prompt: String, model: Claude3Model.ModelType, options: TextGenerationOptions) async throws -> TextGenerationResponse {
        return mockGenerateTextResponse ?? TextGenerationResponse(
            text: "Default mock",
            finishReason: .complete,
            usage: UsageMetrics(promptTokens: 0, completionTokens: 0, totalTokens: 0)
        )
    }
    
    // Implement other required methods...
}
```

## Troubleshooting

### Common Migration Issues

1. **Missing Imports**: Ensure you import the required modules in each file that uses their functionality.

2. **API Changes**: The new API might have different method signatures or parameter names. Refer to the module documentation for details.

3. **Async/Await Conversion**: Many synchronous or callback-based methods are now async/await. Make sure you're using the proper syntax:

   ```swift
   // Before
   service.doSomething { result in
       // Handle result
   }
   
   // After
   Task {
       let result = try await service.doSomething()
       // Handle result
   }
   ```

4. **Type Mismatches**: The modular architecture introduces stricter typing. Ensure you're using the correct types and converting between them as needed.

5. **Configuration Handling**: If you previously used global configuration, you'll need to update to use the configuration objects provided by each module.

### Getting Help

If you encounter issues during migration, refer to:

1. The module documentation in the `/docs` directory
2. The unit tests for each module, which demonstrate proper usage
3. The sample apps in the `/Examples` directory

For further assistance, contact the architecture team at `architecture@example.com`.

## Conclusion

Migrating to the modular architecture requires some upfront effort but provides significant benefits in maintainability, testability, and development velocity. By following the patterns in this guide, you can smoothly transition your codebase to the new architecture.
