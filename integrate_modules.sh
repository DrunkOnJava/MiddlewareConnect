#!/bin/bash

# Make this script executable
chmod +x "$0"

# Make scripts executable
chmod +x make_scripts_executable.sh
./make_scripts_executable.sh

# Run the Xcode project update script
./MiddlewareConnect/Scripts/update_xcodeproj.sh

echo ""
echo "✅ Module integration completed. Next steps:"
echo "1. Open MiddlewareConnect.xcodeproj in Xcode"
echo "2. Build the project (⌘+B)"
echo "3. Run the tests (⌘+U)"
echo ""
echo "If you encounter any issues, check the migration guide:"
echo "open MiddlewareConnect/MIGRATION_GUIDE.md"
