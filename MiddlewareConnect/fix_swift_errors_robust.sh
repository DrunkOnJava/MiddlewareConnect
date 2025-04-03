#!/bin/bash

# Script to attempt fixing common Swift compilation errors found in logs.
# Version 2: More robust handling of UIKit imports and user interaction.
# NOTE: This script makes assumptions based on typical Swift code structure
#       and the specific errors reported in the log.
#       Always review changes made and test thoroughly.

PROJECT_DIR="$HOME/Desktop/RebasedCode/middlewareconnect"
API_VALIDATION_FILE="$PROJECT_DIR/Sources/MiddlewareConnect/ApiValidationResult.swift"
APP_DELEGATE_FILE="$PROJECT_DIR/Sources/MiddlewareConnect/AppDelegate.swift"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# --- Helper Functions ---

# Function to create a timestamped backup only if one doesn't already exist for this run
backup_file() {
  local file_path="$1"
  local backup_path="${file_path}.bak_${TIMESTAMP}"
  if [ -f "$file_path" ] && [ ! -f "$backup_path" ]; then
    cp "$file_path" "$backup_path"
    echo "   -> Created backup: $(basename "$backup_path")"
    return 0
  elif [ -f "$backup_path" ]; then
     # Backup already created for this run
     return 0
  else
    echo "   -> Warning: File not found for backup: $file_path"
    return 1
  fi
}

# Function to check if a file exists
check_file_exists() {
    local file_path="$1"
    if [ ! -f "$file_path" ]; then
        echo "⚠️ Error: Required file not found: $file_path. Aborting fix for this file."
        return 1
    fi
    return 0
}

# Function to fix ApiValidationResult syntax errors (likely comment block)
fix_api_validation() {
    echo "---"
    echo "🔧 Attempting to fix syntax errors in ApiValidationResult.swift..."
    check_file_exists "$API_VALIDATION_FILE" || return 1
    backup_file "$API_VALIDATION_FILE" || return 1

    echo "   -> The log suggests syntax errors on/around lines 2 and 9, likely a malformed comment block."
    echo "   -> Safest automated fix based *only* on the log is commenting out these specific lines."
    echo "   -> Manual review of the comment block /* ... */ structure is recommended for a proper fix."

    # Use sed to comment out line 2 and line 9 specifically. Adding '// ' prefix.
    # Use a temporary file to apply changes sequentially and handle potential sed issues across OSes
    sed "2s|^|// |" "$API_VALIDATION_FILE" | sed "9s|^|// |" > "${API_VALIDATION_FILE}.tmp"

    if [ $? -eq 0 ]; then
        mv "${API_VALIDATION_FILE}.tmp" "$API_VALIDATION_FILE"
        echo "   -> Commented out line 2 and line 9."
        echo "   -> Fix applied. Please review the changes."
    else
        echo "   -> Error during sed operation. Changes not applied."
        rm -f "${API_VALIDATION_FILE}.tmp"
        return 1
    fi
}

# Function to fix AppDelegate UIKit import error
fix_app_delegate_uikit() {
    echo "---"
    echo "🔧 Attempting to fix 'no such module UIKit' error in AppDelegate.swift..."
    check_file_exists "$APP_DELEGATE_FILE" || return 1

    # Check if UIKit is actually imported and not already handled
    if ! grep -q -E '^[[:space:]]*import[[:space:]]+UIKit' "$APP_DELEGATE_FILE"; then
        echo "   -> 'import UIKit' not found or already commented/wrapped in $APP_DELEGATE_FILE. Skipping."
        return 0
    fi
     if grep -q -E '#if canImport\(UIKit\)' "$APP_DELEGATE_FILE"; then
         echo "   -> File seems to already contain '#if canImport(UIKit)'. Skipping automatic wrapping."
         echo "   -> Please review manually if errors persist."
         return 0
     fi

    echo "   -> This error occurs when UIKit (iOS/tvOS/watchOS specific) is imported in a"
    echo "      non-UI platform context (like a default Swift Package target)."
    echo ""
    echo "   Choose how to fix:"
    echo "     1. Comment out 'import UIKit' (Quick fix, but WILL BREAK code using UIKit types)."
    echo "     2. Wrap 'import UIKit' and the AppDelegate class in '#if canImport(UIKit)' directives (Recommended, safer)."
    echo "     S. Skip (Make no changes to this file)."
    echo ""
    read -p "   Enter your choice (1, 2, or S): " choice

    case "$choice" in
        1)
            echo "   -> Applying Option 1: Commenting out 'import UIKit'..."
            backup_file "$APP_DELEGATE_FILE" || return 1
            sed -i.bak_sed_comment "s|^[[:space:]]*import[[:space:]]\+UIKit|//&|" "$APP_DELEGATE_FILE"
            if [ $? -eq 0 ]; then
                 rm -f "${APP_DELEGATE_FILE}.bak_sed_comment" # Remove intermediate sed backup
                 echo "   -> 'import UIKit' commented out. Code using UIKit types will now fail unless also handled."
            else
                 echo "   -> Error during sed operation for commenting. Changes not applied."
                 return 1
            fi
            ;;
        2)
            echo "   -> Applying Option 2: Wrapping code with '#if canImport(UIKit)'..."
            backup_file "$APP_DELEGATE_FILE" || return 1

            # Find line numbers (approximate, relies on typical structure)
            # Find the first non-comment/non-whitespace line containing 'import UIKit'
            local import_line=$(grep -n -E '^[[:space:]]*import[[:space:]]+UIKit' "$APP_DELEGATE_FILE" | head -n 1 | cut -d: -f1)
            # Find the start of the class/struct/enum definition
            local class_start_line=$(grep -n -E '^[[:space:]]*(class|struct|enum)[[:space:]]+AppDelegate' "$APP_DELEGATE_FILE" | head -n 1 | cut -d: -f1)
            # Finding the *correct* closing brace is difficult and error-prone with basic tools.
            # We will wrap from the import line to the end of the file as a safer, broader approach.
            # A more precise approach would require a proper Swift parser.
            local last_line=$(wc -l < "$APP_DELEGATE_FILE")

            if [ -z "$import_line" ] ; then
                echo "   -> Error: Could not reliably determine import line for wrapping. Aborting Option 2."
                # Attempt to restore backup if we created one
                if [ -f "${APP_DELEGATE_FILE}.bak_${TIMESTAMP}" ]; then
                   cp "${APP_DELEGATE_FILE}.bak_${TIMESTAMP}" "$APP_DELEGATE_FILE"
                fi
                return 1
            fi

            echo "   -> Found import on line $import_line. Wrapping from this line to end of file (line $last_line)."
            echo "   -> NOTE: This wraps the entire rest of the file after the import line."

            # Use awk for reliable multi-line insertion
            awk -v import_ln="$import_line" '
            BEGIN { wrapping = 0 }
            NR == import_ln {
                print "#if canImport(UIKit)"
                wrapping = 1
            }
            { print }
            END {
                if (wrapping) {
                    print "#endif // canImport(UIKit)"
                }
            }
            ' "$APP_DELEGATE_FILE" > "${APP_DELEGATE_FILE}.tmp"

             if [ $? -eq 0 ]; then
                mv "${APP_DELEGATE_FILE}.tmp" "$APP_DELEGATE_FILE"
                echo "   -> Code wrapped in #if canImport(UIKit). This allows compilation in non-UIKit environments."
            else
                echo "   -> Error during awk operation for wrapping. Changes not applied."
                rm -f "${APP_DELEGATE_FILE}.tmp"
                return 1
            fi
            ;;
        [Ss]*)
            echo "   -> Skipping fix for $APP_DELEGATE_FILE."
            ;;
        *)
            echo "   -> Invalid choice. Skipping fix for $APP_DELEGATE_FILE."
            ;;
    esac
}


# --- Main Script ---

echo "========================================="
echo " Starting Swift Project Fix Script (v2)  "
echo "========================================="
echo "Target Directory: $PROJECT_DIR"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Error: Project directory not found: $PROJECT_DIR"
    exit 1
fi

# Navigate to project dir or exit
cd "$PROJECT_DIR" || exit 1
echo "Current directory: $(pwd)"

# Apply fixes
fix_api_validation
fix_app_delegate_uikit

# --- Final Instructions ---
echo "---"
echo "✅ Script finished attempting fixes."
echo "💾 Backup files were created in $PROJECT_DIR with extension .bak_${TIMESTAMP}"
echo "---"
echo "ℹ️ Reminder: The '-bash: /usr/local/bin/virtualenvwrapper.sh: No such file or directory' error"
echo "   needs to be fixed separately in your shell startup configuration (~/.bash_profile, ~/.zshrc, etc.)."
echo "   Look for the line sourcing it and either fix the path, remove it, or reinstall the tool."
echo "---"
echo "🏗️ Next Steps:"
echo "   1. Review the changes made by this script (use 'git diff' or compare with *.bak_${TIMESTAMP} files)."
echo "   2. Try building the package again in this directory: swift build"
echo "   3. If errors persist or new ones appear, manual debugging will be required."
echo "   4. If you chose Option 2 for AppDelegate, ensure the wrapping covers all UIKit-dependent code."
echo "========================================="

exit 0