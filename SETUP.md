# MiddlewareConnect Project Setup Guide

This guide will help you complete the setup of your MiddlewareConnect workspace with GitHub synchronization.

## Step 1: Create GitHub Repository

1. Go to [GitHub](https://github.com) and sign in to your account
2. Click the "+" button in the top right and select "New repository"
3. Name your repository `MiddlewareConnect`
4. Optionally add a description
5. Choose whether to make the repository public or private
6. Do NOT initialize with a README, .gitignore, or license (since we're uploading an existing project)
7. Click "Create repository"

## Step 2: Link Local Repository to GitHub

Once you've created the GitHub repository, GitHub will display commands to push an existing repository. You'll need to run the following commands in your terminal:

```bash
cd /Users/griffin/Desktop/RebasedCode
git remote add origin https://github.com/YOUR_USERNAME/MiddlewareConnect.git
git branch -M main
git add .
git commit -m "Initial commit"
git push -u origin main
```

Replace `YOUR_USERNAME` with your GitHub username.

## Step 3: Set Up Automatic Sync

To install the automatic sync service that will keep your workspace up-to-date:

```bash
# Copy the launchd plist file to your LaunchAgents directory
cp /Users/griffin/Desktop/RebasedCode/Scripts/com.middlewareconnect.github-sync.plist ~/Library/LaunchAgents/

# Load the service
launchctl load ~/Library/LaunchAgents/com.middlewareconnect.github-sync.plist
```

This will set up a background service that automatically syncs your workspace with GitHub every 30 minutes.

## Step 4: Open in Your Preferred Tools

### Xcode
Open the workspace in Xcode:
```bash
open /Users/griffin/Desktop/RebasedCode/MiddlewareConnect.xcworkspace
```

### VSCode
Open the workspace in VSCode:
```bash
code /Users/griffin/Desktop/RebasedCode/MiddlewareConnect.code-workspace
```

### Claude Desktop
Simply point Claude Desktop to the `/Users/griffin/Desktop/RebasedCode` directory when needed.

## Additional Information

- The sync script runs every 30 minutes and logs its activity to `/Users/griffin/Desktop/RebasedCode/sync_log.txt`
- If you want to manually trigger a sync, you can run `/Users/griffin/Desktop/RebasedCode/Scripts/github_sync.sh`
- If you need to modify the sync schedule, edit the `StartInterval` value in the plist file and reload the service

## Troubleshooting

- If synchronization fails, check the log files at `/Users/griffin/Desktop/RebasedCode/sync_error.log` and `/Users/griffin/Desktop/RebasedCode/sync_output.log`
- Make sure your Git credentials are properly configured on your system
- If you need to edit the sync script, it's located at `/Users/griffin/Desktop/RebasedCode/Scripts/github_sync.sh`
