#!/bin/bash

# GitHub Sync Script for MiddlewareConnect
# Created: $(date)
# 
# This script automatically pulls changes from the GitHub repository
# and handles potential conflicts to ensure your workspace stays up to date.

# Configuration
REPO_PATH="/Users/griffin/Desktop/RebasedCode"
BRANCH="main"
LOG_FILE="$REPO_PATH/sync_log.txt"
EMAIL_RECIPIENT="your.email@example.com"  # Change this to your email
MAX_RETRIES=3
NOTIFICATION_APP="MiddlewareConnect"

# Log Function
log() {
  local message="$(date '+%Y-%m-%d %H:%M:%S') - $1"
  echo "$message" >> "$LOG_FILE"
  echo "$message"
}

# Send Email Notification
send_notification() {
  local subject="$1"
  local message="$2"
  
  # Send macOS notification
  osascript -e "display notification \"$message\" with title \"$subject\" subtitle \"GitHub Sync\""
  
  # Uncomment if you want email notifications (requires mail command to be properly configured)
  # echo "$message" | mail -s "$subject" "$EMAIL_RECIPIENT"
}

# Change to repository directory
cd "$REPO_PATH" || {
  log "ERROR: Could not change to repository directory at $REPO_PATH"
  send_notification "Sync Error" "Could not find repository directory"
  exit 1
}

# Start sync log
log "Starting GitHub sync"

# Check if we have uncommitted changes
if ! git diff --quiet || ! git diff --staged --quiet; then
  log "WARNING: You have uncommitted changes that will be stashed"
  git stash save "Auto-stashed before git sync on $(date)"
  STASHED=true
else
  STASHED=false
fi

# Fetch from remote
log "Fetching from remote..."
if ! git fetch origin "$BRANCH"; then
  log "ERROR: Failed to fetch from remote"
  send_notification "Sync Error" "Failed to fetch from remote repository"
  exit 1
fi

# Check if we're behind remote
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "origin/$BRANCH")
BASE=$(git merge-base @ "origin/$BRANCH")

if [ "$LOCAL" = "$REMOTE" ]; then
  log "Already up-to-date"
elif [ "$LOCAL" = "$BASE" ]; then
  # We are behind, try to fast-forward
  log "We are behind remote, attempting to pull..."
  
  retry_count=0
  while [ $retry_count -lt $MAX_RETRIES ]; do
    if git pull --ff-only origin "$BRANCH"; then
      log "Successfully pulled changes"
      send_notification "Sync Successful" "Your MiddlewareConnect workspace is now up to date"
      break
    else
      retry_count=$((retry_count + 1))
      log "Pull attempt $retry_count failed, retrying in 10 seconds..."
      sleep 10
    fi
  done
  
  if [ $retry_count -eq $MAX_RETRIES ]; then
    log "ERROR: Failed to pull after $MAX_RETRIES attempts"
    send_notification "Sync Error" "Failed to pull changes after multiple attempts"
    exit 1
  fi
else
  # We have diverged
  log "WARNING: Local and remote have diverged, attempting merge..."
  
  if git merge "origin/$BRANCH" --no-commit; then
    # Auto-merge successful
    if git diff --cached --quiet; then
      log "No changes to commit after merge"
      git merge --abort
    else
      log "Auto-merge successful, committing..."
      git commit -m "Auto-merge from origin/$BRANCH on $(date)"
      send_notification "Merge Successful" "Auto-merged remote changes into your workspace"
    fi
  else
    # Conflict detected
    log "ERROR: Merge conflict detected"
    git merge --abort
    send_notification "Sync Conflict" "Merge conflict detected, manual intervention required"
    exit 1
  fi
fi

# Restore stashed changes if any
if [ "$STASHED" = true ]; then
  log "Restoring stashed changes..."
  git stash pop
fi

log "Sync completed successfully"
exit 0
