# RebasedCode GitHub Synchronization System

This system provides automatic bidirectional synchronization between your local RebasedCode repository and GitHub, with integration for Xcode and VSCode.

## Features

- **Automatic Git Synchronization**: Changes are automatically committed and pushed to GitHub every 5 minutes
- **Cross-Editor Compatibility**: Works with both Xcode and VSCode
- **MCP Git Tools Integration**: Leverages the git MCP server for advanced Git operations
- **VSCode Git Extensions**: Recommended VSCode extensions for Git management
- **Xcode Git Integration**: Preconfigured Xcode Git settings

## Components

### 1. Git MCP Server

The Git MCP server provides Git repository interaction through the Model Context Protocol:

- Installed at `github.com/modelcontextprotocol/servers/tree/main/src/git`
- Provides tools for git operations like status, log, diff, commit, etc.
- Used by Claude to interact with the Git repository programmatically

### 2. Auto Git Sync Service

The `auto_git_sync.sh` script runs as a background service to automatically:

- Detect local changes in the repository
- Pull changes from the remote repository
- Resolve common merge conflicts
- Commit and push local changes to GitHub
- Log all sync operations for audit trails

### 3. MCP Git Manager

The `mcp_git_manager.sh` script provides an interactive menu for:

- Checking repository status via MCP
- Viewing commits and changes
- Creating and switching branches
- Committing changes
- Showing commit details

## Setup Instructions

1. Run the setup script:

```bash
./setup_github_sync.sh
```

This will:
- Make all scripts executable
- Install the launchd service for automatic syncing
- Configure VSCode workspace with Git extensions
- Set up Xcode Git integration

2. Open the project in VSCode:

```bash
code RebasedCode.code-workspace
```

## Using the Git MCP Server

You can interact with the Git MCP server through Claude:

1. Check repository status:
```
use_mcp_tool({ "server_name": "github.com/modelcontextprotocol/servers/tree/main/src/git", "tool_name": "git_status", "arguments": { "repo_path": "/Users/griffin/Desktop/RebasedCode" }})
```

2. View recent commits:
```
use_mcp_tool({ "server_name": "github.com/modelcontextprotocol/servers/tree/main/src/git", "tool_name": "git_log", "arguments": { "repo_path": "/Users/griffin/Desktop/RebasedCode", "max_count": 5 }})
```

3. View changes:
```
use_mcp_tool({ "server_name": "github.com/modelcontextprotocol/servers/tree/main/src/git", "tool_name": "git_diff_unstaged", "arguments": { "repo_path": "/Users/griffin/Desktop/RebasedCode" }})
```

## Sync Service Management

- View sync logs: `tail -f /Users/griffin/Desktop/RebasedCode/sync_log.txt`
- Stop sync service: `launchctl unload ~/Library/LaunchAgents/com.rebasedcode.gitsync.plist`
- Start sync service: `launchctl load ~/Library/LaunchAgents/com.rebasedcode.gitsync.plist`

## Troubleshooting

- Check error logs: `cat /Users/griffin/Desktop/RebasedCode/sync_error.log`
- Manually run sync: `./auto_git_sync.sh`
- Restart sync service if it's not working

## Notes

- Sync frequency is set to 5 minutes by default
- The `.gitignore` has been updated to exclude sync logs
- Xcode and VSCode settings are configured for optimal Git experience
