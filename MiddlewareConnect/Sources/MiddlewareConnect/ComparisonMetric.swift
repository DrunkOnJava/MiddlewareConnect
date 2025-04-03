import Foundation
import LLMServiceProvider

/// Comprehensive metrics system for evaluating and comparing LLM performance
///
/// Provides a structured framework for defining, calculating, and visualizing
/// comparison metrics across different models and evaluation dimensions.
public struct ComparisonMetric: Identifiable, Codable, Equatable {
    /// Unique identifier for the metric
    public let id: UUID
    
    /// Display name for the metric
    public let name: String
    
    /// Extended description of what the metric measures
    public let description: String
    
    /// Category of the metric
    public let category: MetricCategory
    
    /// Calculation method for the metric
    public let calculationMethod: CalculationMethod
    
    /// Value range for the metric
    public let range: ValueRange
    
    /// Interpretation guidance for scores
    public let interpretation: InterpretationGuide
    
    /// Whether higher values are better
    public let higherIsBetter: Bool
    
    /// Visualization properties for display
    public let visualProperties: VisualizationProperties
    
    /// Creates a new comparison metric
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Display name
    ///   - description: Description of the metric
    ///   - category: Metric category
    ///   - calculationMethod: Method for computing the metric
    ///   - range: Value range for the metric
    ///   - interpretation: Guidance for interpreting values
    ///   - higherIsBetter: Whether higher values indicate better performance
    ///   - visualProperties: Properties for visualization
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: MetricCategory,
        calculationMethod: CalculationMethod,
        range: ValueRange,
        interpretation: InterpretationGuide,
        higherIsBetter: Bool = true,
        visualProperties: VisualizationProperties = .default
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.calculationMethod = calculationMethod
        self.range = range
        self.interpretation = interpretation
        self.higherIsBetter = higherIsBetter
        self.visualProperties = visualProperties
    }
    
    /// Categories for organizing metrics
    public enum MetricCategory: String, Codable, CaseIterable {
        /// Evaluation of output quality
        case quality
        
        /// Computational efficiency metrics
        case performance
        
        /// Measures of reasoning capability
        case reasoning
        
        /// Task-specific metrics
        case taskSpecific
        
        /// Consistency of outputs
        case consistency
        
        /// Evaluation of ethical considerations
        case ethics
        
        /// Risk evaluation metrics
        case risk
        
        /// Custom category with a specified name
        case custom(String)
        
        /// Display name for the category
        public var displayName: String {
            switch self {
            case .quality: return "Quality"
            case .performance: return "Performance"
            case .reasoning: return "Reasoning"
            case .taskSpecific: return "Task-Specific"
            case .consistency: return "Consistency"
            case .ethics: return "Ethics"
            case .risk: return "Risk"
            case .custom(let name): return name
            }
        }
        
        /// Color for visualization
        public var color: Color {
            switch self {
            case .quality: return .blue
            case .performance: return .green
            case .reasoning: return .purple
            case .taskSpecific: return .orange
            case .consistency: return .cyan
            case .ethics: return .indigo
            case .risk: return .red
            case .custom: return .gray
            }
        }
        
        /// Icon for the category
        public var icon: String {
            switch self {
            case .quality: return "star.fill"
            case .performance: return "speedometer"
            case .reasoning: return "brain"
            case .taskSpecific: return "checklist"
            case .consistency: return "repeat"
            case .ethics: return "shield"
            case .risk: return "exclamationmark.triangle"
            case .custom: return "tag"
            }
        }
        
        /// Coding keys for serialization
        private enum CodingKeys: String, CodingKey {
            case rawValue, customName
        }
        
        /// Custom decoder implementation
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let rawValue = try container.decode(String.self, forKey: .rawValue)
            
            switch rawValue {
            case "quality": self = .quality
            case "performance": self = .performance
            case "reasoning": self = .reasoning
            case "taskSpecific": self = .taskSpecific
            case "consistency": self = .consistency
            case "ethics": self = .ethics
            case "risk": self = .risk
            case "custom":
                let customName = try container.decode(String.self, forKey: .customName)
                self = .custom(customName)
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .rawValue,
                    in: container,
                    debugDescription: "Invalid metric category: \(rawValue)"
                )
            }
        }
        
        /// Custom encoder implementation
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .custom(let name):
                try container.encode("custom", forKey: .rawValue)
                try container.encode(name, forKey: .customName)
            default:
                try container.encode(self.rawValue, forKey: .rawValue)
            }
        }
    }
    
    /// Methods for calculating metric values
    public enum CalculationMethod: Codable, Equatable {
        /// Direct score from model output
        case direct
        
        /// Average of multiple runs or samples
        case average
        
        /// Model comparison with reference outputs
        case reference(referenceType: ReferenceType)
        
        /// Statistical analysis of multiple outputs
        case statistical(statisticalMethod: StatisticalMethod)
        
        /// Automated evaluation using predefined criteria
        case automated(evaluator: EvaluatorType)
        
        /// Human evaluation scores
        case human
        
        /// Custom calculation with a specified method
        case custom(String)
        
        /// Reference types for comparisons
        public enum ReferenceType: String, Codable {
            /// Expert-created gold standard
            case goldStandard
            
            /// Outputs from another model
            case modelGenerated
            
            /// Human-generated ground truth
            case humanGenerated
        }
        
        /// Statistical methods for calculations
        public enum StatisticalMethod: String, Codable {
            /// Standard deviation analysis
            case standardDeviation
            
            /// Mean absolute error
            case meanAbsoluteError
            
            /// Root mean square error
            case rootMeanSquareError
            
            /// Correlation coefficients
            case correlation
            
            /// F1 score calculations
            case f1Score
        }
        
        /// Types of automated evaluators
        public enum EvaluatorType: String, Codable {
            /// BLEU score for text similarity
            case bleu
            
            /// ROUGE score for text similarity
            case rouge
            
            /// BERT-based similarity scoring
            case bert
            
            /// Embedding-based similarity
            case embedding
            
            /// Custom evaluator
            case custom(String)
            
            /// Coding keys for serialization
            private enum CodingKeys: String, CodingKey {
                case rawValue, customName
            }
            
            /// Custom decoder implementation
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let rawValue = try container.decode(String.self, forKey: .rawValue)
                
                switch rawValue {
                case "bleu": self = .bleu
                case "rouge": self = .rouge
                case "bert": self = .bert
                case "embedding": self = .embedding
                case "custom":
                    let customName = try container.decode(String.self, forKey: .customName)
                    self = .custom(customName)
                default:
                    throw DecodingError.dataCorruptedError(
                        forKey: .rawValue,
                        in: container,
                        debugDescription: "Invalid evaluator type: \(rawValue)"
                    )
                }
            }
            
            /// Custom encoder implementation
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                
                switch self {
                case .custom(let name):
                    try container.encode("custom", forKey: .rawValue)
                    try container.encode(name, forKey: .customName)
                default:
                    try container.encode(self.rawValue, forKey: .rawValue)
                }
            }
        }
        
        /// Coding keys for serialization
        private enum CodingKeys: String, CodingKey {
            case method, referenceType, statisticalMethod, evaluator, customName
        }
        
        /// Custom decoder implementation
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let method = try container.decode(String.self, forKey: .method)
            
            switch method {
            case "direct": self = .direct
            case "average": self = .average
            case "reference":
                let referenceType = try container.decode(ReferenceType.self, forKey: .referenceType)
                self = .reference(referenceType: referenceType)
            case "statistical":
                let statisticalMethod = try container.decode(StatisticalMethod.self, forKey: .statisticalMethod)
                self = .statistical(statisticalMethod: statisticalMethod)
            case "automated":
                let evaluator = try container.decode(EvaluatorType.self, forKey: .evaluator)
                self = .automated(evaluator: evaluator)
            case "human": self = .human
            case "custom":
                let customName = try container.decode(String.self, forKey: .customName)
                self = .custom(customName)
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .method,
                    in: container,
                    debugDescription: "Invalid calculation method: \(method)"
                )
            }
        }
        
        /// Custom encoder implementation
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .direct:
                try container.encode("direct", forKey: .method)
            case .average:
                try container.encode("average", forKey: .method)
            case .reference(let referenceType):
                try container.encode("reference", forKey: .method)
                try container.encode(referenceType, forKey: .referenceType)
            case .statistical(let statisticalMethod):
                try container.encode("statistical", forKey: .method)
                try container.encode(statisticalMethod, forKey: .statisticalMethod)
            case .automated(let evaluator):
                try container.encode("automated", forKey: .method)
                try container.encode(evaluator, forKey: .evaluator)
            case .human:
                try container.encode("human", forKey: .method)
            case .custom(let name):
                try container.encode("custom", forKey: .method)
                try container.encode(name, forKey: .customName)
            }
        }
    }
    
    /// Value range for a metric
    public struct ValueRange: Codable, Equatable {
        /// Minimum possible value
        public let minimumValue: Double
        
        /// Maximum possible value
        public let maximumValue: Double
        
        /// Whether values are discrete or continuous
        public let isDiscrete: Bool
        
        /// Step size for discrete values
        public let discreteStep: Double?
        
        /// Creates a new value range
        /// - Parameters:
        ///   - minimumValue: Minimum possible value
        ///   - maximumValue: Maximum possible value
        ///   - isDiscrete: Whether values are discrete
        ///   - discreteStep: Step size for discrete values
        public init(
            minimumValue: Double,
            maximumValue: Double,
            isDiscrete: Bool = false,
            discreteStep: Double? = nil
        ) {
            self.minimumValue = minimumValue
            self.maximumValue = maximumValue
            self.isDiscrete = isDiscrete
            self.discreteStep = isDiscrete ? (discreteStep ?? 1.0) : nil
        }
        
        /// Standard 0-1 range
        public static let zeroToOne = ValueRange(minimumValue: 0.0, maximumValue: 1.0)
        
        /// Standard 0-100 range
        public static let percentage = ValueRange(minimumValue: 0.0, maximumValue: 100.0)
        
        /// Five-point rating scale
        public static let fivePoint = ValueRange(minimumValue: 1.0, maximumValue: 5.0, isDiscrete: true)
        
        /// Ten-point rating scale
        public static let tenPoint = ValueRange(minimumValue: 1.0, maximumValue: 10.0, isDiscrete: true)
    }
    
    /// Guidance for interpreting metric values
    public struct InterpretationGuide: Codable, Equatable {
        /// Description of excellent performance
        public let excellent: String
        
        /// Description of good performance
        public let good: String
        
        /// Description of fair performance
        public let fair: String
        
        /// Description of poor performance
        public let poor: String
        
        /// Threshold for excellent performance
        public let excellentThreshold: Double
        
        /// Threshold for good performance
        public let goodThreshold: Double
        
        /// Threshold for fair performance
        public let fairThreshold: Double
        
        /// Creates a new interpretation guide
        /// - Parameters:
        ///   - excellent: Description of excellent performance
        ///   - good: Description of good performance
        ///   - fair: Description of fair performance
        ///   - poor: Description of poor performance
        ///   - excellentThreshold: Threshold for excellent
        ///   - goodThreshold: Threshold for good
        ///   - fairThreshold: Threshold for fair
        public init(
            excellent: String,
            good: String,
            fair: String,
            poor: String,
            excellentThreshold: Double,
            goodThreshold: Double,
            fairThreshold: Double
        ) {
            self.excellent = excellent
            self.good = good
            self.fair = fair
            self.poor = poor
            self.excellentThreshold = excellentThreshold
            self.goodThreshold = goodThreshold
            self.fairThreshold = fairThreshold
        }
        
        /// Gets interpretation for a specific value
        /// - Parameter value: Value to interpret
        /// - Returns: Appropriate interpretation text
        public func interpretationFor(value: Double) -> String {
            if value >= excellentThreshold {
                return excellent
            } else if value >= goodThreshold {
                return good
            } else if value >= fairThreshold {
                return fair
            } else {
                return poor
            }
        }
        
        /// Gets performance level for a value
        /// - Parameter value: Value to evaluate
        /// - Returns: Performance level
        public func performanceLevelFor(value: Double) -> PerformanceLevel {
            if value >= excellentThreshold {
                return .excellent
            } else if value >= goodThreshold {
                return .good
            } else if value >= fairThreshold {
                return .fair
            } else {
                return .poor
            }
        }
        
        /// Performance level categories
        public enum PerformanceLevel: String, Codable {
            /// Excellent performance
            case excellent
            
            /// Good performance
            case good
            
            /// Fair performance
            case fair
            
            /// Poor performance
            case poor
            
            /// Color for the performance level
            public var color: Color {
                switch self {
                case .excellent: return .green
                case .good: return .blue
                case .fair: return .orange
                case .poor: return .red
                }
            }
        }
    }
    
    /// Visual properties for displaying the metric
    public struct VisualizationProperties: Codable, Equatable {
        /// Primary color for the metric
        public let primaryColor: Color
        
        /// Secondary color for the metric
        public let secondaryColor: Color
        
        /// Icon for the metric
        public let icon: String
        
        /// Recommended chart type
        public let recommendedChartType: ChartType
        
        /// Default visualization properties
        public static let `default` = VisualizationProperties(
            primaryColor: .blue,
            secondaryColor: .gray,
            icon: "chart.bar.fill",
            recommendedChartType: .bar
        )
        
        /// Creates visual properties for a metric
        /// - Parameters:
        ///   - primaryColor: Primary display color
        ///   - secondaryColor: Secondary display color
        ///   - icon: System icon name
        ///   - recommendedChartType: Suggested chart type
        public init(
            primaryColor: Color,
            secondaryColor: Color,
            icon: String,
            recommendedChartType: ChartType
        ) {
            self.primaryColor = primaryColor
            self.secondaryColor = secondaryColor
            self.icon = icon
            self.recommendedChartType = recommendedChartType
        }
        
        /// Recommended chart types
        public enum ChartType: String, Codable {
            /// Bar chart
            case bar
            
            /// Line chart
            case line
            
            /// Radar/spider chart
            case radar
            
            /// Pie chart
            case pie
            
            /// Scatter plot
            case scatter
            
            /// Heat map visualization
            case heatmap
        }
    }
    
    /// Placeholder type for color
    public struct Color: Codable, Equatable {
        /// Red component (0-1)
        public let red: Double
        
        /// Green component (0-1)
        public let green: Double
        
        /// Blue component (0-1)
        public let blue: Double
        
        /// Alpha/opacity component (0-1)
        public let alpha: Double
        
        /// Creates a new color
        /// - Parameters:
        ///   - red: Red component (0-1)
        ///   - green: Green component (0-1)
        ///   - blue: Blue component (0-1)
        ///   - alpha: Alpha component (0-1)
        public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }
        
        /// Blue color
        public static let blue = Color(red: 0.0, green: 0.0, blue: 1.0)
        
        /// Green color
        public static let green = Color(red: 0.0, green: 0.8, blue: 0.0)
        
        /// Red color
        public static let red = Color(red: 1.0, green: 0.0, blue: 0.0)
        
        /// Orange color
        public static let orange = Color(red: 1.0, green: 0.5, blue: 0.0)
        
        /// Purple color
        public static let purple = Color(red: 0.5, green: 0.0, blue: 0.5)
        
        /// Cyan color
        public static let cyan = Color(red: 0.0, green: 1.0, blue: 1.0)
        
        /// Indigo color
        public static let indigo = Color(red: 0.29, green: 0.0, blue: 0.51)
        
        /// Gray color
        public static let gray = Color(red: 0.5, green: 0.5, blue: 0.5)
    }
    
    // MARK: - Standard Metrics
    
    /// Creates a standard accuracy metric
    /// - Returns: ComparisonMetric for accuracy
    public static func accuracy() -> ComparisonMetric {
        ComparisonMetric(
            name: "Accuracy",
            description: "Measures the proportion of correct outputs relative to total outputs",
            category: .quality,
            calculationMethod: .reference(referenceType: .goldStandard),
            range: .percentage,
            interpretation: InterpretationGuide(
                excellent: "Excellent accuracy with minimal errors",
                good: "Good accuracy with occasional errors",
                fair: "Moderate accuracy with noticeable errors",
                poor: "Poor accuracy with frequent errors",
                excellentThreshold: 90.0,
                goodThreshold: 75.0,
                fairThreshold: 60.0
            ),
            higherIsBetter: true,
            visualProperties: VisualizationProperties(
                primaryColor: .blue,
                secondaryColor: .gray,
                icon: "checkmark.circle.fill",
                recommendedChartType: .bar
            )
        )
    }
    
    /// Creates a standard latency metric
    /// - Returns: ComparisonMetric for latency
    public static func latency() -> ComparisonMetric {
        ComparisonMetric(
            name: "Latency",
            description: "Measures the response time in milliseconds",
            category: .performance,
            calculationMethod: .average,
            range: ValueRange(minimumValue: 0, maximumValue: 10000),
            interpretation: InterpretationGuide(
                excellent: "Excellent response time",
                good: "Good response time",
                fair: "Acceptable response time",
                poor: "Slow response time",
                excellentThreshold: 100.0,
                goodThreshold: 500.0,
                fairThreshold: 2000.0
            ),
            higherIsBetter: false,
            visualProperties: VisualizationProperties(
                primaryColor: .green,
                secondaryColor: .gray,
                icon: "speedometer",
                recommendedChartType: .line
            )
        )
    }
    
    /// Creates a standard token efficiency metric
    /// - Returns: ComparisonMetric for token efficiency
    public static func tokenEfficiency() -> ComparisonMetric {
        ComparisonMetric(
            name: "Token Efficiency",
            description: "Measures the effectiveness of token usage relative to output quality",
            category: .performance,
            calculationMethod: .statistical(statisticalMethod: .correlation),
            range: .zeroToOne,
            interpretation: InterpretationGuide(
                excellent: "Excellent token utilization",
                good: "Good token utilization",
                fair: "Moderate token utilization",
                poor: "Poor token utilization",
                excellentThreshold: 0.9,
                goodThreshold: 0.7,
                fairThreshold: 0.5
            ),
            visualProperties: VisualizationProperties(
                primaryColor: .purple,
                secondaryColor: .gray,
                icon: "arrow.left.and.right.circle",
                recommendedChartType: .bar
            )
        )
    }
    
    /// Creates a standard reasoning score metric
    /// - Returns: ComparisonMetric for reasoning
    public static func reasoningScore() -> ComparisonMetric {
        ComparisonMetric(
            name: "Reasoning Score",
            description: "Evaluates logical consistency and reasoning capabilities",
            category: .reasoning,
            calculationMethod: .automated(evaluator: .custom("ReasoningEvaluator")),
            range: .tenPoint,
            interpretation: InterpretationGuide(
                excellent: "Excellent reasoning abilities",
                good: "Good reasoning abilities",
                fair: "Basic reasoning abilities",
                poor: "Poor reasoning abilities",
                excellentThreshold: 8.0,
                goodThreshold: 6.0,
                fairThreshold: 4.0
            ),
            visualProperties: VisualizationProperties(
                primaryColor: .indigo,
                secondaryColor: .gray,
                icon: "brain",
                recommendedChartType: .radar
            )
        )
    }
    
    /// Creates a standard consistency metric
    /// - Returns: ComparisonMetric for consistency
    public static func consistency() -> ComparisonMetric {
        ComparisonMetric(
            name: "Consistency",
            description: "Measures the variability in outputs for similar inputs",
            category: .consistency,
            calculationMethod: .statistical(statisticalMethod: .standardDeviation),
            range: .zeroToOne,
            interpretation: InterpretationGuide(
                excellent: "Highly consistent outputs",
                good: "Generally consistent outputs",
                fair: "Somewhat consistent outputs",
                poor: "Inconsistent outputs",
                excellentThreshold: 0.9,
                goodThreshold: 0.75,
                fairThreshold: 0.6
            ),
            visualProperties: VisualizationProperties(
                primaryColor: .cyan,
                secondaryColor: .gray,
                icon: "equal.circle.fill",
                recommendedChartType: .scatter
            )
        )
    }
    
    /// Standard predefined metrics
    public static let standardMetrics: [ComparisonMetric] = [
        accuracy(),
        latency(),
        tokenEfficiency(),
        reasoningScore(),
        consistency()
    ]
    
    // MARK: - Calculation Methods
    
    /// Calculates a metric value for a model output
    /// - Parameters:
    ///   - output: Model output to evaluate
    ///   - referenceOutput: Reference output if needed
    ///   - context: Additional evaluation context
    /// - Returns: Calculated metric value or nil if calculation fails
    public func calculate(
        output: String,
        referenceOutput: String? = nil,
        context: [String: Any] = [:]
    ) -> Double? {
        // This would delegate to appropriate calculation method
        // Implementation would depend on the specific metric
        
        switch calculationMethod {
        case .direct:
            // Direct value would be extracted from output or context
            return context["directValue"] as? Double
            
        case .average:
            // Would average multiple values
            if let values = context["values"] as? [Double], !values.isEmpty {
                return values.reduce(0, +) / Double(values.count)
            }
            return nil
            
        case .reference:
            // Would compare against reference output
            guard let referenceOutput = referenceOutput else { return nil }
            
            // Placeholder implementation - would use more sophisticated comparison
            let similarity = calculateSimilarity(output, referenceOutput)
            return similarity
            
        case .statistical:
            // Would perform statistical analysis
            return context["statisticalValue"] as? Double
            
        case .automated:
            // Would use automated evaluator
            return context["automatedScore"] as? Double
            
        case .human:
            // Would use human evaluation score
            return context["humanScore"] as? Double
            
        case .custom:
            // Would use custom evaluation
            return context["customScore"] as? Double
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
        
        return Double(intersection) / Double(union)
    }
    
    /// Normalizes a value to the metric's range
    /// - Parameter value: Raw value to normalize
    /// - Returns: Normalized value between 0 and 1
    public func normalize(_ value: Double) -> Double {
        let range = self.range.maximumValue - self.range.minimumValue
        guard range > 0 else { return 0 }
        
        let normalized = (value - self.range.minimumValue) / range
        
        // Clamp to 0-1
        return max(0, min(1, normalized))
    }
    
    /// Returns a color for a specific metric value
    /// - Parameter value: Metric value to represent
    /// - Returns: Color for visualization
    public func colorForValue(_ value: Double) -> Color {
        let level = interpretation.performanceLevelFor(value: value)
        
        switch level {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

// MARK: - CaseIterable Conformance for MetricCategory
extension ComparisonMetric.MetricCategory: CaseIterable {
    public static var allCases: [ComparisonMetric.MetricCategory] {
        return [.quality, .performance, .reasoning, .taskSpecific, .consistency, .ethics, .risk]
    }
}
