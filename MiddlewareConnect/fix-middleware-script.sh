#!/bin/bash

# MiddlewareConnect Build Fix Script
# This script automatically fixes the overlapping test sources issue and rebuilds the project
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
PROJECT_PATH="/Users/griffin/Desktop/RebasedCode/MiddlewareConnect"
cd "$PROJECT_PATH" || { print_red "❌ Could not access project path: $PROJECT_PATH"; exit 1; }

print_blue "🔍 Analyzing MiddlewareConnect project structure..."

# Check if Package.swift exists
if [ ! -f "Package.swift" ]; then
    print_red "❌ Package.swift not found in current directory: $(pwd)"
    exit 1
fi

# Create backup of the original Package.swift
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="Package.swift.backup.$TIMESTAMP"
cp Package.swift "$BACKUP_FILE"
print_green "✅ Created backup of original Package.swift: $BACKUP_FILE"

# Analyze test directory structure
print_blue "🔍 Analyzing test directory structure..."

TESTS_DIR="$PROJECT_PATH/Tests"
if [ ! -d "$TESTS_DIR" ]; then
    print_red "❌ Tests directory not found: $TESTS_DIR"
    exit 1
fi

# Check if LLMServiceProviderTests directory exists
if [ -d "$TESTS_DIR/LLMServiceProviderTests" ]; then
    HAS_LLM_TESTS=true
    LLM_TEST_FILES=$(find "$TESTS_DIR/LLMServiceProviderTests" -name "*.swift" | wc -l)
    print_green "✅ Found LLMServiceProviderTests with $LLM_TEST_FILES test files"
else
    HAS_LLM_TESTS=false
    print_yellow "⚠️ LLMServiceProviderTests directory not found"
fi

# Check if MiddlewareConnectTests directory exists
if [ -d "$TESTS_DIR/MiddlewareConnectTests" ]; then
    HAS_MIDDLEWARE_TESTS=true
    MIDDLEWARE_TEST_FILES=$(find "$TESTS_DIR/MiddlewareConnectTests" -name "*.swift" | wc -l)
    print_green "✅ Found MiddlewareConnectTests with $MIDDLEWARE_TEST_FILES test files"
else
    HAS_MIDDLEWARE_TESTS=false
    print_yellow "⚠️ MiddlewareConnectTests directory not found"
fi

# Identify the dependencies in the original Package.swift
print_blue "🔍 Identifying dependencies in Package.swift..."
ALAMOFIRE_VERSION=$(grep -o '"https://github.com/Alamofire/Alamofire.git", from: "[^"]*"' Package.swift | grep -o 'from: "[^"]*"' | cut -d'"' -f2)
KEYCHAIN_VERSION=$(grep -o '"https://github.com/kishikawakatsumi/KeychainAccess.git", from: "[^"]*"' Package.swift | grep -o 'from: "[^"]*"' | cut -d'"' -f2)

# If versions not found, use defaults
ALAMOFIRE_VERSION=${ALAMOFIRE_VERSION:-"5.6.0"}
KEYCHAIN_VERSION=${KEYCHAIN_VERSION:-"4.2.0"}
print_green "✅ Found dependency versions - Alamofire: $ALAMOFIRE_VERSION, KeychainAccess: $KEYCHAIN_VERSION"

# Generate a new Package.swift file
print_blue "🔧 Generating fixed Package.swift file..."

cat > Package.swift << EOF
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
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "$ALAMOFIRE_VERSION"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "$KEYCHAIN_VERSION"),
    ],
    targets: [
        .target(
            name: "MiddlewareConnect",
            dependencies: ["Alamofire", "KeychainAccess"]),
EOF

# Add test targets based on the directory structure
if [ "$HAS_MIDDLEWARE_TESTS" = true ] && [ "$HAS_LLM_TESTS" = true ]; then
    # Add both test targets
    cat >> Package.swift << EOF
        .testTarget(
            name: "MiddlewareConnectTests",
            dependencies: ["MiddlewareConnect"],
            path: "Tests/MiddlewareConnectTests"),
        .testTarget(
            name: "LLMServiceProviderTests",
            dependencies: ["MiddlewareConnect"],
            path: "Tests/LLMServiceProviderTests")
EOF
elif [ "$HAS_MIDDLEWARE_TESTS" = true ]; then
    # Only add MiddlewareConnectTests
    cat >> Package.swift << EOF
        .testTarget(
            name: "MiddlewareConnectTests",
            dependencies: ["MiddlewareConnect"],
            path: "Tests/MiddlewareConnectTests")
EOF
elif [ "$HAS_LLM_TESTS" = true ]; then
    # Only add LLMServiceProviderTests
    cat >> Package.swift << EOF
        .testTarget(
            name: "LLMServiceProviderTests",
            dependencies: ["MiddlewareConnect"],
            path: "Tests/LLMServiceProviderTests")
EOF
else
    # No test directories found, add a single test target pointing to Tests
    cat >> Package.swift << EOF
        .testTarget(
            name: "MiddlewareConnectTests",
            dependencies: ["MiddlewareConnect"],
            path: "Tests")
EOF
fi

# Close the Package.swift file
cat >> Package.swift << EOF
    ]
)
EOF

print_green "✅ Created fixed Package.swift file"

# Clean derived data and build folders
print_blue "🧹 Cleaning Xcode derived data and build folders..."

rm -rf ~/Library/Developer/Xcode/DerivedData/*MiddlewareConnect*
rm -rf .build
print_green "✅ Cleaned Xcode derived data and build folders"

# Run swift build to verify the package builds correctly
print_blue "🏗️ Building MiddlewareConnect package..."

if swift build; then
    print_green "✅ Package built successfully!"
else
    print_red "❌ Package build failed. See errors above."
    print_yellow "⚠️ Rolling back to the original Package.swift..."
    cp "$BACKUP_FILE" Package.swift
    print_yellow "Original Package.swift restored."
    exit 1
fi

# Final instructions for Xcode
print_blue "📝 Next steps:"
print_yellow "1. Open your Xcode project/workspace"
print_yellow "2. If Xcode is already open, close and reopen it"
print_yellow "3. Select Product > Clean Build Folder (Shift+Command+K) in Xcode"
print_yellow "4. Build the project (Command+B)"

# Create a helper Xcode script
cat > open_in_xcode.sh << EOF
#!/bin/bash
# Automatically open and clean the project in Xcode

# Kill Xcode if it's running
killall Xcode 2>/dev/null

# Wait a moment for Xcode to fully close
sleep 2

# Open the project
open -a Xcode *.xcodeproj 2>/dev/null || open -a Xcode *.xcworkspace 2>/dev/null || echo "No Xcode project or workspace found"

# Wait for Xcode to open
sleep 5

# Simulate Shift+Command+K (Clean Build Folder)
osascript -e 'tell application "System Events" to tell process "Xcode" to keystroke "k" using {shift down, command down}'

# Wait a moment
sleep 2

# Simulate Command+B (Build)
osascript -e 'tell application "System Events" to tell process "Xcode" to keystroke "b" using {command down}'

echo "Xcode opened and build initiated"
EOF

chmod +x open_in_xcode.sh
print_green "✅ Created helper script to open and clean the project in Xcode: ./open_in_xcode.sh"

print_green "✅ Script completed successfully!"
print_yellow "Would you like to open the project in Xcode and clean build? (y/n)"
read -r answer
if [[ $answer == "y" || $answer == "Y" ]]; then
    ./open_in_xcode.sh
fi
