# Module Integration Instructions

This document explains how to integrate the modular framework components into the Xcode project.

## Quick Start

1. Make the integration script executable:
   ```
   chmod +x integrate.command
   ```

2. Run the integration script by double-clicking `integrate.command` in Finder or running:
   ```
   ./integrate.command
   ```

3. Open the Xcode project and build the modules:
   ```
   open MiddlewareConnect.xcodeproj
   ```

## What The Integration Does

The integration process:

1. Organizes the module files into the appropriate directory structure
2. Updates the Xcode project file to include module targets
3. Sets up dependencies between modules
4. Configures build settings for module targets

## Modules Overview

The modular framework consists of three main modules:

- **LLMServiceProvider**: Core service infrastructure for LLM interactions
- **ModelComparisonView**: Comparison framework for LLM models
- **PdfSplitterView**: PDF processing and splitting tools

## Manual Integration

If you prefer to integrate manually:

1. Run the individual scripts in the `Scripts` directory:
   ```
   Scripts/integrate_modules.sh
   Scripts/update_xcode_project.sh
   ```

2. Open the Xcode project and verify the module targets are properly configured

## Troubleshooting

If you encounter issues during integration:

- Check the console output for error messages
- Verify that all required files exist in the source directories
- If the Xcode project fails to open, restore from the backup created during integration
- For detailed project structure, refer to MODULE_INTEGRATION.md

For more information on using the modular framework, see MIGRATION_GUIDE.md
