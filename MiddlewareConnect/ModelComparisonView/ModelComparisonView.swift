/**
 * @fileoverview Main export file for ModelComparisonView module
 * @module ModelComparisonView
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
 * - Public interfaces for ModelComparisonView module
 * 
 * Notes:
 * - Re-exports public views and components
 * - Provides streamlined API for module consumers
 */

import SwiftUI
import Combine
import LLMServiceProvider

// Re-export public components
public typealias ComparisonMetric = ModelComparisonInternal.ComparisonMetric
public typealias ComparisonResult = ModelComparisonInternal.ComparisonResult
public typealias ModelComparisonViewModel = ModelComparisonInternal.ModelComparisonViewModel

// Main entry point views
@available(iOS 14.0, macOS 11.0, *)
public struct ModelComparisonView: View {
    @StateObject private var viewModel: ModelComparisonViewModel
    
    public init(viewModel: ModelComparisonViewModel = ModelComparisonViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ModelComparisonInternal.ModelComparisonView(viewModel: viewModel)
    }
}

@available(iOS 14.0, macOS 11.0, *)
public struct BenchmarkView: View {
    @StateObject private var viewModel: BenchmarkViewModel
    
    public init(viewModel: BenchmarkViewModel = BenchmarkViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ModelComparisonInternal.BenchmarkView(viewModel: viewModel)
    }
}

// Public types
public typealias BenchmarkViewModel = ModelComparisonInternal.BenchmarkViewModel
public typealias BenchmarkType = ModelComparisonInternal.BenchmarkView.BenchmarkType
public typealias BenchmarkResult = ModelComparisonInternal.BenchmarkResult

// Convenience initializers
public extension ComparisonMetric {
    /// Create a standard accuracy metric
    static func accuracy() -> ComparisonMetric {
        ModelComparisonInternal.ComparisonMetric.accuracy()
    }
    
    /// Create a standard latency metric
    static func latency() -> ComparisonMetric {
        ModelComparisonInternal.ComparisonMetric.latency()
    }
    
    /// Create a standard token efficiency metric
    static func tokenEfficiency() -> ComparisonMetric {
        ModelComparisonInternal.ComparisonMetric.tokenEfficiency()
    }
    
    /// Create a standard reasoning score metric
    static func reasoningScore() -> ComparisonMetric {
        ModelComparisonInternal.ComparisonMetric.reasoningScore()
    }
    
    /// Create a standard consistency metric
    static func consistency() -> ComparisonMetric {
        ModelComparisonInternal.ComparisonMetric.consistency()
    }
}

// Internal namespace
private enum ModelComparisonInternal {
    typealias ComparisonMetric = _ComparisonMetric
    typealias ComparisonResult = _ComparisonResult
    typealias ModelComparisonViewModel = _ModelComparisonViewModel
    typealias ModelComparisonView = _ModelComparisonView
    typealias BenchmarkView = _BenchmarkView
    typealias BenchmarkViewModel = _BenchmarkViewModel
    typealias BenchmarkResult = _BenchmarkResult
}
