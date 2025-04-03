#!/bin/bash

# setup_github_sync.sh - Set up automatic GitHub synchronization
# This script installs and configures the git sync service

REPO_PATH="/Users/griffin/Desktop/RebasedCode"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"

echo "Setting up automatic GitHub synchronization for RebasedCode..."

# Make sure we're in the repository directory
cd "$REPO_PATH"

# Make the scripts executable
echo "Making scripts executable..."
chmod +x "$REPO_PATH/auto_git_sync.sh"
chmod +x "$REPO_PATH/git_sync_runner.py"

# Create launch agents directory if it doesn't exist
mkdir -p "$LAUNCH_AGENTS_DIR"

# Install the launchd service
echo "Installing the launchd service..."
cp "$REPO_PATH/com.rebasedcode.gitsync.plist" "$LAUNCH_AGENTS_DIR/"

# Load the service
echo "Loading the sync service..."
launchctl load "$LAUNCH_AGENTS_DIR/com.rebasedcode.gitsync.plist"

# Create a .gitignore to exclude sync logs
if [ ! -f "$REPO_PATH/.gitignore" ]; then
  echo "Creating .gitignore file..."
  cat > "$REPO_PATH/.gitignore" <<EOL
# Sync logs
sync_log.txt
sync_error.log
sync_output.log

# macOS
.DS_Store
.AppleDouble
.LSOverride
._*

# Xcode
xcuserdata/
*.xcscmblueprint
*.xccheckout
build/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# Swift Package Manager
.build/
Package.resolved

# Node.js
node_modules/
npm-debug.log
EOL
else
  # Add sync logs to existing .gitignore if they're not already there
  grep -q "sync_log.txt" "$REPO_PATH/.gitignore" || echo "sync_log.txt" >> "$REPO_PATH/.gitignore"
  grep -q "sync_error.log" "$REPO_PATH/.gitignore" || echo "sync_error.log" >> "$REPO_PATH/.gitignore"
  grep -q "sync_output.log" "$REPO_PATH/.gitignore" || echo "sync_output.log" >> "$REPO_PATH/.gitignore"
fi

# Create a VSCode workspace file with Git extension recommendations
echo "Creating VSCode workspace file with Git extensions..."
cat > "$REPO_PATH/RebasedCode.code-workspace" <<EOL
{
  "folders": [
    {
      "path": "."
    }
  ],
  "settings": {
    "editor.formatOnSave": true,
    "git.autofetch": true,
    "git.enableSmartCommit": true,
    "git.confirmSync": false
  },
  "extensions": {
    "recommendations": [
      "eamodio.gitlens",
      "mhutchie.git-graph",
      "donjayamanne.githistory"
    ]
  }
}
EOL

# Set up Xcode Git integration
echo "Configuring Xcode Git integration..."
defaults write com.apple.dt.Xcode DVTSourceControlEnableGitSupport -bool YES
defaults write com.apple.dt.Xcode IDESourceControlAutomaticallyAddNewFiles -bool YES

echo "GitHub synchronization setup complete!"
echo ""
echo "Your repository will now automatically sync with GitHub every 5 minutes."
echo "Sync logs are saved to:"
echo "  $REPO_PATH/sync_log.txt"
echo "  $REPO_PATH/sync_error.log"
echo ""
echo "To open this project in VSCode with Git extensions:"
echo "  code $REPO_PATH/RebasedCode.code-workspace"
echo ""
echo "To monitor the sync service:"
echo "  tail -f $REPO_PATH/sync_log.txt"
echo ""
echo "To stop the sync service:"
echo "  launchctl unload $LAUNCH_AGENTS_DIR/com.rebasedcode.gitsync.plist"
echo ""
echo "To start the sync service again:"
echo "  launchctl load $LAUNCH_AGENTS_DIR/com.rebasedcode.gitsync.plist"
