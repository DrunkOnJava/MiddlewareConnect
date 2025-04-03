#!/bin/bash

# Swift Module Import Error Fixer
# Created: 2025-04-02
# 
# This script automatically fixes common Swift module import errors
# by identifying problematic import statements and offering fixes.

set -e

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}   Swift Module Import Error Fixer   ${NC}"
echo -e "${BLUE}=====================================${NC}"

# Default project directory
PROJECT_DIR="$(pwd)"
ERROR_LOG="swift_build_errors.log"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--project)
      PROJECT_DIR="$2"
      shift 2
      ;;
    -l|--log)
      ERROR_LOG="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# Validate project directory
if [ ! -d "$PROJECT_DIR" ]; then
  echo -e "${RED}Error: Project directory '$PROJECT_DIR' does not exist${NC}"
  exit 1
fi

# Function to extract import errors from build log
extract_import_errors() {
  grep -E "No such module '.*'" "$ERROR_LOG" | sort -u
}

# Function to extract file paths from error messages
extract_file_paths() {
  grep -E "^/.+\.swift" "$ERROR_LOG" | sort -u
}

# Function to fix common module import errors
fix_module_imports() {
  local file="$1"
  local module_name="$2"
  
  echo -e "${YELLOW}Analyzing imports in ${file}${NC}"
  
  # Create backup
  cp "$file" "${file}.bak"
  
  # Try to simplify complex module paths
  if grep -q "@_exported import.*$module_name" "$file"; then
    echo -e "${YELLOW}Found @_exported import with '$module_name' - fixing...${NC}"
    
    # Replace complex @_exported import paths with simpler alternatives
    sed -i '' -E "s/@_exported import [a-zA-Z0-9_.]+(\\.$module_name)(\\.[a-zA-Z0-9_.]+)*/@_exported import $module_name/g" "$file"
    echo -e "${GREEN}✓ Simplified @_exported import statements${NC}"
  fi
  
  # Try to fix regular imports with complex paths
  if grep -q "import.*$module_name" "$file"; then
    echo -e "${YELLOW}Found import with '$module_name' - fixing...${NC}"
    
    # Replace complex import paths with simpler alternatives
    sed -i '' -E "s/import [a-zA-Z0-9_.]+(\\.$module_name)(\\.[a-zA-Z0-9_.]+)*/import $module_name/g" "$file"
    echo -e "${GREEN}✓ Simplified import statements${NC}"
  fi
  
  echo -e "${GREEN}Completed analysis of ${file}${NC}"
}

# Function to fix import issues in a file
fix_file_import_issues() {
  local file="$1"
  
  if [ ! -f "$file" ]; then
    echo -e "${RED}Error: File '$file' does not exist${NC}"
    return 1
  fi
  
  echo -e "${BLUE}Processing file: $file${NC}"
  
  # Get list of all imported modules in the file
  local imports=$(grep -E "^import |^@_exported import " "$file" | sed -E 's/^import |^@_exported import //' | tr -d ';' | sed 's/\..*//')
  
  # For each imported module, try to fix if it's problematic
  for module in $imports; do
    if [[ "$module" == *"."* ]]; then
      # This is likely a problematic import with a complex path
      fix_module_imports "$file" "${module%%.*}"
    fi
  done
  
  # Check for complex module paths like MiddlewareConnect.Views.DocumentTools
  if grep -q -E "import [a-zA-Z0-9_]+\.[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+" "$file"; then
    echo -e "${YELLOW}Found complex import paths - fixing...${NC}"
    
    # Extract the base module name and fix
    local base_module=$(grep -E "import [a-zA-Z0-9_]+\.[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+" "$file" | head -1 | sed -E 's/import ([a-zA-Z0-9_]+).*/\1/')
    fix_module_imports "$file" "$base_module"
  fi
  
  echo -e "${GREEN}Completed processing of $file${NC}"
}

echo -e "${BLUE}Scanning project for Swift files...${NC}"

# Find all Swift files in the project
swift_files=$(find "$PROJECT_DIR" -name "*.swift" -type f | grep -v ".build" | grep -v ".swiftpm")
file_count=$(echo "$swift_files" | wc -l)

echo -e "${GREEN}Found $file_count Swift files${NC}"

# Check if error log exists
if [ -f "$ERROR_LOG" ]; then
  echo -e "${BLUE}Reading build errors from $ERROR_LOG...${NC}"
  
  # Extract problematic files from error log
  problematic_files=$(extract_file_paths)
  
  if [ -n "$problematic_files" ]; then
    echo -e "${YELLOW}Found problematic files in build log:${NC}"
    
    # Process each problematic file
    echo "$problematic_files" | while read -r file; do
      fix_file_import_issues "$file"
    done
  else
    echo -e "${GREEN}No specific file errors found in build log${NC}"
  fi
  
  # Extract module import errors
  import_errors=$(extract_import_errors)
  
  if [ -n "$import_errors" ]; then
    echo -e "${YELLOW}Found module import errors:${NC}"
    echo "$import_errors"
    
    # Extract module names from errors
    modules=$(echo "$import_errors" | sed -E "s/.*No such module '(.*)'.*/\1/")
    
    echo -e "${BLUE}Searching for files importing problematic modules...${NC}"
    
    # For each module, find files importing it and fix them
    echo "$modules" | while read -r module; do
      echo -e "${YELLOW}Searching for imports of '$module'...${NC}"
      
      files_with_module=$(grep -l "import.*$module" $swift_files 2>/dev/null || true)
      
      if [ -n "$files_with_module" ]; then
        echo -e "${GREEN}Found files importing '$module':${NC}"
        
        echo "$files_with_module" | while read -r file; do
          fix_module_imports "$file" "$module"
        done
      else
        echo -e "${RED}No files found importing '$module'${NC}"
      fi
    done
  else
    echo -e "${GREEN}No module import errors found in build log${NC}"
  fi
else
  echo -e "${YELLOW}No error log found at $ERROR_LOG${NC}"
  echo -e "${BLUE}Would you like to analyze all Swift files anyway? (y/n)${NC}"
  read -r response
  
  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Analyzing all Swift files...${NC}"
    
    echo "$swift_files" | while read -r file; do
      fix_file_import_issues "$file"
    done
  fi
fi

echo -e "${GREEN}Script completed successfully!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Run 'swift build' to see if the errors are resolved"
echo -e "2. If errors persist, try running this script again with the new error log"
echo -e "3. For stubborn errors, consider manually fixing the imports"

exit 0
