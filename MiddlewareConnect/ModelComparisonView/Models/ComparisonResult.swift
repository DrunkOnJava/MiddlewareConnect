import Foundation
import LLMServiceProvider

/// Comprehensive result structure for model comparison outcomes
///
/// Provides a framework for organizing, analyzing, and presenting
/// comparison results between different LLM models across metrics.
public struct ComparisonResult: Identifiable, Codable, Equatable {
    /// Unique identifier for the comparison
    public let id: UUID
    
    /// Name of the comparison experiment
    public let name: String
    
    /// Description of the comparison
    public let description: String
    
    /// When the comparison was performed
    public let timestamp: Date
    
    /// Models that were compared
    public let models: [ModelReference]
    
    /// Prompts that were used for testing
    public let prompts: [PromptReference]
    
    /// Metrics that were evaluated
    public let metrics: [MetricReference]
    
    /// Individual result data points
    public let results: [ResultPoint]
    
    /// Summary statistics for the comparison
    public let summary: SummaryStatistics
    
    /// Tags for categorizing the comparison
    public let tags: [String]
    
    /// Creates a new comparison result
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Comparison name
    ///   - description: Description of the comparison
    ///   - timestamp: When performed (defaults to now)
    ///   - models: Models compared
    ///   - prompts: Prompts used
    ///   - metrics: Metrics evaluated
    ///   - results: Individual result points
    ///   - summary: Summary statistics
    ///   - tags: Categorization tags
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        timestamp: Date = Date(),
        models: [ModelReference],
        prompts: [PromptReference],
        metrics: [MetricReference],
        results: [ResultPoint],
        summary: SummaryStatistics,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.timestamp = timestamp
        self.models = models
        self.prompts = prompts
        self.metrics = metrics
        self.results = results
        self.summary = summary
        self.tags = tags
    }
    
    /// Reference to a model that was evaluated
    public struct ModelReference: Identifiable, Codable, Equatable {
        /// Unique identifier for the model
        public let id: UUID
        
        /// Name of the model
        public let name: String
        
        /// Model type identifier
        public let modelType: String
        
        /// Model configuration used
        public let configuration: ModelConfiguration
        
        /// Creates a model reference
        /// - Parameters:
        ///   - id: Unique identifier
        ///   - name: Model name
        ///   - modelType: Type identifier
        ///   - configuration: Configuration used
        public init(
            id: UUID = UUID(),
            name: String,
            modelType: String,
            configuration: ModelConfiguration
        ) {
            self.id = id
            self.name = name
            self.modelType = modelType
            self.configuration = configuration
        }
    }
    
    /// Configuration for a model
    public struct ModelConfiguration: Codable, Equatable {
        /// Model parameters
        public let parameters: [String: Double]
        
        /// Context size in tokens
        public let contextSize: Int
        
        /// Additional configuration options
        public let options: [String: String]
        
        /// Creates a model configuration
        /// - Parameters:
        ///   - parameters: Model parameters
        ///   - contextSize: Context size
        ///   - options: Additional options
        public init(
            parameters: [String: Double],
            contextSize: Int,
            options: [String: String] = [:]
        ) {
            self.parameters = parameters
            self.contextSize = contextSize
            self.options = options
        }
    }
    
    /// Reference to a prompt that was used
    public struct PromptReference: Identifiable, Codable, Equatable {
        /// Unique identifier for the prompt
        public let id: UUID
        
        /// Name of the prompt
        public let name: String
        
        /// Category of the prompt
        public let category: String
        
        /// Text content of the prompt
        public let content: String
        
        /// Expected outputs for evaluation
        public let expectedOutputs: [String]?
        
        /// Difficulty rating of the prompt
        public let difficulty: PromptDifficulty
        
        /// Creates a prompt reference
        /// - Parameters:
        ///   - id: Unique identifier
        ///   - name: Prompt name
        ///   - category: Prompt category
        ///   - content: Prompt text
        ///   - expectedOutputs: Expected outputs
        ///   - difficulty: Difficulty rating
        public init(
            id: UUID = UUID(),
            name: String,
            category: String,
            content: String,
            expectedOutputs: [String]? = nil,
            difficulty: PromptDifficulty = .medium
        ) {
            self.id = id
            self.name = name
            self.category = category
            self.content = content
            self.expectedOutputs = expectedOutputs
            self.difficulty = difficulty
        }
        
        /// Difficulty levels for prompts
        public enum PromptDifficulty: String, Codable, CaseIterable {
            /// Simple, straightforward prompt
            case simple
            
            /// Moderately complex prompt
            case medium
            
            /// Complex, challenging prompt
            case complex
            
            /// Very difficult, adversarial prompt
            case challenging
        }
    }
    
    /// Reference to a metric that was evaluated
    public struct MetricReference: Identifiable, Codable, Equatable {
        /// Unique identifier for the metric
        public let id: UUID
        
        /// Name of the metric
        public let name: String
        
        /// Category of the metric
        public let category: String
        
        /// Creates a metric reference
        /// - Parameters:
        ///   - id: Unique identifier
        ///   - name: Metric name
        ///   - category: Metric category
        public init(
            id: UUID = UUID(),
            name: String,
            category: String
        ) {
            self.id = id
            self.name = name
            self.category = category
        }
    }
    
    /// Single comparison result data point
    public struct ResultPoint: Identifiable, Codable, Equatable {
        /// Unique identifier for the result
        public let id: UUID
        
        /// Model that produced the result
        public let modelId: UUID
        
        /// Prompt that was used
        public let promptId: UUID
        
        /// Metric that was evaluated
        public let metricId: UUID
        
        /// Score for the metric
        public let score: Double
        
        /// Normalized score (0-1)
        public let normalizedScore: Double
        
        /// Raw output from the model
        public let modelOutput: String?
        
        /// Metadata about the result
        public let metadata: [String: String]
        
        /// Creates a result point
        /// - Parameters:
        ///   - id: Unique identifier
        ///   - modelId: Model reference
        ///   - promptId: Prompt reference
        ///   - metricId: Metric reference
        ///   - score: Raw score
        ///   - normalizedScore: Normalized score
        ///   - modelOutput: Model output text
        ///   - metadata: Additional metadata
        public init(
            id: UUID = UUID(),
            modelId: UUID,
            promptId: UUID,
            metricId: UUID,
            score: Double,
            normalizedScore: Double,
            modelOutput: String? = nil,
            metadata: [String: String] = [:]
        ) {
            self.id = id
            self.modelId = modelId
            self.promptId = promptId
            self.metricId = metricId
            self.score = score
            self.normalizedScore = normalizedScore
            self.modelOutput = modelOutput
            self.metadata = metadata
        }
    }
    
    /// Summary statistics for comparison results
    public struct SummaryStatistics: Codable, Equatable {
        /// Overall rankings of models
        public let modelRankings: [ModelRanking]
        
        /// Average scores by metric
        public let metricAverages: [MetricAverage]
        
        /// Performance by category
        public let categoryPerformance: [CategoryPerformance]
        
        /// Strengths and weaknesses analysis
        public let analysis: StrengthsWeaknesses
        
        /// Creates summary statistics
        /// - Parameters:
        ///   - modelRankings: Model rankings
        ///   - metricAverages: Metric averages
        ///   - categoryPerformance: Category performance
        ///   - analysis: Strengths and weaknesses
        public init(
            modelRankings: [ModelRanking],
            metricAverages: [MetricAverage],
            categoryPerformance: [CategoryPerformance],
            analysis: StrengthsWeaknesses
        ) {
            self.modelRankings = modelRankings
            self.metricAverages = metricAverages
            self.categoryPerformance = categoryPerformance
            self.analysis = analysis
        }
    }
    
    /// Ranking for a model across metrics
    public struct ModelRanking: Codable, Equatable {
        /// Model identifier
        public let modelId: UUID
        
        /// Overall rank (1 is best)
        public let rank: Int
        
        /// Aggregate score
        public let overallScore: Double
        
        /// Percentile compared to other models
        public let percentile: Double
        
        /// Creates a model ranking
        /// - Parameters:
        ///   - modelId: Model identifier
        ///   - rank: Overall rank
        ///   - overallScore: Aggregate score
        ///   - percentile: Performance percentile
        public init(
            modelId: UUID,
            rank: Int,
            overallScore: Double,
            percentile: Double
        ) {
            self.modelId = modelId
            self.rank = rank
            self.overallScore = overallScore
            self.percentile = percentile
        }
    }
    
    /// Average scores for a specific metric
    public struct MetricAverage: Codable, Equatable {
        /// Metric identifier
        public let metricId: UUID
        
        /// Average scores by model
        public let averagesByModel: [UUID: Double]
        
        /// Overall average across models
        public let overallAverage: Double
        
        /// Standard deviation
        public let standardDeviation: Double
        
        /// Creates a metric average
        /// - Parameters:
        ///   - metricId: Metric identifier
        ///   - averagesByModel: Averages by model
        ///   - overallAverage: Overall average
        ///   - standardDeviation: Standard deviation
        public init(
            metricId: UUID,
            averagesByModel: [UUID: Double],
            overallAverage: Double,
            standardDeviation: Double
        ) {
            self.metricId = metricId
            self.averagesByModel = averagesByModel
            self.overallAverage = overallAverage
            self.standardDeviation = standardDeviation
        }
    }
    
    /// Performance summary for a category
    public struct CategoryPerformance: Codable, Equatable {
        /// Category name
        public let category: String
        
        /// Performance scores by model
        public let scoresByModel: [UUID: Double]
        
        /// Best model for this category
        public let bestModelId: UUID
        
        /// Creates a category performance
        /// - Parameters:
        ///   - category: Category name
        ///   - scoresByModel: Scores by model
        ///   - bestModelId: Best performing model
        public init(
            category: String,
            scoresByModel: [UUID: Double],
            bestModelId: UUID
        ) {
            self.category = category
            self.scoresByModel = scoresByModel
            self.bestModelId = bestModelId
        }
    }
    
    /// Analysis of strengths and weaknesses
    public struct StrengthsWeaknesses: Codable, Equatable {
        /// Strengths by model
        public let strengths: [UUID: [Insight]]
        
        /// Weaknesses by model
        public let weaknesses: [UUID: [Insight]]
        
        /// Overall insights
        public let overallInsights: [String]
        
        /// Creates strengths and weaknesses analysis
        /// - Parameters:
        ///   - strengths: Strengths by model
        ///   - weaknesses: Weaknesses by model
        ///   - overallInsights: Overall insights
        public init(
            strengths: [UUID: [Insight]],
            weaknesses: [UUID: [Insight]],
            overallInsights: [String]
        ) {
            self.strengths = strengths
            self.weaknesses = weaknesses
            self.overallInsights = overallInsights
        }
        
        /// Single analytical insight
        public struct Insight: Codable, Equatable {
            /// Insight description
            public let description: String
            
            /// Related metrics
            public let relatedMetrics: [UUID]
            
            /// Confidence in the insight
            public let confidence: Double
            
            /// Creates an insight
            /// - Parameters:
            ///   - description: Insight description
            ///   - relatedMetrics: Related metrics
            ///   - confidence: Confidence score
            public init(
                description: String,
                relatedMetrics: [UUID],
                confidence: Double
            ) {
                self.description = description
                self.relatedMetrics = relatedMetrics
                self.confidence = confidence
            }
        }
    }
    
    // MARK: - Analysis Methods
    
    /// Gets average scores for each model
    /// - Returns: Dictionary of model IDs to average scores
    public func getAverageScoresByModel() -> [UUID: Double] {
        var totals: [UUID: Double] = [:]
        var counts: [UUID: Int] = [:]
        
        for result in results {
            totals[result.modelId, default: 0] += result.normalizedScore
            counts[result.modelId, default: 0] += 1
        }
        
        var averages: [UUID: Double] = [:]
        for (modelId, total) in totals {
            if let count = counts[modelId], count > 0 {
                averages[modelId] = total / Double(count)
            }
        }
        
        return averages
    }
    
    /// Gets the best-performing model overall
    /// - Returns: Model reference for the best model
    public func getBestModel() -> ModelReference? {
        let rankings = summary.modelRankings.sorted { $0.rank < $1.rank }
        guard let bestRanking = rankings.first else { return nil }
        return models.first { $0.id == bestRanking.modelId }
    }
    
    /// Gets the best model for a specific metric
    /// - Parameter metricId: Metric to check
    /// - Returns: Best model for the metric
    public func getBestModelForMetric(metricId: UUID) -> ModelReference? {
        // Get all results for this metric
        let metricResults = results.filter { $0.metricId == metricId }
        
        // Group by model and calculate averages
        var averagesByModel: [UUID: Double] = [:]
        var countsByModel: [UUID: Int] = [:]
        
        for result in metricResults {
            averagesByModel[result.modelId, default: 0] += result.normalizedScore
            countsByModel[result.modelId, default: 0] += 1
        }
        
        for (modelId, count) in countsByModel {
            if count > 0 {
                averagesByModel[modelId] = averagesByModel[modelId]! / Double(count)
            }
        }
        
        // Find model with highest average
        guard let bestModelId = averagesByModel.max(by: { $0.value < $1.value })?.key else {
            return nil
        }
        
        return models.first { $0.id == bestModelId }
    }
    
    /// Gets performance difference between two models
    /// - Parameters:
    ///   - modelId1: First model ID
    ///   - modelId2: Second model ID
    /// - Returns: Difference statistics
    public func getModelDifference(modelId1: UUID, modelId2: UUID) -> ModelDifference {
        // Get results for both models
        let model1Results = results.filter { $0.modelId == modelId1 }
        let model2Results = results.filter { $0.modelId == modelId2 }
        
        // Calculate differences by metric
        var differencesByMetric: [UUID: Double] = [:]
        var significantlyBetterMetrics: [UUID] = []
        var significantlyWorseMetrics: [UUID] = []
        
        // Process all metrics
        for metric in metrics {
            let model1MetricResults = model1Results.filter { $0.metricId == metric.id }
            let model2MetricResults = model2Results.filter { $0.metricId == metric.id }
            
            // Calculate average scores for this metric
            let model1Avg = model1MetricResults.map { $0.normalizedScore }.reduce(0, +) / 
                Double(max(1, model1MetricResults.count))
            let model2Avg = model2MetricResults.map { $0.normalizedScore }.reduce(0, +) / 
                Double(max(1, model2MetricResults.count))
            
            // Calculate difference (positive means model1 is better)
            let difference = model1Avg - model2Avg
            differencesByMetric[metric.id] = difference
            
            // Check for significant differences (> 10%)
            if difference > 0.1 {
                significantlyBetterMetrics.append(metric.id)
            } else if difference < -0.1 {
                significantlyWorseMetrics.append(metric.id)
            }
        }
        
        // Calculate overall difference
        let overallDifference = differencesByMetric.values.reduce(0, +) / 
            Double(max(1, differencesByMetric.count))
        
        return ModelDifference(
            model1Id: modelId1,
            model2Id: modelId2,
            overallDifference: overallDifference,
            differencesByMetric: differencesByMetric,
            significantlyBetterMetrics: significantlyBetterMetrics,
            significantlyWorseMetrics: significantlyWorseMetrics
        )
    }
    
    /// Performance difference between two models
    public struct ModelDifference: Codable, Equatable {
        /// First model ID
        public let model1Id: UUID
        
        /// Second model ID
        public let model2Id: UUID
        
        /// Overall percentage difference
        public let overallDifference: Double
        
        /// Differences by specific metric
        public let differencesByMetric: [UUID: Double]
        
        /// Metrics where model1 is significantly better
        public let significantlyBetterMetrics: [UUID]
        
        /// Metrics where model1 is significantly worse
        public let significantlyWorseMetrics: [UUID]
        
        /// Creates a model difference
        /// - Parameters:
        ///   - model1Id: First model ID
        ///   - model2Id: Second model ID
        ///   - overallDifference: Overall difference
        ///   - differencesByMetric: Differences by metric
        ///   - significantlyBetterMetrics: Better metrics
        ///   - significantlyWorseMetrics: Worse metrics
        public init(
            model1Id: UUID,
            model2Id: UUID,
            overallDifference: Double,
            differencesByMetric: [UUID: Double],
            significantlyBetterMetrics: [UUID],
            significantlyWorseMetrics: [UUID]
        ) {
            self.model1Id = model1Id
            self.model2Id = model2Id
            self.overallDifference = overallDifference
            self.differencesByMetric = differencesByMetric
            self.significantlyBetterMetrics = significantlyBetterMetrics
            self.significantlyWorseMetrics = significantlyWorseMetrics
        }
    }
    
    /// Returns analysis for a specific prompt category
    /// - Parameter category: Prompt category to analyze
    /// - Returns: Category analysis with model rankings
    public func analyzePromptCategory(category: String) -> CategoryAnalysis {
        // Get prompts in this category
        let categoryPrompts = prompts.filter { $0.category == category }
        guard !categoryPrompts.isEmpty else {
            return CategoryAnalysis(
                category: category,
                modelRankings: [],
                averageScores: [:],
                bestModelId: nil,
                worstModelId: nil
            )
        }
        
        // Get results for these prompts
        let promptIds = categoryPrompts.map { $0.id }
        let categoryResults = results.filter { promptIds.contains($0.promptId) }
        
        // Calculate average scores by model
        var scoresByModel: [UUID: [Double]] = [:]
        for result in categoryResults {
            scoresByModel[result.modelId, default: []].append(result.normalizedScore)
        }
        
        // Calculate average score for each model
        var averageScores: [UUID: Double] = [:]
        for (modelId, scores) in scoresByModel {
            averageScores[modelId] = scores.reduce(0, +) / Double(scores.count)
        }
        
        // Rank models
        let modelRankings = averageScores.sorted { $0.value > $1.value }
            .enumerated()
            .map { idx, entry in
                CategoryModelRanking(
                    modelId: entry.key,
                    rank: idx + 1,
                    averageScore: entry.value
                )
            }
        
        // Find best and worst models
        let bestModelId = modelRankings.first?.modelId
        let worstModelId = modelRankings.last?.modelId
        
        return CategoryAnalysis(
            category: category,
            modelRankings: modelRankings,
            averageScores: averageScores,
            bestModelId: bestModelId,
            worstModelId: worstModelId
        )
    }
    
    /// Analysis for a prompt category
    public struct CategoryAnalysis: Codable, Equatable {
        /// Category name
        public let category: String
        
        /// Rankings of models
        public let modelRankings: [CategoryModelRanking]
        
        /// Average scores by model
        public let averageScores: [UUID: Double]
        
        /// Best model for this category
        public let bestModelId: UUID?
        
        /// Worst model for this category
        public let worstModelId: UUID?
        
        /// Creates a category analysis
        /// - Parameters:
        ///   - category: Category name
        ///   - modelRankings: Model rankings
        ///   - averageScores: Average scores
        ///   - bestModelId: Best model ID
        ///   - worstModelId: Worst model ID
        public init(
            category: String,
            modelRankings: [CategoryModelRanking],
            averageScores: [UUID: Double],
            bestModelId: UUID?,
            worstModelId: UUID?
        ) {
            self.category = category
            self.modelRankings = modelRankings
            self.averageScores = averageScores
            self.bestModelId = bestModelId
            self.worstModelId = worstModelId
        }
    }
    
    /// Model ranking within a category
    public struct CategoryModelRanking: Codable, Equatable {
        /// Model identifier
        public let modelId: UUID
        
        /// Rank within category
        public let rank: Int
        
        /// Average score
        public let averageScore: Double
        
        /// Creates a category model ranking
        /// - Parameters:
        ///   - modelId: Model identifier
        ///   - rank: Rank position
        ///   - averageScore: Average score
        public init(
            modelId: UUID,
            rank: Int,
            averageScore: Double
        ) {
            self.modelId = modelId
            self.rank = rank
            self.averageScore = averageScore
        }
    }
    
    /// Formats a comparison result as a summary report
    /// - Returns: Formatted string report
    public func generateSummaryReport() -> String {
        var report = "# Comparison Summary: \(name)\n\n"
        report += "\(description)\n\n"
        
        // Date formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        report += "Date: \(dateFormatter.string(from: timestamp))\n\n"
        
        // Models summary
        report += "## Models Compared\n\n"
        for model in models {
            report += "- **\(model.name)** (\(model.modelType))\n"
        }
        report += "\n"
        
        // Rankings
        report += "## Overall Rankings\n\n"
        let sortedRankings = summary.modelRankings.sorted { $0.rank < $1.rank }
        for ranking in sortedRankings {
            let modelName = models.first { $0.id == ranking.modelId }?.name ?? "Unknown Model"
            report += "\(ranking.rank). **\(modelName)** - Score: \(String(format: "%.2f", ranking.overallScore)) (\(String(format: "%.0f", ranking.percentile))th percentile)\n"
        }
        report += "\n"
        
        // Key insights
        report += "## Key Insights\n\n"
        for insight in summary.analysis.overallInsights {
            report += "- \(insight)\n"
        }
        report += "\n"
        
        // Best in category
        report += "## Best in Category\n\n"
        for category in summary.categoryPerformance {
            let bestModelName = models.first { $0.id == category.bestModelId }?.name ?? "Unknown Model"
            report += "- **\(category.category)**: \(bestModelName)\n"
        }
        
        return report
    }
    
    /// Exports the comparison result to JSON
    /// - Returns: JSON string representation
    public func exportToJson() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    /// Creates a comparison result from JSON
    /// - Parameter json: JSON string representation
    /// - Returns: ComparisonResult or nil if parsing fails
    public static func fromJson(_ json: String) -> ComparisonResult? {
        guard let data = json.data(using: .utf8) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(ComparisonResult.self, from: data)
        } catch {
            return nil
        }
    }
}
