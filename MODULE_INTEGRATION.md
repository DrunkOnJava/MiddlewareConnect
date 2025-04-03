# Module Integration Guide

This guide explains how to integrate the modular framework components into Xcode.

## Overview

The codebase has been modularized into the following components:

- **LLMServiceProvider**: Core service infrastructure for LLM interactions
- **ModelComparisonView**: Comparison framework for LLM models
- **PdfSplitterView**: PDF processing and splitting tools

## Quick Integration

For automated integration, run:

```bash
chmod +x integrate_modules.sh
./integrate_modules.sh
```

This script will:
1. Make helper scripts executable
2. Update the Xcode project to include all module files
3. Configure build settings for proper module structure

## Manual Integration

If you prefer to integrate modules manually:

1. Open `MiddlewareConnect.xcodeproj` in Xcode
2. Add the module files to their respective groups:
   - LLMServiceProvider
     - LLMServiceProvider.swift
     - Models/Claude3Model.swift
     - Services/TokenCounter.swift
     - Services/TextChunker.swift
   - ModelComparisonView
     - ModelComparisonView.swift
     - Models/ComparisonMetric.swift
     - Models/ComparisonResult.swift
     - ViewModels/ModelComparisonViewModel.swift
     - Views/ModelComparisonView.swift
     - Views/BenchmarkView.swift
   - PdfSplitterView
     - PdfSplitterView.swift
     - Views/PdfSplitterView.swift
     - Components/SplitStrategySelector.swift
3. Configure build settings for each module target:
   - Set "Defines Module" to "Yes"
   - Set "Product Module Name" to the module name
   - Set "Installation Directory" to "@executable_path/Frameworks"
   - Set "Skip Install" to "No"
   - Set "Swift Language Version" to "Swift 5"

## Verifying Integration

To verify that modules are properly integrated:

1. Build the project (⌘+B)
2. Run the tests (⌘+U)
3. Ensure all imports work correctly:

```swift
import LLMServiceProvider
import ModelComparisonView
import PdfSplitterView
```

## Troubleshooting

If you encounter issues:

1. **Build Errors**: Ensure all module files are added to the correct targets
2. **Import Errors**: Verify that "Defines Module" is set to "Yes" for each module target
3. **Runtime Errors**: Check that module dependencies are correctly configured

For more detailed migration instructions, see `MiddlewareConnect/MIGRATION_GUIDE.md`.

## Directory Structure

The module files are organized as follows:

```
MiddlewareConnect/
├── LLMServiceProvider/
│   ├── LLMServiceProvider.swift        # Main export
│   ├── LLMServiceProvider.h            # Umbrella header
│   ├── module.modulemap                # Module map
│   ├── Models/
│   │   └── Claude3Model.swift          # Model definition
│   └── Services/
│       ├── TokenCounter.swift          # Token counting
│       └── TextChunker.swift           # Text chunking
├── ModelComparisonView/
│   ├── ModelComparisonView.swift       # Main export
│   ├── ModelComparisonView.h           # Umbrella header
│   ├── module.modulemap                # Module map
│   ├── Models/
│   │   ├── ComparisonMetric.swift      # Metric definition
│   │   └── ComparisonResult.swift      # Result structure
│   ├── ViewModels/
│   │   └── ModelComparisonViewModel.swift  # View model
│   └── Views/
│       ├── ModelComparisonView.swift   # Main view
│       └── BenchmarkView.swift         # Benchmark view
├── PdfSplitterView/
│   ├── PdfSplitterView.swift           # Main export
│   ├── PdfSplitterView.h               # Umbrella header
│   ├── module.modulemap                # Module map
│   ├── Components/
│   │   └── SplitStrategySelector.swift # Strategy selector
│   └── Views/
│       └── PdfSplitterView.swift       # Main view
└── Tests/
    └── LLMServiceProviderTests/        # Unit tests
        ├── TokenCounterTests.swift
        ├── TextChunkerTests.swift
        └── LLMServiceProviderTests.swift
```
