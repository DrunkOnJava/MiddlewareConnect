#!/bin/bash
# Main script to run all integration steps

set -e  # Exit on error

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting module integration process..."

# Make scripts executable
chmod +x "$SCRIPTS_DIR/integrate_modules.sh"
chmod +x "$SCRIPTS_DIR/update_xcode_project.sh"

# Run integration scripts
echo "Step 1: Organizing module files..."
"$SCRIPTS_DIR/integrate_modules.sh"

echo "Step 2: Updating Xcode project..."
"$SCRIPTS_DIR/update_xcode_project.sh"

echo "Integration complete. You can now open the Xcode project and build the modules."
