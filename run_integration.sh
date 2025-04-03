#!/bin/bash

# Run this script to execute the entire integration process
chmod +x "$(dirname "$0")/build_modules.sh"
./build_modules.sh

echo "Module integration complete. Please open MiddlewareConnect.xcodeproj in Xcode to build the project."
