#!/bin/bash

# Swift Package Structure Fix Script
# This script focuses on fixing the directory structure error in MiddlewareConnect
# Author: Claude AI Assistant
# Date: April 2, 2025

set -e  # Exit on any error

# Define colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print with color
print_green() { echo -e "${GREEN}$1${NC}"; }
print_yellow() { echo -e "${YELLOW}$1${NC}"; }
print_red() { echo -e "${RED}$1${NC}"; }
print_blue() { echo -e "${BLUE}$1${NC}"; }

# Define project path
PROJECT_PATH="$PWD"
print_blue "Working in directory: $PROJECT_PATH"

# Check if Package.swift exists
if [ ! -f "Package.swift" ]; then
    print_red "❌ Package.swift not found in current directory"
    exit 1
fi

# Backup Package.swift
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="Package.swift.backup.$TIMESTAMP"
cp Package.swift "$BACKUP_FILE"
print_green "✅ Created backup of Package.swift: $BACKUP_FILE"

# Two options to fix:
# 1. Create the standard directory structure and move files
# 2. Add a custom path to Package.swift

print_blue "Select an approach to fix the package structure:"
print_blue "1. Create standard Swift Package Manager directory structure"
print_blue "2. Modify Package.swift to specify a custom path"
echo -n "Enter your choice (1 or 2): "
read -r choice

if [ "$choice" = "1" ]; then
    # Option 1: Create standard directory structure
    print_blue "🔧 Creating standard Swift Package Manager directory structure..."

    # Create the standard directory structure
    mkdir -p Sources/MiddlewareConnect
    mkdir -p Tests/MiddlewareConnectTests

    # Find Swift files (excluding those already in Sources or Tests directories)
    print_blue "🔍 Finding Swift files to move..."
    SOURCE_FILES=$(find . -name "*.swift" -not -path "./Sources/*" -not -path "./Tests/*" -not -path "./.build/*")
    SOURCE_FILE_COUNT=$(echo "$SOURCE_FILES" | grep -v '^$' | wc -l)
    
    if [ "$SOURCE_FILE_COUNT" -eq 0 ]; then
        print_yellow "⚠️ No Swift files found outside of Sources or Tests directories"
        print_yellow "⚠️ You may need to manually move your source files"
    else
        print_green "✅ Found $SOURCE_FILE_COUNT Swift files to move"
        
        # Move the files to the standard location
        for file in $SOURCE_FILES; do
            # If it's a test file, move to Tests directory
            if [[ "$file" == *"Tests"* ]] || [[ "$file" == *"Test"* ]]; then
                mkdir -p Tests/MiddlewareConnectTests
                cp "$file" "Tests/MiddlewareConnectTests/$(basename "$file")"
                print_green "✅ Copied $file to Tests/MiddlewareConnectTests/$(basename "$file")"
            else
                # Otherwise, move to Sources directory
                cp "$file" "Sources/MiddlewareConnect/$(basename "$file")"
                print_green "✅ Copied $file to Sources/MiddlewareConnect/$(basename "$file")"
            fi
        done
    fi

    # Create a default updated Package.swift
    cat > Package.swift << 'EOF'
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MiddlewareConnect",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "MiddlewareConnect",
            targets: ["MiddlewareConnect"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0"),
    ],
    targets: [
        .target(
            name: "MiddlewareConnect",
            dependencies: ["Alamofire", "KeychainAccess"]),
        .testTarget(
            name: "MiddlewareConnectTests",
            dependencies: ["MiddlewareConnect"])
    ]
)
EOF
    print_green "✅ Created new Package.swift with standard directory structure"
    
elif [ "$choice" = "2" ]; then
    # Option 2: Modify Package.swift to specify a custom path
    print_blue "🔧 Modifying Package.swift to use custom paths..."
    
    # Identify source and test directories by scanning the project
    print_blue "🔍 Analyzing project structure to identify source and test directories..."
    
    # Find directories containing Swift files
    SOURCE_DIRS=$(find . -type f -name "*.swift" -not -path "./.build/*" | xargs -n1 dirname | sort | uniq)
    
    # Separate potential source and test directories
    TEST_DIRS=$(echo "$SOURCE_DIRS" | grep -i "test")
    SRC_DIRS=$(echo "$SOURCE_DIRS" | grep -v -i "test")
    
    print_green "✅ Potential source directories:"
    echo "$SRC_DIRS"
    print_green "✅ Potential test directories:"
    echo "$TEST_DIRS"
    
    # Create a temporary Package.swift with custom paths
    cat > Package.swift.new << 'EOF'
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MiddlewareConnect",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "MiddlewareConnect",
            targets: ["MiddlewareConnect"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0"),
    ],
    targets: [
        .target(
            name: "MiddlewareConnect",
            dependencies: ["Alamofire", "KeychainAccess"],
            path: ".", // Set to current directory or adjust as needed
            exclude: ["Tests"] // Exclude test directories
        ),
        .testTarget(
            name: "MiddlewareConnectTests",
            dependencies: ["MiddlewareConnect"],
            path: "Tests" // Set to your tests directory or adjust as needed
        )
    ]
)
EOF
    
    # Replace Package.swift with the new version
    mv Package.swift.new Package.swift
    print_green "✅ Updated Package.swift to use custom paths"
    print_yellow "⚠️ You may need to adjust the paths in Package.swift manually based on your actual project structure"
    print_yellow "⚠️ Examine the file to ensure the paths are correct for your project"
    
else
    print_red "❌ Invalid choice. Please run the script again and enter 1 or 2."
    exit 1
fi

# Clean derived data and build folders
print_blue "🧹 Cleaning Xcode derived data and build folders..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*MiddlewareConnect*
rm -rf .build
print_green "✅ Cleaned Xcode derived data and build folders"

# Test the build
print_blue "🏗️ Testing Swift package build..."
if swift build; then
    print_green "✅ Package built successfully!"
else
    print_yellow "⚠️ Build failed. Manual intervention might be needed."
    print_yellow "⚠️ Review the error messages and adjust your Package.swift accordingly."
    
    # Additional guidance based on error messages
    print_blue "📚 Common solutions for build failures:"
    print_yellow "1. Check the paths in Package.swift match your actual directory structure"
    print_yellow "2. If using option 1, ensure all source files were properly moved to Sources/MiddlewareConnect"
    print_yellow "3. If using option 2, adjust the 'path' and 'exclude' properties in Package.swift"
    print_yellow "4. Make sure no required source files are excluded from the build"
    print_yellow "5. If you see import errors, you may need to update your import statements"
fi

print_blue "📝 Next steps:"
print_yellow "1. If the build succeeded, verify that all your files are included and the package works as expected"
print_yellow "2. If the build failed, examine the error messages and make manual adjustments"
print_yellow "3. You can run 'swift build -v' for more verbose output to troubleshoot issues"
print_yellow "4. Once everything is working, open your Xcode project and build"

print_green "✅ Script completed!"
