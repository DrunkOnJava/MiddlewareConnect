#!/bin/bash

# Set process name for better visibility in activity monitor and ps
export PS1="RebasedCodeGitSync"
export PROMPT_COMMAND='echo -ne "\033]0;RebasedCodeGitSync\007"'

# auto_git_sync.sh - Automatic GitHub synchronization script
# Syncs changes between local environment and GitHub repository

REPO_PATH="/Users/griffin/Desktop/RebasedCode"
LOG_FILE="$REPO_PATH/sync_log.txt"
ERROR_LOG="$REPO_PATH/sync_error.log"
BRANCH="main"
SYNC_INTERVAL=300  # 5 minutes in seconds

cd "$REPO_PATH"

echo "$(date): Starting GitHub sync service" >> "$LOG_FILE"

while true; do
  echo "$(date): Checking for changes" >> "$LOG_FILE"
  
  # Save current git status
  GIT_STATUS=$(git status --porcelain)
  
  if [ -n "$GIT_STATUS" ]; then
    echo "$(date): Changes detected, syncing..." >> "$LOG_FILE"
    
    # Pull latest changes from remote repository
    echo "$(date): Pulling latest changes" >> "$LOG_FILE"
    git pull origin "$BRANCH" >> "$LOG_FILE" 2>> "$ERROR_LOG"
    
    # Handle any merge conflicts
    if [ $? -ne 0 ]; then
      echo "$(date): WARNING - Merge conflicts detected." >> "$LOG_FILE"
      
      # Attempt to resolve using ours strategy for common file types
      git checkout --ours "*.pbxproj" "*.xcworkspacedata" "*.xcscheme" "*.plist" 2>/dev/null
      
      # Mark conflicts as resolved
      git add . >> "$LOG_FILE" 2>> "$ERROR_LOG"
    fi
    
    # Stage all changes
    echo "$(date): Staging changes" >> "$LOG_FILE"
    git add -A >> "$LOG_FILE" 2>> "$ERROR_LOG"
    
    # Commit changes with timestamp
    echo "$(date): Committing changes" >> "$LOG_FILE"
    git commit -m "Auto-sync: $(date)" >> "$LOG_FILE" 2>> "$ERROR_LOG"
    
    # Push changes to remote repository
    echo "$(date): Pushing changes" >> "$LOG_FILE"
    git push origin "$BRANCH" >> "$LOG_FILE" 2>> "$ERROR_LOG"
    
    echo "$(date): Sync completed" >> "$LOG_FILE"
  else
    echo "$(date): No changes detected" >> "$LOG_FILE"
    
    # Still pull to check for remote changes
    git pull origin "$BRANCH" --quiet >> "$LOG_FILE" 2>> "$ERROR_LOG"
  fi
  
  # Wait for next sync interval
  echo "$(date): Waiting for next sync cycle" >> "$LOG_FILE"
  sleep "$SYNC_INTERVAL"
done
