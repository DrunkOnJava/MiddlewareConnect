#!/usr/bin/env python3
"""
RebasedCode Git Sync Runner
This script runs the Git synchronization service with a clearly identifiable process name
"""

import os
import sys
import subprocess
import time

# This script will be shown as "python3 .../git_sync_runner.py" in Activity Monitor
# which is already better than just "bash"
os.environ['PYTHONUNBUFFERED'] = '1'  # Ensure output is not buffered

# Path to the sync script
SCRIPT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'auto_git_sync.sh')

# Rename the process in ps output
os.system(f'ps -p {os.getpid()} -o command= | sed "s/.*python.*/RebasedCodeGitSync/"')

# Log file paths
REPO_PATH = os.path.dirname(os.path.abspath(__file__))
LOG_FILE = os.path.join(REPO_PATH, "sync_log.txt")
ERROR_LOG = os.path.join(REPO_PATH, "sync_error.log")

# Log startup
with open(LOG_FILE, 'a') as f:
    f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: Starting RebasedCode Git Sync Runner\n")
    f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: Script path: {SCRIPT_PATH}\n")

print(f"Starting RebasedCode Git Sync process...")
print(f"Script path: {SCRIPT_PATH}")
print(f"Logs will be written to {LOG_FILE} and {ERROR_LOG}")

# Execute the shell script (this will run it in a subprocess with all its functionality)
try:
    process = subprocess.Popen(['/bin/bash', SCRIPT_PATH], 
                              stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE)
    
    # Wait for the script to complete (it shouldn't unless there's an error since it's a loop)
    out, err = process.communicate()
    
    # If we get here, something went wrong
    with open(ERROR_LOG, 'a') as f:
        f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: Git sync process terminated unexpectedly\n")
        f.write(f"Return code: {process.returncode}\n")
        if err:
            f.write(f"Error output: {err.decode()}\n")
    
    sys.exit(1)
        
except Exception as e:
    with open(ERROR_LOG, 'a') as f:
        f.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}: Exception running git sync script: {e}\n")
    sys.exit(1)
