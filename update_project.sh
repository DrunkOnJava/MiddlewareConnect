#!/bin/bash

# Script to update Xcode project with modular framework files
# Created for MiddlewareConnect project

echo "Starting Xcode project update for modular framework..."

# Define paths
PROJECT_DIR="/Users/griffin/Desktop/RebasedCode"
PROJECT_FILE="$PROJECT_DIR/MiddlewareConnect.xcodeproj/project.pbxproj"
BACKUP_FILE="$PROJECT_DIR/MiddlewareConnect.xcodeproj/project.pbxproj.bak.$(date +%Y%m%d_%H%M%S)"

# Make a backup of the original project file
cp "$PROJECT_FILE" "$BACKUP_FILE"
echo "Created backup of project.pbxproj at $BACKUP_FILE"

# Define UUIDs for new files
# We need to generate consistent UUIDs for Xcode to recognize the files
LLM_SERVICE_PROVIDER_UUID="94A1B2C3D5E6F8A1"
MODEL_COMPARISON_VIEW_UUID="94A1B2C3D5E6F8A2"
PDF_SPLITTER_VIEW_UUID="94A1B2C3D5E6F8A3"

TESTS_GROUP_UUID="94A1B2C3D5E6F8B1"
LLM_SERVICE_PROVIDER_TESTS_UUID="94A1B2C3D5E6F8B2"

# Add module groups to the project
echo "Adding module groups to project hierarchy..."

# This sed script adds our module groups to the main MiddlewareConnect group
sed -i'.tmp' '/84A1B2C3D5E6F7D5 \/\* MiddlewareConnect \*\/ = {/,/children = (/c\
84A1B2C3D5E6F7D5 /* MiddlewareConnect */ = {\
			isa = PBXGroup;\
			children = (\
				84A1B2C3D5E6F7D6 /* App */,\
				84A1B2C3D5E6F7D7 /* Extensions */,\
				'"$LLM_SERVICE_PROVIDER_UUID"' /* LLMServiceProvider */,\
				'"$MODEL_COMPARISON_VIEW_UUID"' /* ModelComparisonView */,\
				'"$PDF_SPLITTER_VIEW_UUID"' /* PdfSplitterView */,\
				84A1B2C3D5E6F7D8 /* Models */,\
				84A1B2C3D5E6F7D9 /* Navigation */,\
				84A1B2C3D5E6F7DA /* Services */,\
				84A1B2C3D5E6F7DB /* Utilities */,\
				84A1B2C3D5E6F7DC /* Views */,\
				'"$TESTS_GROUP_UUID"' /* Tests */,\
				84A1B2C3D5E6F7AD /* Assets.xcassets */,\
				84A1B2C3D5E6F7D0 /* Info.plist */,\
				84A1B2C3D5E6F7DD /* Preview Content */,\
' "$PROJECT_FILE"

# Add module group definitions
echo "Adding module group definitions..."

# This adds the new group definitions to the PBXGroup section
sed -i'.tmp' '/End PBXGroup section/i\
		'"$LLM_SERVICE_PROVIDER_UUID"' /* LLMServiceProvider */ = {\
			isa = PBXGroup;\
			children = (\
				94A1B2C3D5E6F901 /* LLMServiceProvider.swift */,\
				94A1B2C3D5E6F902 /* Claude3Model.swift */,\
				94A1B2C3D5E6F903 /* ContextWindow.swift */,\
				94A1B2C3D5E6F904 /* DocumentAnalyzer.swift */,\
				94A1B2C3D5E6F905 /* DocumentSummarizer.swift */,\
				94A1B2C3D5E6F906 /* EntityExtractor.swift */,\
				94A1B2C3D5E6F907 /* ProcessingStatus.swift */,\
				94A1B2C3D5E6F908 /* PromptBuilder.swift */,\
				94A1B2C3D5E6F909 /* SystemPrompts.swift */,\
			);\
			path = LLMServiceProvider;\
			sourceTree = "<group>";\
		};\
		'"$MODEL_COMPARISON_VIEW_UUID"' /* ModelComparisonView */ = {\
			isa = PBXGroup;\
			children = (\
				94A1B2C3D5E6F911 /* ModelComparisonView.swift */,\
				94A1B2C3D5E6F912 /* Models/ComparisonMetric.swift */,\
				94A1B2C3D5E6F913 /* Models/ComparisonResult.swift */,\
				94A1B2C3D5E6F914 /* ViewModels/ModelComparisonViewModel.swift */,\
				94A1B2C3D5E6F915 /* Views/ModelComparisonView.swift */,\
				94A1B2C3D5E6F916 /* Views/BenchmarkView.swift */,\
			);\
			path = ModelComparisonView;\
			sourceTree = "<group>";\
		};\
		'"$PDF_SPLITTER_VIEW_UUID"' /* PdfSplitterView */ = {\
			isa = PBXGroup;\
			children = (\
				94A1B2C3D5E6F921 /* PdfSplitterView.swift */,\
				94A1B2C3D5E6F922 /* Components/SplitStrategySelector.swift */,\
				94A1B2C3D5E6F923 /* Views/PdfSplitterView.swift */,\
			);\
			path = PdfSplitterView;\
			sourceTree = "<group>";\
		};\
		'"$TESTS_GROUP_UUID"' /* Tests */ = {\
			isa = PBXGroup;\
			children = (\
				'"$LLM_SERVICE_PROVIDER_TESTS_UUID"' /* LLMServiceProviderTests */,\
			);\
			path = Tests;\
			sourceTree = "<group>";\
		};\
		'"$LLM_SERVICE_PROVIDER_TESTS_UUID"' /* LLMServiceProviderTests */ = {\
			isa = PBXGroup;\
			children = (\
				94A1B2C3D5E6F931 /* TokenCounterTests.swift */,\
				94A1B2C3D5E6F932 /* TextChunkerTests.swift */,\
				94A1B2C3D5E6F933 /* LLMServiceProviderTests.swift */,\
			);\
			path = LLMServiceProviderTests;\
			sourceTree = "<group>";\
		};\
' "$PROJECT_FILE"

# Add file references
echo "Adding file references..."

sed -i'.tmp' '/End PBXFileReference section/i\
		94A1B2C3D5E6F901 /* LLMServiceProvider.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LLMServiceProvider.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F902 /* Claude3Model.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Claude3Model.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F903 /* ContextWindow.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContextWindow.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F904 /* DocumentAnalyzer.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DocumentAnalyzer.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F905 /* DocumentSummarizer.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DocumentSummarizer.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F906 /* EntityExtractor.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = EntityExtractor.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F907 /* ProcessingStatus.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ProcessingStatus.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F908 /* PromptBuilder.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PromptBuilder.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F909 /* SystemPrompts.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SystemPrompts.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F911 /* ModelComparisonView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ModelComparisonView.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F912 /* ComparisonMetric.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ComparisonMetric.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F913 /* ComparisonResult.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ComparisonResult.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F914 /* ModelComparisonViewModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ModelComparisonViewModel.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F915 /* ModelComparisonView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ModelComparisonView.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F916 /* BenchmarkView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = BenchmarkView.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F921 /* PdfSplitterView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PdfSplitterView.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F922 /* SplitStrategySelector.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SplitStrategySelector.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F923 /* PdfSplitterView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PdfSplitterView.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F931 /* TokenCounterTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TokenCounterTests.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F932 /* TextChunkerTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TextChunkerTests.swift; sourceTree = "<group>"; };\
		94A1B2C3D5E6F933 /* LLMServiceProviderTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LLMServiceProviderTests.swift; sourceTree = "<group>"; };\
' "$PROJECT_FILE"

# Add build file entries
echo "Adding build file entries..."

sed -i'.tmp' '/End PBXBuildFile section/i\
		94A1B2C3D5E6F941 /* LLMServiceProvider.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F901 /* LLMServiceProvider.swift */; };\
		94A1B2C3D5E6F942 /* Claude3Model.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F902 /* Claude3Model.swift */; };\
		94A1B2C3D5E6F943 /* ContextWindow.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F903 /* ContextWindow.swift */; };\
		94A1B2C3D5E6F944 /* DocumentAnalyzer.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F904 /* DocumentAnalyzer.swift */; };\
		94A1B2C3D5E6F945 /* DocumentSummarizer.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F905 /* DocumentSummarizer.swift */; };\
		94A1B2C3D5E6F946 /* EntityExtractor.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F906 /* EntityExtractor.swift */; };\
		94A1B2C3D5E6F947 /* ProcessingStatus.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F907 /* ProcessingStatus.swift */; };\
		94A1B2C3D5E6F948 /* PromptBuilder.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F908 /* PromptBuilder.swift */; };\
		94A1B2C3D5E6F949 /* SystemPrompts.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F909 /* SystemPrompts.swift */; };\
		94A1B2C3D5E6F951 /* ModelComparisonView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F911 /* ModelComparisonView.swift */; };\
		94A1B2C3D5E6F952 /* ComparisonMetric.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F912 /* ComparisonMetric.swift */; };\
		94A1B2C3D5E6F953 /* ComparisonResult.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F913 /* ComparisonResult.swift */; };\
		94A1B2C3D5E6F954 /* ModelComparisonViewModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F914 /* ModelComparisonViewModel.swift */; };\
		94A1B2C3D5E6F955 /* ModelComparisonView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F915 /* ModelComparisonView.swift */; };\
		94A1B2C3D5E6F956 /* BenchmarkView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F916 /* BenchmarkView.swift */; };\
		94A1B2C3D5E6F961 /* PdfSplitterView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F921 /* PdfSplitterView.swift */; };\
		94A1B2C3D5E6F962 /* SplitStrategySelector.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F922 /* SplitStrategySelector.swift */; };\
		94A1B2C3D5E6F963 /* PdfSplitterView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 94A1B2C3D5E6F923 /* PdfSplitterView.swift */; };\
' "$PROJECT_FILE"

# Update build phase
echo "Updating build phase..."

sed -i'.tmp' '/84A1B2C3D5E6F7CA \/\* DesignSystem.swift in Sources \*\/,/);/c\
				84A1B2C3D5E6F7CA /* DesignSystem.swift in Sources */,\
				94A1B2C3D5E6F941 /* LLMServiceProvider.swift in Sources */,\
				94A1B2C3D5E6F942 /* Claude3Model.swift in Sources */,\
				94A1B2C3D5E6F943 /* ContextWindow.swift in Sources */,\
				94A1B2C3D5E6F944 /* DocumentAnalyzer.swift in Sources */,\
				94A1B2C3D5E6F945 /* DocumentSummarizer.swift in Sources */,\
				94A1B2C3D5E6F946 /* EntityExtractor.swift in Sources */,\
				94A1B2C3D5E6F947 /* ProcessingStatus.swift in Sources */,\
				94A1B2C3D5E6F948 /* PromptBuilder.swift in Sources */,\
				94A1B2C3D5E6F949 /* SystemPrompts.swift in Sources */,\
				94A1B2C3D5E6F951 /* ModelComparisonView.swift in Sources */,\
				94A1B2C3D5E6F952 /* ComparisonMetric.swift in Sources */,\
				94A1B2C3D5E6F953 /* ComparisonResult.swift in Sources */,\
				94A1B2C3D5E6F954 /* ModelComparisonViewModel.swift in Sources */,\
				94A1B2C3D5E6F955 /* ModelComparisonView.swift in Sources */,\
				94A1B2C3D5E6F956 /* BenchmarkView.swift in Sources */,\
				94A1B2C3D5E6F961 /* PdfSplitterView.swift in Sources */,\
				94A1B2C3D5E6F962 /* SplitStrategySelector.swift in Sources */,\
				94A1B2C3D5E6F963 /* PdfSplitterView.swift in Sources */,\
			);\
' "$PROJECT_FILE"

# Create module map files for modularity
echo "Creating module map files..."

mkdir -p "$PROJECT_DIR/MiddlewareConnect/LLMServiceProvider/include"
cat > "$PROJECT_DIR/MiddlewareConnect/LLMServiceProvider/include/module.modulemap" << EOF
framework module LLMServiceProvider {
    umbrella header "LLMServiceProvider.h"
    export *
    module * { export * }
}
EOF

mkdir -p "$PROJECT_DIR/MiddlewareConnect/ModelComparisonView/include"
cat > "$PROJECT_DIR/MiddlewareConnect/ModelComparisonView/include/module.modulemap" << EOF
framework module ModelComparisonView {
    umbrella header "ModelComparisonView.h"
    export *
    module * { export * }
}
EOF

mkdir -p "$PROJECT_DIR/MiddlewareConnect/PdfSplitterView/include"
cat > "$PROJECT_DIR/MiddlewareConnect/PdfSplitterView/include/module.modulemap" << EOF
framework module PdfSplitterView {
    umbrella header "PdfSplitterView.h"
    export *
    module * { export * }
}
EOF

# Create umbrella headers
echo "Creating umbrella headers..."

cat > "$PROJECT_DIR/MiddlewareConnect/LLMServiceProvider/include/LLMServiceProvider.h" << EOF
// LLMServiceProvider umbrella header

#import <Foundation/Foundation.h>

//! Project version number for LLMServiceProvider.
FOUNDATION_EXPORT double LLMServiceProviderVersionNumber;

//! Project version string for LLMServiceProvider.
FOUNDATION_EXPORT const unsigned char LLMServiceProviderVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <LLMServiceProvider/PublicHeader.h>
EOF

cat > "$PROJECT_DIR/MiddlewareConnect/ModelComparisonView/include/ModelComparisonView.h" << EOF
// ModelComparisonView umbrella header

#import <Foundation/Foundation.h>

//! Project version number for ModelComparisonView.
FOUNDATION_EXPORT double ModelComparisonViewVersionNumber;

//! Project version string for ModelComparisonView.
FOUNDATION_EXPORT const unsigned char ModelComparisonViewVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ModelComparisonView/PublicHeader.h>
EOF

cat > "$PROJECT_DIR/MiddlewareConnect/PdfSplitterView/include/PdfSplitterView.h" << EOF
// PdfSplitterView umbrella header

#import <Foundation/Foundation.h>

//! Project version number for PdfSplitterView.
FOUNDATION_EXPORT double PdfSplitterViewVersionNumber;

//! Project version string for PdfSplitterView.
FOUNDATION_EXPORT const unsigned char PdfSplitterViewVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <PdfSplitterView/PublicHeader.h>
EOF

# Create module directories if they don't exist
echo "Creating module directories..."
mkdir -p "$PROJECT_DIR/MiddlewareConnect/ModelComparisonView/Models"
mkdir -p "$PROJECT_DIR/MiddlewareConnect/ModelComparisonView/ViewModels"
mkdir -p "$PROJECT_DIR/MiddlewareConnect/ModelComparisonView/Views"
mkdir -p "$PROJECT_DIR/MiddlewareConnect/PdfSplitterView/Components"
mkdir -p "$PROJECT_DIR/MiddlewareConnect/PdfSplitterView/Views"
mkdir -p "$PROJECT_DIR/MiddlewareConnect/Tests/LLMServiceProviderTests"

# Clean up temporary files
rm "$PROJECT_FILE.tmp"

echo "Project file successfully updated."
echo "Now open the project in Xcode and verify the file structure."
