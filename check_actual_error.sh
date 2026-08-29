#!/bin/bash

export PATH="$HOME/flutter/bin:$PATH"

echo -e "\033[0;34m====================================================\033[0m"
echo -e "\033[0;34m       🔍 DIAGNOSTIC: FINDING THE REAL ISSUE        \033[0m"
echo -e "\033[0;34m====================================================\033[0m\n"

echo -e "\033[1;33m[1] Checking System RAM & Memory...\033[0m"
free -h

echo -e "\n\033[1;33m[2] Running Code Analyzer (Finding Syntax Errors)...\033[0m"
flutter analyze lib/web_live_sync/

echo -e "\n\033[1;33m[3] Attempting Web Build & Capturing Exact Error...\033[0m"
# Running with verbose flag to capture everything in a log file
flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none --no-tree-shake-icons --dart2js-optimization=O1 -v > build_error_log.txt 2>&1

BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo -e "\n\033[0;31m✖ BUILD FAILED! Here is the exact reason from the log:\033[0m"
    echo "----------------------------------------------------"
    # Grep the exact exceptions or errors from the end of the log
    grep -iE "error:|exception:|failed " build_error_log.txt | tail -n 25
    echo "----------------------------------------------------"
    echo "Process exited with code: $BUILD_EXIT_CODE"
else
    echo -e "\n\033[0;32m✔ BUILD PASSED SUCCESSFULLY!\033[0m"
fi
