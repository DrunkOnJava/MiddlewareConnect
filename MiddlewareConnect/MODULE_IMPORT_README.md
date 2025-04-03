# Swift Module Import Error Resolution Guide

## Overview

This document explains how to fix Swift module import errors in the MiddlewareConnect project. These errors typically manifest as:

```
No such module 'ModuleName'
```

## Quick Fix Steps

1. Make the error fixing script executable:
   ```bash
   chmod +x ./fix-module-imports.sh
   ```

2. Run the script to automatically fix import issues:
   ```bash
   ./fix-module-imports.sh
   ```

3. If you have a build log with errors, you can pass it to the script:
   ```bash
   ./fix-module-imports.sh --log your_error_log_file.log
   ```

## Manual Fix for PdfCombinerView.swift

The `PdfCombinerView.swift` file had multiple issues with module imports and missing dependencies:

```swift
// INCORRECT - Too complex and specific
@_exported import struct MiddlewareConnect.Views.DocumentTools.PDFCombiner.Views.PdfCombinerView
```

This and other issues have been fixed by:

1. Directly importing the required modules: `SwiftUI`, `PDFKit`, `UniformTypeIdentifiers`, and `Combine`
2. Adding proper imports for the missing components:
   ```swift
   import class MiddlewareConnect.PDFService
   @_exported import struct MiddlewareConnect.PDFCombinerViewState
   ```
3. Using type aliases for components:
   ```swift
   typealias DocumentPicker = MiddlewareConnect.DocumentPicker
   typealias PDFPreviewView = MiddlewareConnect.PDFPreviewView
   ```
4. Adding the missing `getPDFInfo` method to `PDFService` via extension:
   ```swift
   extension PDFService {
       func getPDFInfo(url: URL) throws -> (pageCount: Int, fileSizeFormatted: String) {
           // Implementation
       }
   }
   ```

### Common Import Error Patterns

1. **Overly Qualified Imports**
   
   ```swift
   // INCORRECT
   import ProjectName.Module.Submodule.Component
   
   // CORRECT
   import Module
   ```

2. **Export Issues**
   
   ```swift
   // INCORRECT
   @_exported import struct FullPath.To.Struct
   
   // CORRECT
   import ModuleName
   typealias MyStruct = OriginalType
   ```

## Fixing Future Import Issues

When encountering module import errors:

1. **Simplify Import Paths**: Remove unnecessary qualification
2. **Use Direct Imports**: Import just the module name, not the full path
3. **Use Type Aliases**: Instead of complex exported imports
4. **Check Package.swift**: Ensure the module is properly defined
5. **Check Target Membership**: Ensure files are in the correct target

## Module Structure Best Practices

1. Keep module names simple and clear
2. Avoid deep nesting of modules
3. Use clear boundaries between modules
4. Consider using type aliases for cross-module references
5. Maintain a consistent import style across the project

The fix-module-imports.sh script can help identify and fix common patterns, but complex module organization issues may require manual intervention.

## Resolving Dependency Issues

When encountering "Cannot find X in scope" errors, follow these steps:

1. **Identify the Missing Dependency**: Look for the specific type or component that's missing
2. **Locate the Component**: Use file search to find where it's defined in the project
3. **Determine Import Strategy**: Choose between:
   - Direct import: `import ComponentModule`
   - Specific type import: `import struct Module.Component`
   - Typealias: `typealias Component = Module.Component`
4. **Extension Method**: If a method is missing from a class, add it via extension
   ```swift
   extension SomeClass {
       func missingMethod() {
           // Implementation
       }
   }
   ```
5. **Check Module Structure**: Ensure the Package.swift file correctly defines all modules and dependencies
6. **Update Build Settings**: Make sure all files belong to the correct target
7. **Use Local Implementations**: In difficult cases, copy and adapt implementations locally
# Last updated: Wed Apr  2 21:12:25 EDT 2025
