#!/bin/bash
# Make all integration scripts executable

chmod +x integrate.command
chmod +x Scripts/integrate_modules.sh
chmod +x Scripts/update_xcode_project.sh
chmod +x Scripts/run_integration.sh

echo "All integration scripts are now executable."
echo "You can now run ./integrate.command to integrate the modules."
