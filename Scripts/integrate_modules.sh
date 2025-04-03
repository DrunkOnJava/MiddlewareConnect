#!/bin/bash
# Script to integrate module files into the Xcode project structure

set -e  # Exit on error

# Configuration
PROJECT_ROOT="/Users/griffin/Desktop/RebasedCode"
MIDDLEWARE_ROOT="$PROJECT_ROOT/MiddlewareConnect"

# Function to create a module directory structure
create_module_structure() {
    local module_name=$1
    
    echo "Creating directory structure for $module_name..."
    
    # Create main module directory if it doesn't exist
    mkdir -p "$MIDDLEWARE_ROOT/$module_name"
    
    # Create standard subdirectories
    mkdir -p "$MIDDLEWARE_ROOT/$module_name/Views"
    mkdir -p "$MIDDLEWARE_ROOT/$module_name/Models"
    mkdir -p "$MIDDLEWARE_ROOT/$module_name/Components"
    mkdir -p "$MIDDLEWARE_ROOT/$module_name/ViewModels"
    
    echo "Directory structure for $module_name created successfully."
}

# Function to add a file to the project structure
copy_file() {
    local src_file=$1
    local dest_file=$2
    
    # Ensure destination directory exists
    mkdir -p "$(dirname "$dest_file")"
    
    # Copy file
    cp "$src_file" "$dest_file"
    
    echo "Copied: $src_file -> $dest_file"
}

# Create test directories if they don't exist
mkdir -p "$PROJECT_ROOT/Tests"
mkdir -p "$PROJECT_ROOT/Tests/LLMServiceProviderTests"
mkdir -p "$PROJECT_ROOT/Tests/ModelComparisonViewTests"
mkdir -p "$PROJECT_ROOT/Tests/PdfSplitterViewTests"

# Create module structures
create_module_structure "LLMServiceProvider"
create_module_structure "ModelComparisonView"
create_module_structure "PdfSplitterView"

# Copy/move LLMServiceProvider files
echo "Integrating LLMServiceProvider module..."
copy_file "$MIDDLEWARE_ROOT/LLMServiceProvider/LLMServiceProvider.swift" "$MIDDLEWARE_ROOT/LLMServiceProvider/LLMServiceProvider.swift"
copy_file "$MIDDLEWARE_ROOT/LLMServiceProvider/Claude3Model.swift" "$MIDDLEWARE_ROOT/LLMServiceProvider/Models/Claude3Model.swift"
copy_file "$MIDDLEWARE_ROOT/Services/LLM/TokenCounter.swift" "$MIDDLEWARE_ROOT/LLMServiceProvider/Services/TokenCounter.swift"
copy_file "$MIDDLEWARE_ROOT/Services/LLM/TextChunker.swift" "$MIDDLEWARE_ROOT/LLMServiceProvider/Services/TextChunker.swift"
copy_file "$PROJECT_ROOT/Tests/LLMServiceProviderTests/TokenCounterTests.swift" "$PROJECT_ROOT/Tests/LLMServiceProviderTests/TokenCounterTests.swift"
copy_file "$PROJECT_ROOT/Tests/LLMServiceProviderTests/TextChunkerTests.swift" "$PROJECT_ROOT/Tests/LLMServiceProviderTests/TextChunkerTests.swift"
copy_file "$PROJECT_ROOT/Tests/LLMServiceProviderTests/LLMServiceProviderTests.swift" "$PROJECT_ROOT/Tests/LLMServiceProviderTests/LLMServiceProviderTests.swift"

# Copy/move ModelComparisonView files
echo "Integrating ModelComparisonView module..."
copy_file "$MIDDLEWARE_ROOT/ModelComparisonView/ModelComparisonView.swift" "$MIDDLEWARE_ROOT/ModelComparisonView/ModelComparisonView.swift"
copy_file "$MIDDLEWARE_ROOT/ModelComparisonView/Models/ComparisonMetric.swift" "$MIDDLEWARE_ROOT/ModelComparisonView/Models/ComparisonMetric.swift" 
copy_file "$MIDDLEWARE_ROOT/ModelComparisonView/Models/ComparisonResult.swift" "$MIDDLEWARE_ROOT/ModelComparisonView/Models/ComparisonResult.swift"
copy_file "$MIDDLEWARE_ROOT/ModelComparisonView/ViewModels/ModelComparisonViewModel.swift" "$MIDDLEWARE_ROOT/ModelComparisonView/ViewModels/ModelComparisonViewModel.swift"
copy_file "$MIDDLEWARE_ROOT/ModelComparisonView/Views/ModelComparisonView.swift" "$MIDDLEWARE_ROOT/ModelComparisonView/Views/ModelComparisonView.swift"
copy_file "$MIDDLEWARE_ROOT/ModelComparisonView/Views/BenchmarkView.swift" "$MIDDLEWARE_ROOT/ModelComparisonView/Views/BenchmarkView.swift"

# Copy/move PdfSplitterView files
echo "Integrating PdfSplitterView module..."
copy_file "$MIDDLEWARE_ROOT/PdfSplitterView/PdfSplitterView.swift" "$MIDDLEWARE_ROOT/PdfSplitterView/PdfSplitterView.swift"
copy_file "$MIDDLEWARE_ROOT/PdfSplitterView/Components/SplitStrategySelector.swift" "$MIDDLEWARE_ROOT/PdfSplitterView/Components/SplitStrategySelector.swift"
copy_file "$MIDDLEWARE_ROOT/PdfSplitterView/Views/PdfSplitterView.swift" "$MIDDLEWARE_ROOT/PdfSplitterView/Views/PdfSplitterView.swift"

# Copy migration guide
echo "Copying migration guide..."
copy_file "$PROJECT_ROOT/MIGRATION_GUIDE.md" "$PROJECT_ROOT/MIGRATION_GUIDE.md"

echo "Module integration complete."
