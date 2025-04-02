#!/bin/bash

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define paths
PBXPROJ_PATH="$DIR/project.pbxproj"
COMPLETION_PATH="$DIR/project_completion.txt"
TEMP_PATH="$DIR/project.pbxproj.new"

# Find the line that contains MTL_ENABLE_DEBUG_INFO without the value
MERGE_LINE=$(grep -n "MTL_ENABLE_DEBUG_INFO" "$PBXPROJ_PATH" | tail -1 | cut -d: -f1)

if [ -z "$MERGE_LINE" ]; then
    echo "Error: Could not find the merge point in project.pbxproj"
    exit 1
fi

# Create a new file with the content up to the merge line
head -n "$MERGE_LINE" "$PBXPROJ_PATH" > "$TEMP_PATH"

# Append the completion content
cat "$COMPLETION_PATH" >> "$TEMP_PATH"

# Backup the original
cp "$PBXPROJ_PATH" "$PBXPROJ_PATH.bak"

# Replace with the new file
mv "$TEMP_PATH" "$PBXPROJ_PATH"

echo "Project file fixed successfully!"
