/**
 * @fileoverview Benchmark View for standardized model evaluation
 * @module BenchmarkView
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
 * - BenchmarkView
 * 
 * Notes:
 * - Provides standardized benchmark evaluation
 * - Includes predefined prompt sets and evaluation metrics
 */

import SwiftUI
import Combine
import LLMServiceProvider

/// View for running standardized benchmark evaluations of LLM models
public struct BenchmarkView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: BenchmarkViewModel
    @State private var selectedBenchmark: BenchmarkType = .general
    @State private var isRunning = false
    @State private var showResults = false
    
    // MARK: - Initialization
    
    /// Initialize with a view model
    /// - Parameter viewModel: The view model for benchmark orchestration
    public init(viewModel: BenchmarkViewModel = BenchmarkViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Benchmark selection
                benchmarkSelector
                    .padding(.horizontal)
                    .padding(.top)
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        benchmarkInfo
                        modelSelection
                        benchmarkOptions
                        
                        Divider()
                        
                        if showResults {
                            benchmarkResults
                        } else {
                            actionButton
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Model Benchmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.resetBenchmark()
                        showResults = false
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .disabled(isRunning || !showResults)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // In a real app, would implement export
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(isRunning || !showResults)
                }
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
    
    /// Benchmark selector
    private var benchmarkSelector: some View {
        Picker("Benchmark", selection: $selectedBenchmark) {
            ForEach(BenchmarkType.allCases, id: \.self) { benchmarkType in
                Text(benchmarkType.displayName).tag(benchmarkType)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedBenchmark) { newBenchmark in
            viewModel.loadBenchmark(newBenchmark)
            showResults = false
        }
    }
    
    /// Benchmark information
    private var benchmarkInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedBenchmark.displayName)
                        .font(.headline)
                    
                    Text(selectedBenchmark.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: selectedBenchmark.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                BenchmarkDetailRow(
                    title: "Tasks",
                    value: "\(viewModel.benchmarkTasks.count)",
                    iconName: "checklist"
                )
                
                BenchmarkDetailRow(
                    title: "Metrics",
                    value: "\(viewModel.benchmarkMetrics.count)",
                    iconName: "chart.bar"
                )
                
                BenchmarkDetailRow(
                    title: "Difficulty",
                    value: selectedBenchmark.difficulty.rawValue,
                    iconName: "speedometer"
                )
                
                BenchmarkDetailRow(
                    title: "Estimated Time",
                    value: selectedBenchmark.timeEstimate,
                    iconName: "clock"
                )
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    /// Model selection view
    private var modelSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Models")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.availableModels, id: \.id) { model in
                        ModelCheckboxButton(
                            model: model,
                            isSelected: viewModel.selectedModelIds.contains(model.id),
                            action: {
                                viewModel.toggleModelSelection(model.id)
                            }
                        )
                    }
                }
            }
        }
    }
    
    /// Benchmark options view
    private var benchmarkOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Benchmark Options")
                .font(.headline)
            
            VStack(spacing: 10) {
                Toggle("Run in parallel", isOn: $viewModel.runInParallel)
                    .disabled(isRunning)
                
                Toggle("Use system prompts", isOn: $viewModel.useSystemPrompts)
                    .disabled(isRunning)
                
                Toggle("Cache results", isOn: $viewModel.cacheResults)
                    .disabled(isRunning)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            Text("Task Selection")
                .font(.headline)
                .padding(.top, 8)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(viewModel.benchmarkTasks) { task in
                        TaskCheckboxRow(
                            task: task,
                            isSelected: viewModel.selectedTaskIds.contains(task.id),
                            action: {
                                viewModel.toggleTaskSelection(task.id)
                            }
                        )
                        .disabled(isRunning)
                    }
                }
            }
            .frame(height: 150)
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    /// Button to run benchmark
    private var actionButton: some View {
        VStack(spacing: 16) {
            Button(action: runBenchmark) {
                if isRunning {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        
                        Text("Running Benchmark...")
                            .padding(.leading, 8)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text("Run Benchmark")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning || viewModel.selectedModelIds.isEmpty || viewModel.selectedTaskIds.isEmpty)
            .padding(.vertical, 8)
            
            if isRunning {
                BenchmarkProgressView(progress: viewModel.benchmarkProgress)
            }
        }
    }
    
    /// Benchmark results view
    private var benchmarkResults: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Benchmark Results")
                .font(.headline)
            
            if let results = viewModel.benchmarkResults {
                VStack(spacing: 16) {
                    // Overall rankings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overall Rankings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(results.modelRankings, id: \.modelId) { ranking in
                            BenchmarkRankingRow(
                                modelName: viewModel.getModelName(ranking.modelId),
                                rank: ranking.rank,
                                score: ranking.score
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    
                    // Category performance
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Performance by Category")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(results.categoryPerformance, id: \.category) { categoryPerf in
                            PerformanceCategoryView(
                                category: categoryPerf.category,
                                modelScores: categoryPerf.modelScores.map { score in
                                    (viewModel.getModelName(score.modelId), score.score)
                                }
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    
                    // Task-specific performance
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task-Specific Performance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            TaskPerformanceGrid(
                                tasks: results.taskPerformance.map { $0.taskName },
                                models: viewModel.selectedModelIds.map { viewModel.getModelName($0) },
                                scores: results.taskPerformance.map { task in
                                    viewModel.selectedModelIds.map { modelId in
                                        task.modelScores.first { $0.modelId == modelId }?.score ?? 0
                                    }
                                }
                            )
                            .padding(.vertical)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
            } else {
                Text("No results available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
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
    
    // MARK: - Actions
    
    /// Runs the benchmark
    private func runBenchmark() {
        isRunning = true
        
        // In a real app, this would use Combine to handle async operations
        // For this example, we'll simulate the benchmark
        viewModel.runBenchmark { success in
            DispatchQueue.main.async {
                self.isRunning = false
                if success {
                    self.showResults = true
                }
            }
        }
    }
    
    // MARK: - Benchmark Types
    
    /// Types of benchmarks available
    public enum BenchmarkType: String, CaseIterable {
        case general = "general"
        case reasoning = "reasoning"
        case creative = "creative"
        case knowledge = "knowledge"
        case code = "code"
        
        /// User-friendly display name
        var displayName: String {
            switch self {
            case .general: return "General"
            case .reasoning: return "Reasoning"
            case .creative: return "Creative"
            case .knowledge: return "Knowledge"
            case .code: return "Code"
            }
        }
        
        /// Description of the benchmark
        var description: String {
            switch self {
            case .general:
                return "Evaluates general capabilities across a diverse range of tasks"
            case .reasoning:
                return "Tests logical reasoning, problem-solving, and analytical abilities"
            case .creative:
                return "Assesses creative writing, storytelling, and innovation"
            case .knowledge:
                return "Evaluates factual knowledge and information retrieval capabilities"
            case .code:
                return "Tests code generation, debugging, and documentation capabilities"
            }
        }
        
        /// Icon for the benchmark type
        var iconName: String {
            switch self {
            case .general: return "star"
            case .reasoning: return "brain"
            case .creative: return "paintbrush"
            case .knowledge: return "book"
            case .code: return "chevron.left.forwardslash.chevron.right"
            }
        }
        
        /// Difficulty level
        var difficulty: Difficulty {
            switch self {
            case .general: return .medium
            case .reasoning: return .hard
            case .creative: return .medium
            case .knowledge: return .medium
            case .code: return .hard
            }
        }
        
        /// Estimated time to complete
        var timeEstimate: String {
            switch self {
            case .general: return "5-10 min"
            case .reasoning: return "10-15 min"
            case .creative: return "8-12 min"
            case .knowledge: return "5-8 min"
            case .code: return "12-18 min"
            }
        }
        
        /// Difficulty levels
        enum Difficulty: String {
            case easy = "Easy"
            case medium = "Medium"
            case hard = "Hard"
        }
    }
}

// MARK: - BenchmarkViewModel

/// View model for benchmark orchestration
public class BenchmarkViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Available models for benchmarking
    @Published public var availableModels: [ModelReference] = []
    
    /// IDs of selected models
    @Published public var selectedModelIds: Set<UUID> = []
    
    /// Tasks for the current benchmark
    @Published public var benchmarkTasks: [BenchmarkTask] = []
    
    /// IDs of selected tasks
    @Published public var selectedTaskIds: Set<UUID> = []
    
    /// Metrics for the current benchmark
    @Published public var benchmarkMetrics: [BenchmarkMetric] = []
    
    /// Whether to run tasks in parallel
    @Published public var runInParallel = true
    
    /// Whether to use system prompts
    @Published public var useSystemPrompts = true
    
    /// Whether to cache results
    @Published public var cacheResults = true
    
    /// Current benchmark progress
    @Published public var benchmarkProgress: Double = 0.0
    
    /// Benchmark results
    @Published public var benchmarkResults: BenchmarkResult?
    
    /// Error message if any
    @Published public var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Service for managing model operations
    private let modelService = ModelService()
    
    /// Maps from model ID to name
    private var modelIdToNameMap: [UUID: String] = [:]
    
    // MARK: - Initialization
    
    /// Initialize the view model
    public init() {
        loadAvailableModels()
        loadBenchmark(.general)
    }
    
    // MARK: - Public Methods
    
    /// Loads available models
    public func loadAvailableModels() {
        // In a real app, would fetch from service
        let models = [
            ModelReference(name: "Claude 3 Haiku", modelType: "claude-3-haiku"),
            ModelReference(name: "Claude 3 Sonnet", modelType: "claude-3-sonnet"),
            ModelReference(name: "Claude 3 Opus", modelType: "claude-3-opus"),
            ModelReference(name: "Claude 3.5 Sonnet", modelType: "claude-3.5-sonnet")
        ]
        
        availableModels = models
        
        // Update lookup map
        modelIdToNameMap = [:]
        for model in models {
            modelIdToNameMap[model.id] = model.name
        }
        
        // Select default models
        selectedModelIds = [models[0].id, models[1].id]
    }
    
    /// Loads a specific benchmark type
    /// - Parameter benchmarkType: Type of benchmark to load
    public func loadBenchmark(_ benchmarkType: BenchmarkView.BenchmarkType) {
        // Load tasks for the benchmark
        benchmarkTasks = loadBenchmarkTasks(benchmarkType)
        
        // Select all tasks by default
        selectedTaskIds = Set(benchmarkTasks.map { $0.id })
        
        // Load metrics for the benchmark
        benchmarkMetrics = loadBenchmarkMetrics(benchmarkType)
        
        // Reset results
        benchmarkResults = nil
        benchmarkProgress = 0.0
    }
    
    /// Toggles selection for a model
    /// - Parameter modelId: Model ID to toggle
    public func toggleModelSelection(_ modelId: UUID) {
        if selectedModelIds.contains(modelId) {
            selectedModelIds.remove(modelId)
        } else {
            selectedModelIds.insert(modelId)
        }
    }
    
    /// Toggles selection for a task
    /// - Parameter taskId: Task ID to toggle
    public func toggleTaskSelection(_ taskId: UUID) {
        if selectedTaskIds.contains(taskId) {
            selectedTaskIds.remove(taskId)
        } else {
            selectedTaskIds.insert(taskId)
        }
    }
    
    /// Gets a model name from its ID
    /// - Parameter modelId: Model ID to look up
    /// - Returns: Model name or "Unknown Model"
    public func getModelName(_ modelId: UUID) -> String {
        return modelIdToNameMap[modelId] ?? "Unknown Model"
    }
    
    /// Runs the benchmark
    /// - Parameter completion: Callback with success status
    public func runBenchmark(completion: @escaping (Bool) -> Void) {
        // Reset
        benchmarkProgress = 0.0
        benchmarkResults = nil
        errorMessage = nil
        
        // Validate
        guard !selectedModelIds.isEmpty else {
            errorMessage = "Please select at least one model"
            completion(false)
            return
        }
        
        guard !selectedTaskIds.isEmpty else {
            errorMessage = "Please select at least one task"
            completion(false)
            return
        }
        
        // Get selected models and tasks
        let models = availableModels.filter { selectedModelIds.contains($0.id) }
        let tasks = benchmarkTasks.filter { selectedTaskIds.contains($0.id) }
        
        // Simulate benchmark execution
        // In a real app, this would execute the actual benchmark
        simulateBenchmarkExecution(models: models, tasks: tasks) { result in
            if let result = result {
                self.benchmarkResults = result
                completion(true)
            } else {
                self.errorMessage = "Failed to complete benchmark"
                completion(false)
            }
        }
    }
    
    /// Resets the benchmark
    public func resetBenchmark() {
        benchmarkResults = nil
        benchmarkProgress = 0.0
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    /// Loads tasks for a benchmark type
    /// - Parameter benchmarkType: Benchmark type
    /// - Returns: Array of benchmark tasks
    private func loadBenchmarkTasks(_ benchmarkType: BenchmarkView.BenchmarkType) -> [BenchmarkTask] {
        // In a real app, would load from a data source
        switch benchmarkType {
        case .general:
            return [
                BenchmarkTask(
                    name: "Question Answering",
                    description: "Tests factual responses to straightforward questions",
                    category: "General",
                    prompts: ["What causes seasons on Earth?", "Explain how vaccines work."]
                ),
                BenchmarkTask(
                    name: "Text Summarization",
                    description: "Evaluates ability to condense text while preserving key information",
                    category: "General",
                    prompts: ["Summarize the history of artificial intelligence in 3 paragraphs."]
                ),
                BenchmarkTask(
                    name: "Instruction Following",
                    description: "Tests ability to follow multi-step instructions",
                    category: "General",
                    prompts: ["List 5 capital cities in alphabetical order. Then, for each city, provide one famous landmark."]
                ),
                BenchmarkTask(
                    name: "Classification",
                    description: "Evaluates ability to classify text into categories",
                    category: "General",
                    prompts: ["Classify the following email as spam or legitimate: 'Dear Sir, I am a prince from Nigeria and I need your help...'"]
                ),
                BenchmarkTask(
                    name: "General Knowledge",
                    description: "Tests broad factual knowledge",
                    category: "Knowledge",
                    prompts: ["Name the largest countries by land mass.", "What are the main components of the solar system?"]
                )
            ]
            
        case .reasoning:
            return [
                BenchmarkTask(
                    name: "Logical Reasoning",
                    description: "Tests ability to solve logical problems",
                    category: "Reasoning",
                    prompts: ["If A is greater than B, and B is greater than C, is A necessarily greater than C? Explain."]
                ),
                BenchmarkTask(
                    name: "Mathematical Reasoning",
                    description: "Evaluates mathematical problem-solving capabilities",
                    category: "Reasoning",
                    prompts: ["If a train travels at 60 mph for 2 hours, then at 30 mph for 1 hour, what is its average speed?"]
                ),
                BenchmarkTask(
                    name: "Deductive Reasoning",
                    description: "Tests ability to make deductions from premises",
                    category: "Reasoning",
                    prompts: ["All birds have feathers. A penguin is a bird. Does a penguin have feathers? Explain your reasoning."]
                ),
                BenchmarkTask(
                    name: "Causal Reasoning",
                    description: "Evaluates understanding of cause and effect",
                    category: "Reasoning",
                    prompts: ["If increasing CO2 in the atmosphere leads to higher global temperatures, and we observe rising temperatures, can we conclude that atmospheric CO2 has increased? Explain."]
                ),
                BenchmarkTask(
                    name: "Analogical Reasoning",
                    description: "Tests ability to recognize patterns and analogies",
                    category: "Reasoning",
                    prompts: ["Fish is to water as bird is to _____? Explain your answer."]
                )
            ]
            
        case .creative:
            return [
                BenchmarkTask(
                    name: "Story Generation",
                    description: "Tests creative storytelling abilities",
                    category: "Creative",
                    prompts: ["Write a short story about a robot discovering human emotions."]
                ),
                BenchmarkTask(
                    name: "Poetry Composition",
                    description: "Evaluates poetic composition skills",
                    category: "Creative",
                    prompts: ["Compose a haiku about autumn."]
                ),
                BenchmarkTask(
                    name: "Character Creation",
                    description: "Tests ability to create rich fictional characters",
                    category: "Creative",
                    prompts: ["Create a character profile for a complex antagonist in a sci-fi setting."]
                ),
                BenchmarkTask(
                    name: "Idea Generation",
                    description: "Evaluates creative problem-solving",
                    category: "Creative",
                    prompts: ["Suggest five innovative uses for plastic waste."]
                ),
                BenchmarkTask(
                    name: "Dialogue Writing",
                    description: "Tests ability to write natural dialogue",
                    category: "Creative",
                    prompts: ["Write a dialogue between a customer and a shop owner who don't speak the same language."]
                )
            ]
            
        case .knowledge:
            return [
                BenchmarkTask(
                    name: "Historical Knowledge",
                    description: "Tests knowledge of historical events and figures",
                    category: "Knowledge",
                    prompts: ["Explain the major causes and effects of World War I."]
                ),
                BenchmarkTask(
                    name: "Scientific Knowledge",
                    description: "Evaluates understanding of scientific concepts",
                    category: "Knowledge",
                    prompts: ["Explain how DNA replication works."]
                ),
                BenchmarkTask(
                    name: "Geographic Knowledge",
                    description: "Tests knowledge of world geography",
                    category: "Knowledge",
                    prompts: ["Describe the major climate zones and where they're typically found on Earth."]
                ),
                BenchmarkTask(
                    name: "Cultural Knowledge",
                    description: "Evaluates knowledge of diverse cultures",
                    category: "Knowledge",
                    prompts: ["Describe three traditional celebrations from different cultures and their significance."]
                ),
                BenchmarkTask(
                    name: "Technical Knowledge",
                    description: "Tests knowledge of technical concepts",
                    category: "Knowledge",
                    prompts: ["Explain how public key cryptography works."]
                )
            ]
            
        case .code:
            return [
                BenchmarkTask(
                    name: "Code Generation",
                    description: "Tests ability to generate working code",
                    category: "Code",
                    prompts: ["Write a Python function to check if a string is a palindrome."]
                ),
                BenchmarkTask(
                    name: "Debugging",
                    description: "Evaluates ability to identify and fix bugs",
                    category: "Code",
                    prompts: ["Fix the bug in this code: `function sum(a, b) { retrun a + b; }`"]
                ),
                BenchmarkTask(
                    name: "Code Explanation",
                    description: "Tests ability to explain code functionality",
                    category: "Code",
                    prompts: ["Explain what this code does: `[x*x for x in range(10) if x % 2 == 0]`"]
                ),
                BenchmarkTask(
                    name: "Algorithm Design",
                    description: "Evaluates ability to design efficient algorithms",
                    category: "Code",
                    prompts: ["Design an algorithm to find the kth largest element in an unsorted array."]
                ),
                BenchmarkTask(
                    name: "Documentation",
                    description: "Tests ability to write clear code documentation",
                    category: "Code",
                    prompts: ["Write comprehensive documentation for a function that processes user authentication."]
                )
            ]
        }
    }
    
    /// Loads metrics for a benchmark type
    /// - Parameter benchmarkType: Benchmark type
    /// - Returns: Array of benchmark metrics
    private func loadBenchmarkMetrics(_ benchmarkType: BenchmarkView.BenchmarkType) -> [BenchmarkMetric] {
        // Base metrics for all benchmark types
        var metrics = [
            BenchmarkMetric(
                name: "Accuracy",
                description: "Correctness of responses relative to expected outputs",
                category: "Quality"
            ),
            BenchmarkMetric(
                name: "Relevance",
                description: "How well responses address the given prompt",
                category: "Quality"
            ),
            BenchmarkMetric(
                name: "Completeness",
                description: "Whether all aspects of the prompt are addressed",
                category: "Quality"
            ),
            BenchmarkMetric(
                name: "Consistency",
                description: "Consistency in responses across similar prompts",
                category: "Reliability"
            ),
            BenchmarkMetric(
                name: "Efficiency",
                description: "Token efficiency and response length",
                category: "Performance"
            )
        ]
        
        // Add benchmark-specific metrics
        switch benchmarkType {
        case .general:
            // General benchmark has the base metrics
            break
            
        case .reasoning:
            metrics.append(contentsOf: [
                BenchmarkMetric(
                    name: "Logical Validity",
                    description: "Evaluates the logical structure and validity of arguments",
                    category: "Reasoning"
                ),
                BenchmarkMetric(
                    name: "Step-by-Step Clarity",
                    description: "Clarity of reasoning steps and thought process",
                    category: "Reasoning"
                ),
                BenchmarkMetric(
                    name: "Alternative Consideration",
                    description: "Consideration of alternative hypotheses or solutions",
                    category: "Reasoning"
                )
            ])
            
        case .creative:
            metrics.append(contentsOf: [
                BenchmarkMetric(
                    name: "Originality",
                    description: "Uniqueness and novelty of generated content",
                    category: "Creativity"
                ),
                BenchmarkMetric(
                    name: "Coherence",
                    description: "Logical flow and structure of creative content",
                    category: "Quality"
                ),
                BenchmarkMetric(
                    name: "Emotional Impact",
                    description: "Ability to evoke emotions through creative content",
                    category: "Creativity"
                )
            ])
            
        case .knowledge:
            metrics.append(contentsOf: [
                BenchmarkMetric(
                    name: "Factual Accuracy",
                    description: "Correctness of factual information provided",
                    category: "Knowledge"
                ),
                BenchmarkMetric(
                    name: "Comprehensiveness",
                    description: "Breadth and depth of knowledge demonstrated",
                    category: "Knowledge"
                ),
                BenchmarkMetric(
                    name: "Citation Quality",
                    description: "Correct attribution and reference to sources",
                    category: "Knowledge"
                )
            ])
            
        case .code:
            metrics.append(contentsOf: [
                BenchmarkMetric(
                    name: "Correctness",
                    description: "Whether code functions as expected",
                    category: "Code"
                ),
                BenchmarkMetric(
                    name: "Efficiency",
                    description: "Computational and space efficiency of code",
                    category: "Code"
                ),
                BenchmarkMetric(
                    name: "Readability",
                    description: "Code organization, naming, and style",
                    category: "Code"
                ),
                BenchmarkMetric(
                    name: "Error Handling",
                    description: "Robustness and graceful error handling",
                    category: "Code"
                )
            ])
        }
        
        return metrics
    }
    
    /// Simulates benchmark execution
    /// - Parameters:
    ///   - models: Models to benchmark
    ///   - tasks: Tasks to execute
    ///   - completion: Callback with benchmark result
    private func simulateBenchmarkExecution(
        models: [ModelReference],
        tasks: [BenchmarkTask],
        completion: @escaping (BenchmarkResult?) -> Void
    ) {
        // Simulate processing time
        let totalSteps = models.count * tasks.count
        var currentStep = 0
        
        // Process each model and task
        var modelRankings: [ModelRanking] = []
        var categoryPerformance: [CategoryPerformance] = []
        var taskPerformance: [TaskPerformance] = []
        
        // Create a timer to simulate processing
        let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { timer in
            // Update progress
            currentStep += 1
            self.benchmarkProgress = Double(currentStep) / Double(totalSteps)
            
            // Check if complete
            if currentStep >= totalSteps {
                timer.invalidate()
                
                // Generate model rankings (simulated)
                modelRankings = models.enumerated().map { index, model in
                    let baseScore = 70.0 + Double.random(in: 0...30)
                    return ModelRanking(
                        modelId: model.id,
                        rank: index + 1,
                        score: baseScore
                    )
                }
                
                // Sort rankings by score
                modelRankings.sort { $0.score > $1.score }
                
                // Update ranks
                for (index, _) in modelRankings.enumerated() {
                    modelRankings[index].rank = index + 1
                }
                
                // Generate category performance (simulated)
                let categories = Array(Set(tasks.map { $0.category }))
                categoryPerformance = categories.map { category ->
                    CategoryPerformance in
                    let modelScores = models.map { model ->
                        ModelScore in
                        let score = 60.0 + Double.random(in: 0...40)
                        return ModelScore(modelId: model.id, score: score)
                    }
                    
                    return CategoryPerformance(
                        category: category,
                        modelScores: modelScores.sorted { $0.score > $1.score }
                    )
                }
                
                // Generate task performance (simulated)
                taskPerformance = tasks.map { task ->
                    TaskPerformance in
                    let modelScores = models.map { model ->
                        ModelScore in
                        let score = 50.0 + Double.random(in: 0...50)
                        return ModelScore(modelId: model.id, score: score)
                    }
                    
                    return TaskPerformance(
                        taskId: task.id,
                        taskName: task.name,
                        modelScores: modelScores.sorted { $0.score > $1.score }
                    )
                }
                
                // Create final result
                let result = BenchmarkResult(
                    id: UUID(),
                    name: "Benchmark Results",
                    timestamp: Date(),
                    modelRankings: modelRankings,
                    categoryPerformance: categoryPerformance,
                    taskPerformance: taskPerformance
                )
                
                completion(result)
            }
        }
        
        // Start the timer
        RunLoop.current.add(timer, forMode: .common)
    }
    
    // MARK: - Model Service
    
    /// Service for model operations
    private class ModelService {
        // This would implement actual model service functionality
        // For this example, it's a placeholder
    }
}

// MARK: - Data Models

/// Reference to a model
public struct ModelReference: Identifiable {
    public let id = UUID()
    public let name: String
    public let modelType: String
    
    public init(name: String, modelType: String) {
        self.name = name
        self.modelType = modelType
    }
}

/// Benchmark task
public struct BenchmarkTask: Identifiable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let category: String
    public let prompts: [String]
    
    public init(name: String, description: String, category: String, prompts: [String]) {
        self.name = name
        self.description = description
        self.category = category
        self.prompts = prompts
    }
}

/// Benchmark metric
public struct BenchmarkMetric: Identifiable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let category: String
    
    public init(name: String, description: String, category: String) {
        self.name = name
        self.description = description
        self.category = category
    }
}

/// Benchmark result
public struct BenchmarkResult: Identifiable {
    public let id: UUID
    public let name: String
    public let timestamp: Date
    public let modelRankings: [ModelRanking]
    public let categoryPerformance: [CategoryPerformance]
    public let taskPerformance: [TaskPerformance]
    
    public init(
        id: UUID,
        name: String,
        timestamp: Date,
        modelRankings: [ModelRanking],
        categoryPerformance: [CategoryPerformance],
        taskPerformance: [TaskPerformance]
    ) {
        self.id = id
        self.name = name
        self.timestamp = timestamp
        self.modelRankings = modelRankings
        self.categoryPerformance = categoryPerformance
        self.taskPerformance = taskPerformance
    }
}

/// Model ranking
public struct ModelRanking: Identifiable {
    public let id = UUID()
    public let modelId: UUID
    public var rank: Int
    public let score: Double
    
    public init(modelId: UUID, rank: Int, score: Double) {
        self.modelId = modelId
        self.rank = rank
        self.score = score
    }
}

/// Category performance
public struct CategoryPerformance: Identifiable {
    public let id = UUID()
    public let category: String
    public let modelScores: [ModelScore]
    
    public init(category: String, modelScores: [ModelScore]) {
        self.category = category
        self.modelScores = modelScores
    }
}

/// Task performance
public struct TaskPerformance: Identifiable {
    public let id = UUID()
    public let taskId: UUID
    public let taskName: String
    public let modelScores: [ModelScore]
    
    public init(taskId: UUID, taskName: String, modelScores: [ModelScore]) {
        self.taskId = taskId
        self.taskName = taskName
        self.modelScores = modelScores
    }
}

/// Model score
public struct ModelScore: Identifiable {
    public let id = UUID()
    public let modelId: UUID
    public let score: Double
    
    public init(modelId: UUID, score: Double) {
        self.modelId = modelId
        self.score = score
    }
}

// MARK: - Supporting Views

/// Row for benchmark detail
struct BenchmarkDetailRow: View {
    let title: String
    let value: String
    let iconName: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .frame(width: 20)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .bold()
        }
    }
}

/// Button for model selection
struct ModelCheckboxButton: View {
    let model: ModelReference
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.subheadline)
                        .bold()
                    
                    Text(model.modelType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .frame(width: 200)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Row for task selection
struct TaskCheckboxRow: View {
    let task: BenchmarkTask
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.subheadline)
                        .bold()
                    
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text(task.category)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
        }
        .buttonStyle(.plain)
    }
}

/// View for benchmark progress
struct BenchmarkProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("\(Int(progress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// View for benchmark ranking row
struct BenchmarkRankingRow: View {
    let modelName: String
    let rank: Int
    let score: Double
    
    var body: some View {
        HStack {
            Text("#\(rank)")
                .font(.subheadline)
                .bold()
                .foregroundColor(rank <= 3 ? .blue : .gray)
                .frame(width: 30)
            
            Text(modelName)
                .font(.subheadline)
            
            Spacer()
            
            Text(String(format: "%.1f", score))
                .font(.subheadline)
                .bold()
                .foregroundColor(rank <= 3 ? .blue : .gray)
        }
        .padding(.vertical, 4)
    }
}

/// View for performance category
struct PerformanceCategoryView: View {
    let category: String
    let modelScores: [(name: String, score: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category)
                .font(.subheadline)
                .bold()
            
            HStack(spacing: 0) {
                ForEach(0..<modelScores.count, id: \.self) { index in
                    let modelScore = modelScores[index]
                    
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 100)
                            
                            Rectangle()
                                .fill(index == 0 ? Color.blue : Color.green)
                                .frame(height: CGFloat(modelScore.score))
                        }
                        .frame(width: 40)
                        
                        Text(modelScore.name.components(separatedBy: " ").last ?? "")
                            .font(.caption2)
                            .lineLimit(1)
                            .frame(width: 40)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

/// Grid for task performance
struct TaskPerformanceGrid: View {
    let tasks: [String]
    let models: [String]
    let scores: [[Double]]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(spacing: 0) {
                Text("Task")
                    .font(.caption)
                    .bold()
                    .frame(width: 150, alignment: .leading)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                
                ForEach(0..<models.count, id: \.self) { index in
                    Text(models[index].components(separatedBy: " ").last ?? "")
                        .font(.caption)
                        .bold()
                        .frame(width: 80)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                }
            }
            
            // Data rows
            ForEach(0..<tasks.count, id: \.self) { taskIndex in
                HStack(spacing: 0) {
                    Text(tasks[taskIndex])
                        .font(.caption)
                        .frame(width: 150, alignment: .leading)
                        .padding(8)
                        .background(taskIndex % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                    
                    ForEach(0..<models.count, id: \.self) { modelIndex in
                        let score = scores[taskIndex][modelIndex]
                        let isBest = scores[taskIndex].firstIndex(of: scores[taskIndex].max() ?? 0) == modelIndex
                        
                        Text(String(format: "%.1f", score))
                            .font(.caption)
                            .foregroundColor(isBest ? .blue : .primary)
                            .bold(isBest)
                            .frame(width: 80)
                            .padding(8)
                            .background(taskIndex % 2 == 0 ? Color.white : Color.gray.opacity(0.05))
                    }
                }
            }
        }
        .border(Color.gray.opacity(0.2), width: 1)
        .fixedSize()
    }
}

// MARK: - Preview

struct BenchmarkView_Previews: PreviewProvider {
    static var previews: some View {
        BenchmarkView()
    }
}
