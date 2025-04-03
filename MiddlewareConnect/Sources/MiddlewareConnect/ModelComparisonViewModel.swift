import Foundation
import Combine
import SwiftUI
import LLMServiceProvider

/// Comprehensive view model for orchestrating model comparison workflows
///
/// Manages the complete state for model comparison, coordinating model selection,
/// comparison execution, results analysis, and visualization presentation.
public class ModelComparisonViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Currently selected models for comparison
    @Published public var selectedModels: [ModelConfig] = []
    
    /// Available models for selection
    @Published public var availableModels: [ModelConfig] = []
    
    /// Metrics selected for evaluation
    @Published public var selectedMetrics: [ComparisonMetric] = []
    
    /// Available metrics for selection
    @Published public var availableMetrics: [ComparisonMetric] = []
    
    /// Test prompts for evaluation
    @Published public var testPrompts: [TestPrompt] = []
    
    /// Current state of the comparison process
    @Published public var comparisonState: ComparisonState = .ready
    
    /// Current comparison results
    @Published public var comparisonResults: ComparisonResult?
    
    /// Current in-progress results (partial results during comparison)
    @Published public var inProgressResults: [ProgressResultItem] = []
    
    /// Current user-facing error message
    @Published public var errorMessage: String?
    
    /// Whether comparison history is currently visible
    @Published public var showHistory: Bool = false
    
    /// History of previous comparisons
    @Published public var comparisonHistory: [ComparisonResult] = []
    
    /// Current visualization settings
    @Published public var visualizationSettings: VisualizationSettings = .default
    
    /// Comparison name
    @Published public var comparisonName: String = "Model Comparison"
    
    /// Comparison description
    @Published public var comparisonDescription: String = "Comparing model performance across metrics"
    
    /// Current comparison options
    @Published public var comparisonOptions: ComparisonOptions = .default
    
    // MARK: - Private Properties
    
    /// Service for managing LLM interactions
    private let modelService: ModelService
    
    /// Cancellation tokens for in-progress operations
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Initializes the view model with dependencies
    /// - Parameter modelService: Service for model interactions
    public init(modelService: ModelService = ModelService()) {
        self.modelService = modelService
        
        // Initialize with default data
        loadAvailableModels()
        loadAvailableMetrics()
    }
    
    // MARK: - Model Configuration Types
    
    /// Configuration for a model in comparison
    public struct ModelConfig: Identifiable, Equatable {
        /// Unique identifier
        public let id: UUID = UUID()
        
        /// Model type identifier
        public let modelType: Claude3Model.ModelType
        
        /// Display name for the model
        public let displayName: String
        
        /// Model parameters
        public var parameters: ModelParameters
        
        /// Creates a model configuration
        /// - Parameters:
        ///   - modelType: Model type
        ///   - displayName: Display name
        ///   - parameters: Model parameters
        public init(
            modelType: Claude3Model.ModelType,
            displayName: String? = nil,
            parameters: ModelParameters = ModelParameters()
        ) {
            self.modelType = modelType
            self.displayName = displayName ?? modelType.description
            self.parameters = parameters
        }
    }
    
    /// Parameters for model configuration
    public struct ModelParameters: Equatable {
        /// Temperature setting (0.0-1.0)
        public var temperature: Double
        
        /// Top-p sampling parameter (0.0-1.0)
        public var topP: Double
        
        /// Maximum tokens to generate
        public var maxTokens: Int?
        
        /// Whether to stream responses
        public var stream: Bool
        
        /// Additional model-specific parameters
        public var additionalParameters: [String: Any]
        
        /// Creates default model parameters
        public init(
            temperature: Double = 0.7,
            topP: Double = 1.0,
            maxTokens: Int? = nil,
            stream: Bool = false,
            additionalParameters: [String: Any] = [:]
        ) {
            self.temperature = temperature
            self.topP = topP
            self.maxTokens = maxTokens
            self.stream = stream
            self.additionalParameters = additionalParameters
        }
        
        /// Equatable implementation
        public static func == (lhs: ModelParameters, rhs: ModelParameters) -> Bool {
            return lhs.temperature == rhs.temperature &&
                   lhs.topP == rhs.topP &&
                   lhs.maxTokens == rhs.maxTokens &&
                   lhs.stream == rhs.stream
            // Note: additionalParameters not compared for simplicity
        }
    }
    
    /// Test prompt for evaluation
    public struct TestPrompt: Identifiable, Equatable {
        /// Unique identifier
        public let id: UUID = UUID()
        
        /// Prompt name/title
        public var name: String
        
        /// Content of the prompt
        public var content: String
        
        /// Category of the prompt
        public var category: String
        
        /// Expected response if any
        public var expectedResponse: String?
        
        /// Number of test iterations
        public var iterations: Int
        
        /// Creates a test prompt
        /// - Parameters:
        ///   - name: Prompt name
        ///   - content: Prompt content
        ///   - category: Prompt category
        ///   - expectedResponse: Expected response
        ///   - iterations: Test iterations
        public init(
            name: String,
            content: String,
            category: String = "General",
            expectedResponse: String? = nil,
            iterations: Int = 1
        ) {
            self.name = name
            self.content = content
            self.category = category
            self.expectedResponse = expectedResponse
            self.iterations = iterations
        }
    }
    
    /// Partial result during comparison
    public struct ProgressResultItem: Identifiable {
        /// Unique identifier
        public let id: UUID = UUID()
        
        /// Model being evaluated
        public let model: ModelConfig
        
        /// Prompt being tested
        public let prompt: TestPrompt
        
        /// Metric being evaluated
        public let metric: ComparisonMetric
        
        /// Current score if available
        public let score: Double?
        
        /// Model output
        public let output: String?
        
        /// Status of this evaluation
        public let status: EvaluationStatus
        
        /// Creates a progress result item
        /// - Parameters:
        ///   - model: Model configuration
        ///   - prompt: Test prompt
        ///   - metric: Comparison metric
        ///   - score: Current score
        ///   - output: Model output
        ///   - status: Evaluation status
        public init(
            model: ModelConfig,
            prompt: TestPrompt,
            metric: ComparisonMetric,
            score: Double? = nil,
            output: String? = nil,
            status: EvaluationStatus = .pending
        ) {
            self.model = model
            self.prompt = prompt
            self.metric = metric
            self.score = score
            self.output = output
            self.status = status
        }
        
        /// Evaluation status options
        public enum EvaluationStatus {
            /// Waiting to be processed
            case pending
            
            /// Currently being processed
            case processing
            
            /// Successfully completed
            case completed
            
            /// Failed with error
            case failed(String)
        }
    }
    
    /// Comparison state options
    public enum ComparisonState: Equatable {
        /// Ready to begin comparison
        case ready
        
        /// Comparison in progress
        case comparing(progress: Double)
        
        /// Comparison completed
        case completed
        
        /// Comparison failed
        case failed
        
        /// Equatable implementation
        public static func == (lhs: ComparisonState, rhs: ComparisonState) -> Bool {
            switch (lhs, rhs) {
            case (.ready, .ready):
                return true
            case let (.comparing(p1), .comparing(p2)):
                return p1 == p2
            case (.completed, .completed):
                return true
            case (.failed, .failed):
                return true
            default:
                return false
            }
        }
    }
    
    /// Visualization settings
    public struct VisualizationSettings: Equatable {
        /// Chart type for visualization
        public var chartType: ChartType
        
        /// Whether to normalize scores
        public var normalizeScores: Bool
        
        /// Whether to show raw data
        public var showRawData: Bool
        
        /// Whether to group by category
        public var groupByCategory: Bool
        
        /// Color scheme for visualization
        public var colorScheme: ColorScheme
        
        /// Default visualization settings
        public static let `default` = VisualizationSettings(
            chartType: .bar,
            normalizeScores: true,
            showRawData: false,
            groupByCategory: true,
            colorScheme: .standard
        )
        
        /// Creates visualization settings
        /// - Parameters:
        ///   - chartType: Chart type
        ///   - normalizeScores: Normalize scores
        ///   - showRawData: Show raw data
        ///   - groupByCategory: Group by category
        ///   - colorScheme: Color scheme
        public init(
            chartType: ChartType,
            normalizeScores: Bool,
            showRawData: Bool,
            groupByCategory: Bool,
            colorScheme: ColorScheme
        ) {
            self.chartType = chartType
            self.normalizeScores = normalizeScores
            self.showRawData = showRawData
            self.groupByCategory = groupByCategory
            self.colorScheme = colorScheme
        }
        
        /// Chart type options
        public enum ChartType: String, CaseIterable {
            /// Bar chart
            case bar
            
            /// Line chart
            case line
            
            /// Radar chart
            case radar
            
            /// Table view
            case table
            
            /// Display name for the chart type
            public var displayName: String {
                switch self {
                case .bar: return "Bar Chart"
                case .line: return "Line Chart"
                case .radar: return "Radar Chart"
                case .table: return "Table View"
                }
            }
            
            /// Icon for the chart type
            public var icon: String {
                switch self {
                case .bar: return "chart.bar"
                case .line: return "chart.line.uptrend.xyaxis"
                case .radar: return "chart.pie"
                case .table: return "tablecells"
                }
            }
        }
        
        /// Color scheme options
        public enum ColorScheme: String, CaseIterable {
            /// Standard color scheme
            case standard
            
            /// Colorblind-friendly scheme
            case colorblind
            
            /// Monochrome scheme
            case monochrome
            
            /// High-contrast scheme
            case highContrast
            
            /// Display name for the scheme
            public var displayName: String {
                switch self {
                case .standard: return "Standard Colors"
                case .colorblind: return "Colorblind Friendly"
                case .monochrome: return "Monochrome"
                case .highContrast: return "High Contrast"
                }
            }
        }
    }
    
    /// Options for comparison execution
    public struct ComparisonOptions: Equatable {
        /// Number of test iterations
        public var iterations: Int
        
        /// Whether to use parallel execution
        public var useParallelExecution: Bool
        
        /// Whether to cache results
        public var cacheResults: Bool
        
        /// Whether to include analysis
        public var includeAnalysis: Bool
        
        /// Default comparison options
        public static let `default` = ComparisonOptions(
            iterations: 1,
            useParallelExecution: true,
            cacheResults: true,
            includeAnalysis: true
        )
        
        /// Creates comparison options
        /// - Parameters:
        ///   - iterations: Test iterations
        ///   - useParallelExecution: Use parallel execution
        ///   - cacheResults: Cache results
        ///   - includeAnalysis: Include analysis
        public init(
            iterations: Int,
            useParallelExecution: Bool,
            cacheResults: Bool,
            includeAnalysis: Bool
        ) {
            self.iterations = iterations
            self.useParallelExecution = useParallelExecution
            self.cacheResults = cacheResults
            self.includeAnalysis = includeAnalysis
        }
    }
    
    // MARK: - Service Protocol
    
    /// Protocol for model service
    public protocol ModelService {
        /// Get available models
        /// - Returns: Array of model types
        func getAvailableModels() -> [Claude3Model.ModelType]
        
        /// Execute a prompt with a model
        /// - Parameters:
        ///   - prompt: Prompt to execute
        ///   - model: Model to use
        ///   - parameters: Model parameters
        /// - Returns: Publisher with response
        func executePrompt(prompt: String, model: Claude3Model.ModelType, parameters: ModelParameters) -> AnyPublisher<ModelResponse, Error>
    }
    
    /// Model response data
    public struct ModelResponse {
        /// Output text
        public let output: String
        
        /// Execution statistics
        public let stats: ResponseStats
        
        /// Creates a model response
        /// - Parameters:
        ///   - output: Output text
        ///   - stats: Response statistics
        public init(output: String, stats: ResponseStats) {
            self.output = output
            self.stats = stats
        }
    }
    
    /// Response statistics
    public struct ResponseStats {
        /// Tokens in the prompt
        public let promptTokens: Int
        
        /// Tokens in the completion
        public let completionTokens: Int
        
        /// Total tokens used
        public let totalTokens: Int
        
        /// Time taken in seconds
        public let latencySeconds: Double
        
        /// Creates response statistics
        /// - Parameters:
        ///   - promptTokens: Prompt tokens
        ///   - completionTokens: Completion tokens
        ///   - totalTokens: Total tokens
        ///   - latencySeconds: Latency in seconds
        public init(
            promptTokens: Int,
            completionTokens: Int,
            totalTokens: Int,
            latencySeconds: Double
        ) {
            self.promptTokens = promptTokens
            self.completionTokens = completionTokens
            self.totalTokens = totalTokens
            self.latencySeconds = latencySeconds
        }
    }
    
    // MARK: - Default Implementation
    
    /// Default service implementation
    private class DefaultModelService: ModelService {
        /// Get available models
        func getAvailableModels() -> [Claude3Model.ModelType] {
            return [
                .claude3Haiku,
                .claude3Sonnet,
                .claude3Opus
            ]
        }
        
        /// Execute a prompt with a model
        func executePrompt(prompt: String, model: Claude3Model.ModelType, parameters: ModelParameters) -> AnyPublisher<ModelResponse, Error> {
            // This would interact with actual LLM service
            // For now, return mock data
            let mockResponse = ModelResponse(
                output: "This is a mock response for \(model.description) with prompt: \(prompt.prefix(20))...",
                stats: ResponseStats(
                    promptTokens: prompt.count / 4,
                    completionTokens: 100,
                    totalTokens: prompt.count / 4 + 100,
                    latencySeconds: Double.random(in: 0.5...3.0)
                )
            )
            
            return Just(mockResponse)
                .delay(for: .seconds(Double.random(in: 0.5...2.0)), scheduler: RunLoop.main)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    // MARK: - Public Methods
    
    /// Loads available models
    public func loadAvailableModels() {
        let modelTypes = modelService.getAvailableModels()
        self.availableModels = modelTypes.map { ModelConfig(modelType: $0) }
    }
    
    /// Loads available metrics
    public func loadAvailableMetrics() {
        self.availableMetrics = ComparisonMetric.standardMetrics
    }
    
    /// Adds a model to the selection
    /// - Parameter model: Model to add
    public func addModel(_ model: ModelConfig) {
        guard !selectedModels.contains(where: { $0.modelType == model.modelType }) else {
            return
        }
        selectedModels.append(model)
    }
    
    /// Removes a model from the selection
    /// - Parameter id: Model ID to remove
    public func removeModel(id: UUID) {
        selectedModels.removeAll { $0.id == id }
    }
    
    /// Updates parameters for a model
    /// - Parameters:
    ///   - id: Model ID to update
    ///   - parameters: New parameters
    public func updateModelParameters(id: UUID, parameters: ModelParameters) {
        guard let index = selectedModels.firstIndex(where: { $0.id == id }) else {
            return
        }
        selectedModels[index].parameters = parameters
    }
    
    /// Adds a metric to the selection
    /// - Parameter metric: Metric to add
    public func addMetric(_ metric: ComparisonMetric) {
        guard !selectedMetrics.contains(where: { $0.id == metric.id }) else {
            return
        }
        selectedMetrics.append(metric)
    }
    
    /// Removes a metric from the selection
    /// - Parameter id: Metric ID to remove
    public func removeMetric(id: UUID) {
        selectedMetrics.removeAll { $0.id == id }
    }
    
    /// Adds a test prompt
    /// - Parameter prompt: Prompt to add
    public func addTestPrompt(_ prompt: TestPrompt) {
        testPrompts.append(prompt)
    }
    
    /// Updates a test prompt
    /// - Parameters:
    ///   - id: Prompt ID to update
    ///   - updatedPrompt: Updated prompt data
    public func updateTestPrompt(id: UUID, updatedPrompt: TestPrompt) {
        guard let index = testPrompts.firstIndex(where: { $0.id == id }) else {
            return
        }
        testPrompts[index] = updatedPrompt
    }
    
    /// Removes a test prompt
    /// - Parameter id: Prompt ID to remove
    public func removeTestPrompt(id: UUID) {
        testPrompts.removeAll { $0.id == id }
    }
    
    /// Starts the comparison process
    public func startComparison() {
        // Validate inputs
        guard !selectedModels.isEmpty else {
            errorMessage = "Please select at least one model for comparison"
            return
        }
        
        guard !selectedMetrics.isEmpty else {
            errorMessage = "Please select at least one metric for evaluation"
            return
        }
        
        guard !testPrompts.isEmpty else {
            errorMessage = "Please add at least one test prompt"
            return
        }
        
        // Reset state
        comparisonState = .comparing(progress: 0.0)
        errorMessage = nil
        inProgressResults = []
        
        // Create in-progress results placeholder
        for model in selectedModels {
            for prompt in testPrompts {
                for metric in selectedMetrics {
                    inProgressResults.append(
                        ProgressResultItem(
                            model: model,
                            prompt: prompt,
                            metric: metric
                        )
                    )
                }
            }
        }
        
        // Execute comparison
        executeComparisonTasks()
    }
    
    /// Cancels the comparison process
    public func cancelComparison() {
        // Cancel all publishers
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        // Reset state
        comparisonState = .ready
        inProgressResults = []
    }
    
    /// Saves the current results
    public func saveResults() {
        guard let results = comparisonResults else {
            return
        }
        
        // Add to history
        comparisonHistory.append(results)
        
        // In a real app, would persist to storage
    }
    
    /// Exports results to a specific format
    /// - Parameter format: Export format
    /// - Returns: Export data
    public func exportResults(format: ExportFormat) -> Data? {
        guard let results = comparisonResults else {
            return nil
        }
        
        switch format {
        case .json:
            guard let jsonString = results.exportToJson(),
                  let jsonData = jsonString.data(using: .utf8) else {
                return nil
            }
            return jsonData
            
        case .csv:
            // Generate CSV
            var csv = "Model,Prompt,Metric,Score\n"
            
            for result in results.results {
                let modelName = results.models.first(where: { $0.id == result.modelId })?.name ?? "Unknown"
                let promptName = results.prompts.first(where: { $0.id == result.promptId })?.name ?? "Unknown"
                let metricName = results.metrics.first(where: { $0.id == result.metricId })?.name ?? "Unknown"
                
                csv += "\"\(modelName)\",\"\(promptName)\",\"\(metricName)\",\(result.score)\n"
            }
            
            return csv.data(using: .utf8)
            
        case .pdf:
            // Would generate PDF in a real implementation
            return nil
        }
    }
    
    /// Export format options
    public enum ExportFormat {
        /// JSON format
        case json
        
        /// CSV format
        case csv
        
        /// PDF format
        case pdf
    }
    
    /// Clears comparison results
    public func clearResults() {
        comparisonResults = nil
        comparisonState = .ready
        inProgressResults = []
    }
    
    /// Loads a comparison from history
    /// - Parameter id: Comparison ID to load
    public func loadFromHistory(id: UUID) {
        guard let historicalResult = comparisonHistory.first(where: { $0.id == id }) else {
            return
        }
        
        comparisonResults = historicalResult
        comparisonState = .completed
    }
    
    // MARK: - Private Methods
    
    /// Executes the comparison tasks
    private func executeComparisonTasks() {
        let totalTasks = inProgressResults.count
        var completedTasks = 0
        
        // Process each result
        for (index, result) in inProgressResults.enumerated() {
            // Update status to processing
            inProgressResults[index] = ProgressResultItem(
                model: result.model,
                prompt: result.prompt,
                metric: result.metric,
                status: .processing
            )
            
            // Execute the prompt
            executePromptForResult(index: index)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        guard let self = self else { return }
                        
                        // Update task completion count
                        completedTasks += 1
                        let progress = Double(completedTasks) / Double(totalTasks)
                        self.comparisonState = .comparing(progress: progress)
                        
                        // Check if all tasks are complete
                        if completedTasks == totalTasks {
                            self.finalizeComparison()
                        }
                    },
                    receiveValue: { [weak self] resultItem in
                        guard let self = self else { return }
                        
                        // Update result
                        self.inProgressResults[index] = resultItem
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    /// Executes a prompt for a specific result
    /// - Parameter index: Result index to process
    /// - Returns: Publisher with updated result
    private func executePromptForResult(index: Int) -> AnyPublisher<ProgressResultItem, Never> {
        let result = inProgressResults[index]
        
        return modelService.executePrompt(
            prompt: result.prompt.content,
            model: result.model.modelType,
            parameters: result.model.parameters
        )
        .map { response -> ProgressResultItem in
            // Calculate metric score based on response
            let metricScore = self.calculateMetricScore(
                metric: result.metric,
                output: response.output,
                expectedOutput: result.prompt.expectedResponse,
                stats: response.stats
            )
            
            // Create updated result
            return ProgressResultItem(
                model: result.model,
                prompt: result.prompt,
                metric: result.metric,
                score: metricScore,
                output: response.output,
                status: .completed
            )
        }
        .catch { error -> AnyPublisher<ProgressResultItem, Never> in
            // Handle error
            let errorResult = ProgressResultItem(
                model: result.model,
                prompt: result.prompt,
                metric: result.metric,
                status: .failed(error.localizedDescription)
            )
            
            return Just(errorResult).eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    /// Calculates a metric score for a response
    /// - Parameters:
    ///   - metric: Metric to evaluate
    ///   - output: Model output
    ///   - expectedOutput: Expected output if any
    ///   - stats: Response statistics
    /// - Returns: Calculated score
    private func calculateMetricScore(
        metric: ComparisonMetric,
        output: String,
        expectedOutput: String?,
        stats: ResponseStats
    ) -> Double {
        // Based on metric type, calculate appropriate score
        switch metric.name {
        case "Accuracy":
            // If expected output is available, compare similarity
            if let expectedOutput = expectedOutput {
                return calculateSimilarity(output, expectedOutput)
            }
            // Default placeholder value
            return 0.75
            
        case "Latency":
            // Inverse latency (lower is better)
            let normalizedLatency = 1.0 - min(1.0, stats.latencySeconds / 10.0)
            return normalizedLatency * 100.0
            
        case "Token Efficiency":
            // Calculate token efficiency
            let efficiency = Double(output.count) / Double(stats.totalTokens)
            return min(1.0, efficiency) * 100.0
            
        case "Reasoning Score":
            // Placeholder reasoning score
            return Double.random(in: 6.0...9.0)
            
        case "Consistency":
            // Placeholder consistency score
            return Double.random(in: 0.7...0.95)
            
        default:
            // Generic placeholder score
            return Double.random(in: 0.6...0.9) * 100.0
        }
    }
    
    /// Simple text similarity calculation
    /// - Parameters:
    ///   - text1: First text
    ///   - text2: Second text
    /// - Returns: Similarity score between 0 and 1
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        // This is a placeholder implementation
        // Real implementation would use more sophisticated algorithms
        
        let set1 = Set(text1.components(separatedBy: .whitespacesAndNewlines))
        let set2 = Set(text2.components(separatedBy: .whitespacesAndNewlines))
        
        guard !set1.isEmpty || !set2.isEmpty else { return 0.0 }
        
        let intersection = set1.intersection(set2).count
        let union = set1.union(set2).count
        
        return Double(intersection) / Double(union) * 100.0
    }
    
    /// Finalizes the comparison process
    private func finalizeComparison() {
        // Generate model references
        let modelReferences = selectedModels.map { model in
            ComparisonResult.ModelReference(
                name: model.displayName,
                modelType: model.modelType.rawValue,
                configuration: ComparisonResult.ModelConfiguration(
                    parameters: [
                        "temperature": model.parameters.temperature,
                        "topP": model.parameters.topP
                    ],
                    contextSize: 8192,
                    options: [:]
                )
            )
        }
        
        // Generate prompt references
        let promptReferences = testPrompts.map { prompt in
            ComparisonResult.PromptReference(
                name: prompt.name,
                category: prompt.category,
                content: prompt.content,
                expectedOutputs: prompt.expectedResponse.map { [$0] } ?? [],
                difficulty: .medium
            )
        }
        
        // Generate metric references
        let metricReferences = selectedMetrics.map { metric in
            ComparisonResult.MetricReference(
                id: metric.id,
                name: metric.name,
                category: metric.category.rawValue
            )
        }
        
        // Generate result points
        let resultPoints: [ComparisonResult.ResultPoint] = inProgressResults.compactMap { item in
            guard case .completed = item.status, let score = item.score else {
                return nil
            }
            
            let modelId = modelReferences.first { $0.name == item.model.displayName }?.id ?? UUID()
            let promptId = promptReferences.first { $0.name == item.prompt.name }?.id ?? UUID()
            let metricId = metricReferences.first { $0.name == item.metric.name }?.id ?? UUID()
            
            return ComparisonResult.ResultPoint(
                modelId: modelId,
                promptId: promptId,
                metricId: metricId,
                score: score,
                normalizedScore: score / 100.0,
                modelOutput: item.output,
                metadata: [:]
            )
        }
        
        // Calculate summary statistics
        let modelRankings = calculateModelRankings(
            models: modelReferences,
            resultPoints: resultPoints
        )
        
        let metricAverages = calculateMetricAverages(
            metrics: metricReferences,
            resultPoints: resultPoints
        )
        
        let categoryPerformance = calculateCategoryPerformance(
            models: modelReferences,
            metrics: metricReferences,
            resultPoints: resultPoints
        )
        
        let strengthsWeaknesses = calculateStrengthsWeaknesses(
            models: modelReferences,
            metrics: metricReferences,
            resultPoints: resultPoints
        )
        
        let summary = ComparisonResult.SummaryStatistics(
            modelRankings: modelRankings,
            metricAverages: metricAverages,
            categoryPerformance: categoryPerformance,
            analysis: strengthsWeaknesses
        )
        
        // Create final result
        let comparisonResult = ComparisonResult(
            name: comparisonName,
            description: comparisonDescription,
            models: modelReferences,
            prompts: promptReferences,
            metrics: metricReferences,
            results: resultPoints,
            summary: summary,
            tags: []
        )
        
        // Update state
        self.comparisonResults = comparisonResult
        self.comparisonState = .completed
    }
    
    /// Calculates model rankings based on results
    /// - Parameters:
    ///   - models: Model references
    ///   - resultPoints: Result data points
    /// - Returns: Model rankings
    private func calculateModelRankings(
        models: [ComparisonResult.ModelReference],
        resultPoints: [ComparisonResult.ResultPoint]
    ) -> [ComparisonResult.ModelRanking] {
        // Calculate average scores by model
        var scoresByModel: [UUID: [Double]] = [:]
        for result in resultPoints {
            scoresByModel[result.modelId, default: []].append(result.normalizedScore)
        }
        
        // Calculate average score for each model
        var averageScores: [UUID: Double] = [:]
        for (modelId, scores) in scoresByModel {
            averageScores[modelId] = scores.reduce(0, +) / Double(max(1, scores.count))
        }
        
        // Sort models by score
        let sortedModels = averageScores.sorted { $0.value > $1.value }
        
        // Create rankings
        return sortedModels.enumerated().map { index, entry in
            // Calculate percentile (higher is better)
            let percentile = 100.0 * (1.0 - Double(index) / Double(max(1, sortedModels.count - 1)))
            
            return ComparisonResult.ModelRanking(
                modelId: entry.key,
                rank: index + 1,
                overallScore: entry.value * 100.0, // Scale to 0-100
                percentile: percentile
            )
        }
    }
    
    /// Calculates metric averages based on results
    /// - Parameters:
    ///   - metrics: Metric references
    ///   - resultPoints: Result data points
    /// - Returns: Metric averages
    private func calculateMetricAverages(
        metrics: [ComparisonResult.MetricReference],
        resultPoints: [ComparisonResult.ResultPoint]
    ) -> [ComparisonResult.MetricAverage] {
        // Group by metric
        var metricGroups: [UUID: [ComparisonResult.ResultPoint]] = [:]
        for result in resultPoints {
            metricGroups[result.metricId, default: []].append(result)
        }
        
        // Calculate averages for each metric
        return metrics.map { metric in
            let metricResults = metricGroups[metric.id] ?? []
            
            // Group by model
            var averagesByModel: [UUID: Double] = [:]
            var scoresByModel: [UUID: [Double]] = [:]
            
            for result in metricResults {
                scoresByModel[result.modelId, default: []].append(result.normalizedScore)
            }
            
            // Calculate average for each model
            for (modelId, scores) in scoresByModel {
                averagesByModel[modelId] = scores.reduce(0, +) / Double(max(1, scores.count))
            }
            
            // Calculate overall average and standard deviation
            let allScores = metricResults.map { $0.normalizedScore }
            let overallAverage = allScores.reduce(0, +) / Double(max(1, allScores.count))
            
            // Calculate standard deviation
            let variance = allScores.map { pow($0 - overallAverage, 2) }.reduce(0, +) / Double(max(1, allScores.count))
            let standardDeviation = sqrt(variance)
            
            return ComparisonResult.MetricAverage(
                metricId: metric.id,
                averagesByModel: averagesByModel,
                overallAverage: overallAverage,
                standardDeviation: standardDeviation
            )
        }
    }
    
    /// Calculates category performance based on results
    /// - Parameters:
    ///   - models: Model references
    ///   - metrics: Metric references
    ///   - resultPoints: Result data points
    /// - Returns: Category performance data
    private func calculateCategoryPerformance(
        models: [ComparisonResult.ModelReference],
        metrics: [ComparisonResult.MetricReference],
        resultPoints: [ComparisonResult.ResultPoint]
    ) -> [ComparisonResult.CategoryPerformance] {
        // Group metrics by category
        var metricsByCategory: [String: [UUID]] = [:]
        for metric in metrics {
            metricsByCategory[metric.category, default: []].append(metric.id)
        }
        
        // Calculate performance by category
        return metricsByCategory.map { category, metricIds in
            // Filter results by metrics in this category
            let categoryResults = resultPoints.filter { metricIds.contains($0.metricId) }
            
            // Group by model
            var scoresByModel: [UUID: [Double]] = [:]
            for result in categoryResults {
                scoresByModel[result.modelId, default: []].append(result.normalizedScore)
            }
            
            // Calculate average for each model
            var modelAverages: [UUID: Double] = [:]
            for (modelId, scores) in scoresByModel {
                modelAverages[modelId] = scores.reduce(0, +) / Double(max(1, scores.count))
            }
            
            // Find best model
            let bestModel = modelAverages.max { $0.value < $1.value }
            let bestModelId = bestModel?.key ?? models.first!.id
            
            return ComparisonResult.CategoryPerformance(
                category: category,
                scoresByModel: modelAverages,
                bestModelId: bestModelId
            )
        }
    }
    
    /// Calculates strengths and weaknesses analysis
    /// - Parameters:
    ///   - models: Model references
    ///   - metrics: Metric references
    ///   - resultPoints: Result data points
    /// - Returns: Strengths and weaknesses analysis
    private func calculateStrengthsWeaknesses(
        models: [ComparisonResult.ModelReference],
        metrics: [ComparisonResult.MetricReference],
        resultPoints: [ComparisonResult.ResultPoint]
    ) -> ComparisonResult.StrengthsWeaknesses {
        var strengths: [UUID: [ComparisonResult.StrengthsWeaknesses.Insight]] = [:]
        var weaknesses: [UUID: [ComparisonResult.StrengthsWeaknesses.Insight]] = [:]
        
        // For each model, find strengths and weaknesses
        for model in models {
            // Get results for this model
            let modelResults = resultPoints.filter { $0.modelId == model.id }
            
            // Calculate average by metric
            var scoresByMetric: [UUID: [Double]] = [:]
            for result in modelResults {
                scoresByMetric[result.metricId, default: []].append(result.normalizedScore)
            }
            
            var metricAverages: [UUID: Double] = [:]
            for (metricId, scores) in scoresByMetric {
                metricAverages[metricId] = scores.reduce(0, +) / Double(max(1, scores.count))
            }
            
            // Sort metrics by score
            let sortedMetrics = metricAverages.sorted { $0.value > $1.value }
            
            // Top metrics are strengths
            let strengthMetrics = sortedMetrics.prefix(2)
            strengths[model.id] = strengthMetrics.map { metricId, score in
                let metricName = metrics.first { $0.id == metricId }?.name ?? "Unknown"
                
                return ComparisonResult.StrengthsWeaknesses.Insight(
                    description: "Strong performance in \(metricName) metrics",
                    relatedMetrics: [metricId],
                    confidence: min(1.0, score + 0.2)
                )
            }
            
            // Bottom metrics are weaknesses
            let weaknessMetrics = sortedMetrics.suffix(2)
            weaknesses[model.id] = weaknessMetrics.map { metricId, score in
                let metricName = metrics.first { $0.id == metricId }?.name ?? "Unknown"
                
                return ComparisonResult.StrengthsWeaknesses.Insight(
                    description: "Weaker performance in \(metricName) metrics",
                    relatedMetrics: [metricId],
                    confidence: min(1.0, 1.0 - score + 0.2)
                )
            }
        }
        
        // Generate overall insights
        let overallInsights = [
            "Models generally perform better on quality metrics than on efficiency metrics",
            "Performance varies significantly by prompt category",
            "Models with higher token efficiency tend to have lower accuracy scores"
        ]
        
        return ComparisonResult.StrengthsWeaknesses(
            strengths: strengths,
            weaknesses: weaknesses,
            overallInsights: overallInsights
        )
    }
}
