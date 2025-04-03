#!/bin/bash

# Create necessary module structure for MiddlewareConnect
# This script creates the directories and copies files to the appropriate locations

echo "Creating module structure for MiddlewareConnect..."

PROJECT_DIR="/Users/griffin/Desktop/RebasedCode/MiddlewareConnect"

# Create module directories if they don't exist
mkdir -p "$PROJECT_DIR/LLMServiceProvider"
mkdir -p "$PROJECT_DIR/ModelComparisonView/Models"
mkdir -p "$PROJECT_DIR/ModelComparisonView/ViewModels"
mkdir -p "$PROJECT_DIR/ModelComparisonView/Views"
mkdir -p "$PROJECT_DIR/PdfSplitterView/Components"
mkdir -p "$PROJECT_DIR/PdfSplitterView/Views"
mkdir -p "$PROJECT_DIR/Tests/LLMServiceProviderTests"

# Copy module files to their appropriate locations
# LLMServiceProvider module
cp "$PROJECT_DIR/../LLMServiceProvider/LLMServiceProvider.swift" "$PROJECT_DIR/LLMServiceProvider/"
cp "$PROJECT_DIR/../LLMServiceProvider/Claude3Model.swift" "$PROJECT_DIR/LLMServiceProvider/"
cp "$PROJECT_DIR/../LLMServiceProvider/ContextWindow.swift" "$PROJECT_DIR/LLMServiceProvider/"
cp "$PROJECT_DIR/../LLMServiceProvider/DocumentAnalyzer.swift" "$PROJECT_DIR/LLMServiceProvider/"
cp "$PROJECT_DIR/../LLMServiceProvider/DocumentSummarizer.swift" "$PROJECT_DIR/LLMServiceProvider/"
cp "$PROJECT_DIR/../LLMServiceProvider/EntityExtractor.swift" "$PROJECT_DIR/LLMServiceProvider/"
cp "$PROJECT_DIR/../LLMServiceProvider/ProcessingStatus.swift" "$PROJECT_DIR/LLMServiceProvider/"
cp "$PROJECT_DIR/../LLMServiceProvider/PromptBuilder.swift" "$PROJECT_DIR/LLMServiceProvider/"
cp "$PROJECT_DIR/../LLMServiceProvider/SystemPrompts.swift" "$PROJECT_DIR/LLMServiceProvider/"

# ModelComparisonView module
cp "$PROJECT_DIR/../ModelComparisonView/ModelComparisonView.swift" "$PROJECT_DIR/ModelComparisonView/"
cp "$PROJECT_DIR/../ModelComparisonView/Models/ComparisonMetric.swift" "$PROJECT_DIR/ModelComparisonView/Models/"
cp "$PROJECT_DIR/../ModelComparisonView/Models/ComparisonResult.swift" "$PROJECT_DIR/ModelComparisonView/Models/"
cp "$PROJECT_DIR/../ModelComparisonView/ViewModels/ModelComparisonViewModel.swift" "$PROJECT_DIR/ModelComparisonView/ViewModels/"
cp "$PROJECT_DIR/../ModelComparisonView/Views/ModelComparisonView.swift" "$PROJECT_DIR/ModelComparisonView/Views/"
cp "$PROJECT_DIR/../ModelComparisonView/Views/BenchmarkView.swift" "$PROJECT_DIR/ModelComparisonView/Views/"

# PdfSplitterView module
cp "$PROJECT_DIR/../PdfSplitterView/PdfSplitterView.swift" "$PROJECT_DIR/PdfSplitterView/"
cp "$PROJECT_DIR/../PdfSplitterView/Components/SplitStrategySelector.swift" "$PROJECT_DIR/PdfSplitterView/Components/"
cp "$PROJECT_DIR/../PdfSplitterView/Views/PdfSplitterView.swift" "$PROJECT_DIR/PdfSplitterView/Views/"

# Test files
cp "$PROJECT_DIR/../Tests/LLMServiceProviderTests/TokenCounterTests.swift" "$PROJECT_DIR/Tests/LLMServiceProviderTests/"
cp "$PROJECT_DIR/../Tests/LLMServiceProviderTests/TextChunkerTests.swift" "$PROJECT_DIR/Tests/LLMServiceProviderTests/"
cp "$PROJECT_DIR/../Tests/LLMServiceProviderTests/LLMServiceProviderTests.swift" "$PROJECT_DIR/Tests/LLMServiceProviderTests/"

# Add MIGRATION_GUIDE.md to the main project directory
cp "$PROJECT_DIR/../MIGRATION_GUIDE.md" "$PROJECT_DIR/"

echo "Module structure created successfully."
