#!/bin/bash

# Master script to build and integrate modules for MiddlewareConnect

echo "Starting module integration process..."

# Make scripts executable
chmod +x ./update_project.sh
chmod +x ./create_module_structure.sh

# Create the module structure first
./create_module_structure.sh

# Update the project file next
./update_project.sh

# Create an import test file to verify imports
cat > "/Users/griffin/Desktop/RebasedCode/MiddlewareConnect/ImportTest.swift" << EOF
import Foundation
import SwiftUI

// Import our modules
import LLMServiceProvider
import ModelComparisonView
import PdfSplitterView

struct ModuleIntegrationTest {
    // Test LLMServiceProvider
    func testLLMService() {
        let service = LLMServiceProvider.shared
        
        // Use some types from the module
        let options = TextGenerationOptions(
            temperature: 0.7,
            maxTokens: 1000
        )
        
        print("LLMServiceProvider successfully imported")
    }
    
    // Test ModelComparisonView
    func testModelComparison() {
        let viewModel = ModelComparisonViewModel()
        
        // Create a metric
        let metric = ComparisonMetric.accuracy()
        
        print("ModelComparisonView successfully imported")
    }
    
    // Test PdfSplitterView
    func testPdfSplitter() {
        let viewModel = PdfSplitterViewModel()
        
        // Create a strategy
        let strategy = SplitStrategy.byPage()
        
        print("PdfSplitterView successfully imported")
    }
}
EOF

echo "Module integration complete."
echo "Open MiddlewareConnect.xcodeproj in Xcode to build the project."
