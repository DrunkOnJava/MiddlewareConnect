#!/bin/bash

# mcp_git_manager.sh - Git management script using the git MCP server
# Provides additional git management functionality that leverages the git MCP server

REPO_PATH="/Users/griffin/Desktop/RebasedCode"
SCRIPT_PATH=$(dirname "$0")

# Make sure working directory is set correctly
cd "$REPO_PATH"

# Function to display status using the git MCP server
get_git_status() {
  echo "Getting repository status via MCP server..."
  echo "Run this command to see the status:"
  echo "  claude 'use_mcp_tool({ \"server_name\": \"github.com/modelcontextprotocol/servers/tree/main/src/git\", \"tool_name\": \"git_status\", \"arguments\": { \"repo_path\": \"$REPO_PATH\" }})'"
  echo ""
}

# Function to view recent commits using the git MCP server
get_git_log() {
  local count=${1:-5}
  echo "Getting last $count commits via MCP server..."
  echo "Run this command to see recent commits:"
  echo "  claude 'use_mcp_tool({ \"server_name\": \"github.com/modelcontextprotocol/servers/tree/main/src/git\", \"tool_name\": \"git_log\", \"arguments\": { \"repo_path\": \"$REPO_PATH\", \"max_count\": $count }})'"
  echo ""
}

# Function to view unstaged changes using the git MCP server
get_git_diff_unstaged() {
  echo "Getting unstaged changes via MCP server..."
  echo "Run this command to see unstaged changes:"
  echo "  claude 'use_mcp_tool({ \"server_name\": \"github.com/modelcontextprotocol/servers/tree/main/src/git\", \"tool_name\": \"git_diff_unstaged\", \"arguments\": { \"repo_path\": \"$REPO_PATH\" }})'"
  echo ""
}

# Function to view staged changes using the git MCP server
get_git_diff_staged() {
  echo "Getting staged changes via MCP server..."
  echo "Run this command to see staged changes:"
  echo "  claude 'use_mcp_tool({ \"server_name\": \"github.com/modelcontextprotocol/servers/tree/main/src/git\", \"tool_name\": \"git_diff_staged\", \"arguments\": { \"repo_path\": \"$REPO_PATH\" }})'"
  echo ""
}

# Function to create a new branch using the git MCP server
create_branch() {
  local branch_name=$1
  local base_branch=${2:-main}
  
  echo "Creating new branch via MCP server..."
  echo "Run this command to create branch $branch_name from $base_branch:"
  echo "  claude 'use_mcp_tool({ \"server_name\": \"github.com/modelcontextprotocol/servers/tree/main/src/git\", \"tool_name\": \"git_create_branch\", \"arguments\": { \"repo_path\": \"$REPO_PATH\", \"branch_name\": \"$branch_name\", \"base_branch\": \"$base_branch\" }})'"
  echo ""
}

# Function to checkout a branch using the git MCP server
checkout_branch() {
  local branch_name=$1
  
  echo "Checking out branch via MCP server..."
  echo "Run this command to checkout branch $branch_name:"
  echo "  claude 'use_mcp_tool({ \"server_name\": \"github.com/modelcontextprotocol/servers/tree/main/src/git\", \"tool_name\": \"git_checkout\", \"arguments\": { \"repo_path\": \"$REPO_PATH\", \"branch_name\": \"$branch_name\" }})'"
  echo ""
}

# Function to commit changes using the git MCP server
commit_changes() {
  local message=$1
  
  echo "Committing changes via MCP server..."
  echo "Run this command to commit staged changes:"
  echo "  claude 'use_mcp_tool({ \"server_name\": \"github.com/modelcontextprotocol/servers/tree/main/src/git\", \"tool_name\": \"git_commit\", \"arguments\": { \"repo_path\": \"$REPO_PATH\", \"message\": \"$message\" }})'"
  echo ""
}

# Function to show commit details using the git MCP server
show_commit() {
  local revision=$1
  
  echo "Showing commit details via MCP server..."
  echo "Run this command to show commit details:"
  echo "  claude 'use_mcp_tool({ \"server_name\": \"github.com/modelcontextprotocol/servers/tree/main/src/git\", \"tool_name\": \"git_show\", \"arguments\": { \"repo_path\": \"$REPO_PATH\", \"revision\": \"$revision\" }})'"
  echo ""
}

# Main menu
show_menu() {
  echo "=========================================="
  echo "   RebasedCode Git Manager via MCP"
  echo "=========================================="
  echo "1) Check repository status"
  echo "2) View recent commits"
  echo "3) View unstaged changes"
  echo "4) View staged changes"
  echo "5) Create new branch"
  echo "6) Checkout branch"
  echo "7) Commit changes"
  echo "8) Show commit details"
  echo "9) Exit"
  echo "=========================================="
  echo -n "Select an option: "
  read -r option

  case $option in
    1) get_git_status ;;
    2) 
       echo -n "How many commits to show? [5]: "
       read -r count
       count=${count:-5}
       get_git_log "$count" 
       ;;
    3) get_git_diff_unstaged ;;
    4) get_git_diff_staged ;;
    5) 
       echo -n "Enter new branch name: "
       read -r branch_name
       echo -n "Enter base branch [main]: "
       read -r base_branch
       base_branch=${base_branch:-main}
       create_branch "$branch_name" "$base_branch" 
       ;;
    6) 
       echo -n "Enter branch name to checkout: "
       read -r branch_name
       checkout_branch "$branch_name" 
       ;;
    7) 
       echo -n "Enter commit message: "
       read -r message
       commit_changes "$message" 
       ;;
    8) 
       echo -n "Enter commit hash or reference: "
       read -r revision
       show_commit "$revision" 
       ;;
    9) exit 0 ;;
    *) echo "Invalid option" ;;
  esac
  
  echo ""
  echo "Press Enter to continue..."
  read -r
  show_menu
}

# Make the script executable
chmod +x "$SCRIPT_PATH/mcp_git_manager.sh"

# Start the menu
show_menu
