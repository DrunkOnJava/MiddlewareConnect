# GitHub Integration Setup Guide

This guide will help you set up GitHub integration for your MiddlewareConnect project using both the GitHub sync script and MCP server.

## Part 1: GitHub Repository Setup

The repository doesn't currently exist. To create it:

1. You'll need a GitHub Personal Access Token (PAT) with the following permissions:
   - `repo` (Full control of private repositories)
   - `workflow` (if you plan to use GitHub Actions)

   Create one at: https://github.com/settings/tokens/new

2. Run the repository creation script with your GitHub PAT:
   ```bash
   node /Users/griffin/Desktop/RebasedCode/create_github_repo.js YOUR_GITHUB_PAT
   ```

   Replace `YOUR_GITHUB_PAT` with your actual Personal Access Token

## Part 2: Claude Desktop MCP Configuration

1. The MCP configuration file has been set up at:
   ```
   ~/Library/Application Support/Claude/claude_desktop_config.json
   ```

2. Update this file with your GitHub Personal Access Token:
   ```json
   {
     "mcpServers": {
       "github": {
         "command": "npx",
         "args": [
           "-y",
           "@modelcontextprotocol/server-github"
         ],
         "env": {
           "GITHUB_PERSONAL_ACCESS_TOKEN": "YOUR_GITHUB_PAT_HERE"
         }
       }
     }
   }
   ```

   Replace `YOUR_GITHUB_PAT_HERE` with your actual GitHub token.

## Part 3: GitHub Sync Script

1. The GitHub sync script has been fixed with proper permissions:
   ```
   /Users/griffin/Desktop/RebasedCode/Scripts/github_sync.sh
   ```

2. The script is scheduled to run every 30 minutes via launchd:
   ```
   ~/Library/LaunchAgents/com.middlewareconnect.github-sync.plist
   ```

3. If the sync service is not running, start it with:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.middlewareconnect.github-sync.plist
   ```

## Part 4: Testing Your Setup

1. After creating the repository, test the sync script:
   ```bash
   /Users/griffin/Desktop/RebasedCode/Scripts/github_sync.sh
   ```

2. Try using MCP GitHub tools in Claude Desktop:
   - Restart Claude Desktop after updating the configuration
   - Use the MCP GitHub tools to list repositories, create issues, etc.

## Troubleshooting

- If sync fails, check logs at:
  ```
  /Users/griffin/Desktop/RebasedCode/sync_error.log
  /Users/griffin/Desktop/RebasedCode/sync_output.log
  ```

- If MCP GitHub tools fail, check:
  - GitHub token permissions
  - Network connectivity
  - Claude Desktop logs
