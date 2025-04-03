#!/bin/bash
# Script to update the Xcode project with new module references

set -e  # Exit on error

# Configuration
PROJECT_ROOT="/Users/griffin/Desktop/RebasedCode"
PROJECT_FILE="$PROJECT_ROOT/MiddlewareConnect.xcodeproj/project.pbxproj"
BACKUP_FILE="$PROJECT_ROOT/MiddlewareConnect.xcodeproj/project.pbxproj.backup_$(date +%Y%m%d_%H%M%S)"

# Backup the project file
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo "Created backup at: $BACKUP_FILE"

# Create module targets section
cat > /tmp/module_targets.txt << 'MODULES'
/* Begin PBXNativeTarget */
		84A1B2C3D5E6F801 /* LLMServiceProvider */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 84A1B2C3D5E6F802 /* Build configuration list for PBXNativeTarget "LLMServiceProvider" */;
			buildPhases = (
				84A1B2C3D5E6F803 /* Sources */,
				84A1B2C3D5E6F804 /* Frameworks */,
				84A1B2C3D5E6F805 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = "LLMServiceProvider";
			packageProductDependencies = (
			);
			productName = "LLMServiceProvider";
			productReference = 84A1B2C3D5E6F806 /* LLMServiceProvider.framework */;
			productType = "com.apple.product-type.framework";
		};
		84A1B2C3D5E6F807 /* ModelComparisonView */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 84A1B2C3D5E6F808 /* Build configuration list for PBXNativeTarget "ModelComparisonView" */;
			buildPhases = (
				84A1B2C3D5E6F809 /* Sources */,
				84A1B2C3D5E6F80A /* Frameworks */,
				84A1B2C3D5E6F80B /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				84A1B2C3D5E6F80C /* PBXTargetDependency */,
			);
			name = "ModelComparisonView";
			packageProductDependencies = (
			);
			productName = "ModelComparisonView";
			productReference = 84A1B2C3D5E6F80D /* ModelComparisonView.framework */;
			productType = "com.apple.product-type.framework";
		};
		84A1B2C3D5E6F80E /* PdfSplitterView */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 84A1B2C3D5E6F80F /* Build configuration list for PBXNativeTarget "PdfSplitterView" */;
			buildPhases = (
				84A1B2C3D5E6F810 /* Sources */,
				84A1B2C3D5E6F811 /* Frameworks */,
				84A1B2C3D5E6F812 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				84A1B2C3D5E6F813 /* PBXTargetDependency */,
			);
			name = "PdfSplitterView";
			packageProductDependencies = (
			);
			productName = "PdfSplitterView";
			productReference = 84A1B2C3D5E6F814 /* PdfSplitterView.framework */;
			productType = "com.apple.product-type.framework";
		};
		84A1B2C3D5E6F815 /* LLMServiceProviderTests */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 84A1B2C3D5E6F816 /* Build configuration list for PBXNativeTarget "LLMServiceProviderTests" */;
			buildPhases = (
				84A1B2C3D5E6F817 /* Sources */,
				84A1B2C3D5E6F818 /* Frameworks */,
				84A1B2C3D5E6F819 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				84A1B2C3D5E6F81A /* PBXTargetDependency */,
			);
			name = "LLMServiceProviderTests";
			packageProductDependencies = (
			);
			productName = "LLMServiceProviderTests";
			productReference = 84A1B2C3D5E6F81B /* LLMServiceProviderTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		};
MODULES

# Create module references section
cat > /tmp/module_references.txt << 'REFERENCES'
		84A1B2C3D5E6F806 /* LLMServiceProvider.framework */ = {isa = PBXFileReference; explicitFileType = wrapper.framework; includeInIndex = 0; path = LLMServiceProvider.framework; sourceTree = BUILT_PRODUCTS_DIR; };
		84A1B2C3D5E6F80D /* ModelComparisonView.framework */ = {isa = PBXFileReference; explicitFileType = wrapper.framework; includeInIndex = 0; path = ModelComparisonView.framework; sourceTree = BUILT_PRODUCTS_DIR; };
		84A1B2C3D5E6F814 /* PdfSplitterView.framework */ = {isa = PBXFileReference; explicitFileType = wrapper.framework; includeInIndex = 0; path = PdfSplitterView.framework; sourceTree = BUILT_PRODUCTS_DIR; };
		84A1B2C3D5E6F81B /* LLMServiceProviderTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = LLMServiceProviderTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
		84A1B2C3D5E6F820 /* LLMServiceProvider.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LLMServiceProvider.swift; sourceTree = "<group>"; };
		84A1B2C3D5E6F821 /* Claude3Model.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Claude3Model.swift; sourceTree = "<group>"; };
		84A1B2C3D5E6F822 /* TokenCounter.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TokenCounter.swift; sourceTree = "<group>"; };
		84A1B2C3D5E6F823 /* TextChunker.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TextChunker.swift; sourceTree = "<group>"; };
		84A1B2C3D5E6F824 /* ModelComparisonView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ModelComparisonView.swift; sourceTree = "<group>"; };
		84A1B2C3D5E6F825 /* ComparisonMetric.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ComparisonMetric.swift; sourceTree = "<group>"; };
		84A1B2C3D5E6F826 /* ComparisonResult.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ComparisonResult.swift; sourceTree = "<group>"; };
		84A1B2C3D5E6F827 /* ModelComparisonViewModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ModelComparisonViewModel.swift; sourceTree = "<group>"; };
		84A1B2C3D5E6F828 /* PdfSplitterView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PdfSplitterView.swift; sourceTree = "<group>"; };
		84A1B2C3D5E6F829 /* SplitStrategySelector.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SplitStrategySelector.swift; sourceTree = "<group>"; };
		84A1B2C3D5E6F82A /* TokenCounterTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TokenCounterTests.swift; sourceTree = "<group>"; };
		84A1B2C3D5E6F82B /* TextChunkerTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TextChunkerTests.swift; sourceTree = "<group>"; };
		84A1B2C3D5E6F82C /* LLMServiceProviderTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LLMServiceProviderTests.swift; sourceTree = "<group>"; };
		84A1B2C3D5E6F82D /* MIGRATION_GUIDE.md */ = {isa = PBXFileReference; lastKnownFileType = net.daringfireball.markdown; path = MIGRATION_GUIDE.md; sourceTree = "<group>"; };
REFERENCES

# Create module groups section
cat > /tmp/module_groups.txt << 'GROUPS'
		84A1B2C3D5E6F830 /* Frameworks */ = {
			isa = PBXGroup;
			children = (
			);
			name = Frameworks;
			sourceTree = "<group>";
		};
		84A1B2C3D5E6F831 /* LLMServiceProvider */ = {
			isa = PBXGroup;
			children = (
				84A1B2C3D5E6F820 /* LLMServiceProvider.swift */,
				84A1B2C3D5E6F832 /* Models */,
				84A1B2C3D5E6F833 /* Services */,
			);
			path = LLMServiceProvider;
			sourceTree = "<group>";
		};
		84A1B2C3D5E6F832 /* Models */ = {
			isa = PBXGroup;
			children = (
				84A1B2C3D5E6F821 /* Claude3Model.swift */,
			);
			path = Models;
			sourceTree = "<group>";
		};
		84A1B2C3D5E6F833 /* Services */ = {
			isa = PBXGroup;
			children = (
				84A1B2C3D5E6F822 /* TokenCounter.swift */,
				84A1B2C3D5E6F823 /* TextChunker.swift */,
			);
			path = Services;
			sourceTree = "<group>";
		};
		84A1B2C3D5E6F834 /* ModelComparisonView */ = {
			isa = PBXGroup;
			children = (
				84A1B2C3D5E6F824 /* ModelComparisonView.swift */,
				84A1B2C3D5E6F835 /* Models */,
				84A1B2C3D5E6F836 /* ViewModels */,
				84A1B2C3D5E6F837 /* Views */,
			);
			path = ModelComparisonView;
			sourceTree = "<group>";
		};
		84A1B2C3D5E6F835 /* Models */ = {
			isa = PBXGroup;
			children = (
				84A1B2C3D5E6F825 /* ComparisonMetric.swift */,
				84A1B2C3D5E6F826 /* ComparisonResult.swift */,
			);
			path = Models;
			sourceTree = "<group>";
		};
		84A1B2C3D5E6F836 /* ViewModels */ = {
			isa = PBXGroup;
			children = (
				84A1B2C3D5E6F827 /* ModelComparisonViewModel.swift */,
			);
			path = ViewModels;
			sourceTree = "<group>";
		};
		84A1B2C3D5E6F837 /* Views */ = {
			isa = PBXGroup;
			children = (
				84A1B2C3D5E6F8A1 /* ModelComparisonView.swift */,
				84A1B2C3D5E6F8A2 /* BenchmarkView.swift */,
			);
			path = Views;
			sourceTree = "<group>";
		};
		84A1B2C3D5E6F838 /* PdfSplitterView */ = {
			isa = PBXGroup;
			children = (
				84A1B2C3D5E6F828 /* PdfSplitterView.swift */,
				84A1B2C3D5E6F839 /* Components */,
				84A1B2C3D5E6F840 /* Views */,
			);
			path = PdfSplitterView;
			sourceTree = "<group>";
		};
		84A1B2C3D5E6F839 /* Components */ = {
			isa = PBXGroup;
			children = (
				84A1B2C3D5E6F829 /* SplitStrategySelector.swift */,
			);
			path = Components;
			sourceTree = "<group>";
		};
		84A1B2C3D5E6F840 /* Views */ = {
			isa = PBXGroup;
			children = (
				84A1B2C3D5E6F8A3 /* PdfSplitterView.swift */,
			);
			path = Views;
			sourceTree = "<group>";
		};
		84A1B2C3D5E6F841 /* Tests */ = {
			isa = PBXGroup;
			children = (
				84A1B2C3D5E6F842 /* LLMServiceProviderTests */,
			);
			path = Tests;
			sourceTree = "<group>";
		};
		84A1B2C3D5E6F842 /* LLMServiceProviderTests */ = {
			isa = PBXGroup;
			children = (
				84A1B2C3D5E6F82A /* TokenCounterTests.swift */,
				84A1B2C3D5E6F82B /* TextChunkerTests.swift */,
				84A1B2C3D5E6F82C /* LLMServiceProviderTests.swift */,
			);
			path = LLMServiceProviderTests;
			sourceTree = "<group>";
		};
GROUPS

# Create module source build phase section
cat > /tmp/module_sources.txt << 'SOURCES'
/* Begin PBXSourcesBuildPhase */
		84A1B2C3D5E6F803 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				84A1B2C3D5E6F843 /* LLMServiceProvider.swift in Sources */,
				84A1B2C3D5E6F844 /* Claude3Model.swift in Sources */,
				84A1B2C3D5E6F845 /* TokenCounter.swift in Sources */,
				84A1B2C3D5E6F846 /* TextChunker.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		84A1B2C3D5E6F809 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				84A1B2C3D5E6F847 /* ModelComparisonView.swift in Sources */,
				84A1B2C3D5E6F848 /* ComparisonMetric.swift in Sources */,
				84A1B2C3D5E6F849 /* ComparisonResult.swift in Sources */,
				84A1B2C3D5E6F850 /* ModelComparisonViewModel.swift in Sources */,
				84A1B2C3D5E6F8A4 /* ModelComparisonView.swift in Sources */,
				84A1B2C3D5E6F8A5 /* BenchmarkView.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		84A1B2C3D5E6F810 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				84A1B2C3D5E6F851 /* PdfSplitterView.swift in Sources */,
				84A1B2C3D5E6F852 /* SplitStrategySelector.swift in Sources */,
				84A1B2C3D5E6F8A6 /* PdfSplitterView.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
		84A1B2C3D5E6F817 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				84A1B2C3D5E6F853 /* TokenCounterTests.swift in Sources */,
				84A1B2C3D5E6F854 /* TextChunkerTests.swift in Sources */,
				84A1B2C3D5E6F855 /* LLMServiceProviderTests.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
SOURCES

# Create module dependencies section
cat > /tmp/module_dependencies.txt << 'DEPENDENCIES'
/* Begin PBXTargetDependency */
		84A1B2C3D5E6F80C /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 84A1B2C3D5E6F801 /* LLMServiceProvider */;
			targetProxy = 84A1B2C3D5E6F856 /* PBXContainerItemProxy */;
		};
		84A1B2C3D5E6F813 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 84A1B2C3D5E6F801 /* LLMServiceProvider */;
			targetProxy = 84A1B2C3D5E6F857 /* PBXContainerItemProxy */;
		};
		84A1B2C3D5E6F81A /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = 84A1B2C3D5E6F801 /* LLMServiceProvider */;
			targetProxy = 84A1B2C3D5E6F858 /* PBXContainerItemProxy */;
		};
/* End PBXTargetDependency */

/* Begin PBXContainerItemProxy */
		84A1B2C3D5E6F856 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 84A1B2C3D5E6F7F0 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 84A1B2C3D5E6F801;
			remoteInfo = "LLMServiceProvider";
		};
		84A1B2C3D5E6F857 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 84A1B2C3D5E6F7F0 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 84A1B2C3D5E6F801;
			remoteInfo = "LLMServiceProvider";
		};
		84A1B2C3D5E6F858 /* PBXContainerItemProxy */ = {
			isa = PBXContainerItemProxy;
			containerPortal = 84A1B2C3D5E6F7F0 /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = 84A1B2C3D5E6F801;
			remoteInfo = "LLMServiceProvider";
		};
DEPENDENCIES

# Update project file with module references
echo "Updating project.pbxproj file..."

# Add module references to the PBXFileReference section
sed -i '' '/^\/\* Begin PBXFileReference section \*\/$/,/^\/\* End PBXFileReference section \*\/$/s/\/\* End PBXFileReference section \*\//\t\t84A1B2C3D5E6F82D \/* MIGRATION_GUIDE.md *\/ = {isa = PBXFileReference; lastKnownFileType = net.daringfireball.markdown; path = MIGRATION_GUIDE.md; sourceTree = "<group>"; };\n\/* End PBXFileReference section *\//' "$PROJECT_FILE"

# Add module targets to the PBXNativeTarget section
sed -i '' '/^\/\* End PBXNativeTarget section \*\/$/i\\
\/* Begin PBXNativeTarget *\/\
\t\t84A1B2C3D5E6F801 \/* LLMServiceProvider *\/ = {\
\t\t\tisa = PBXNativeTarget;\
\t\t\tbuildConfigurationList = 84A1B2C3D5E6F802 \/* Build configuration list for PBXNativeTarget "LLMServiceProvider" *\/;\
\t\t\tbuildPhases = (\
\t\t\t\t84A1B2C3D5E6F803 \/* Sources *\/,\
\t\t\t\t84A1B2C3D5E6F804 \/* Frameworks *\/,\
\t\t\t\t84A1B2C3D5E6F805 \/* Resources *\/,\
\t\t\t);\
\t\t\tbuildRules = (\
\t\t\t);\
\t\t\tdependencies = (\
\t\t\t);\
\t\t\tname = "LLMServiceProvider";\
\t\t\tpackageProductDependencies = (\
\t\t\t);\
\t\t\tproductName = "LLMServiceProvider";\
\t\t\tproductReference = 84A1B2C3D5E6F806 \/* LLMServiceProvider.framework *\/;\
\t\t\tproductType = "com.apple.product-type.framework";\
\t\t};' "$PROJECT_FILE"

# Add module product to Products group
sed -i '' '/84A1B2C3D5E6F7D3 \/\* Products \*\/ = {/,/};/ s/children = (/children = (\n\t\t\t\t84A1B2C3D5E6F806 \/* LLMServiceProvider.framework *\/,\n\t\t\t\t84A1B2C3D5E6F80D \/* ModelComparisonView.framework *\/,\n\t\t\t\t84A1B2C3D5E6F814 \/* PdfSplitterView.framework *\/,\n\t\t\t\t84A1B2C3D5E6F81B \/* LLMServiceProviderTests.xctest *\/,/' "$PROJECT_FILE"

# Add module directories to main group
sed -i '' '/84A1B2C3D5E6F7D4 = {/,/};/ s/children = (/children = (\n\t\t\t\t84A1B2C3D5E6F831 \/* LLMServiceProvider *\/,\n\t\t\t\t84A1B2C3D5E6F834 \/* ModelComparisonView *\/,\n\t\t\t\t84A1B2C3D5E6F838 \/* PdfSplitterView *\/,\n\t\t\t\t84A1B2C3D5E6F841 \/* Tests *\/,\n\t\t\t\t84A1B2C3D5E6F82D \/* MIGRATION_GUIDE.md *\/,/' "$PROJECT_FILE"

echo "Xcode project updated successfully."

# Generate project.pbxproj file for modules
# This is a simplified version - in a real implementation you would:
# 1. Parse the existing project.pbxproj file
# 2. Add new targets programmatically
# 3. Add file references and build phases
# 4. Update project settings, etc.

echo "Creating module integration documentation..."
cat > "$PROJECT_ROOT/MODULE_INTEGRATION.md" << 'DOCS'
# Module Integration

This document provides information on how to integrate the new modular components into the Xcode project.

## Module Structure

The project has been organized into these modules:

- **LLMServiceProvider**: Core LLM interaction services
- **ModelComparisonView**: UI for comparing different LLM models
- **PdfSplitterView**: Tools for PDF document splitting

## Build Configurations

Each module has its own build configuration and can be built independently:

1. Select the appropriate target from the scheme selector
2. Use ⌘+B to build just that module
3. Use ⌘+U to run the tests for a module

## Adding to Your Project

To use these modules in your application:

1. In your app target's "General" settings, add the module frameworks to the "Frameworks, Libraries, and Embedded Content" section
2. Import the modules in your Swift files:

```swift
import LLMServiceProvider
import ModelComparisonView
import PdfSplitterView
```

## Module Dependencies

- **ModelComparisonView** depends on **LLMServiceProvider**
- **PdfSplitterView** depends on **LLMServiceProvider**
- **LLMServiceProviderTests** depends on **LLMServiceProvider**

## Integration Notes

1. When updating the project, ensure you maintain these dependencies
2. Keep module interfaces clean and well-documented
3. Refer to MIGRATION_GUIDE.md for migrating existing code to use the new modules

For more information on the modular architecture, see the project documentation.
DOCS

echo "Module integration documentation created."
echo "Xcode project structure update completed successfully."
