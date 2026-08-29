#!/bin/bash

export PATH="$HOME/flutter/bin:$PATH"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}         🔍 DEEP CODE ERROR INSPECTOR               ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Check Web Module Code with Static Analyzer
echo -e "${YELLOW}[1/2] Checking Web Modules (lib/web_live_sync/)...${NC}"
flutter analyze lib/web_live_sync/

echo -e "\n${YELLOW}[2/2] Running Verbose Compilation Check...${NC}"
flutter build web -t lib/web_live_sync/web_main.dart --release --no-tree-shake-icons --dart2js-optimization=O1 -v 2>&1 | tee /tmp/build_errors.log | grep -E "Error:|error:|Exception:|exception:|line [0-9]+|warning:" | head -n 35

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${YELLOW}Agar koi red error aaya hai toh upar check karein.${NC}"
echo -e "${BLUE}====================================================${NC}"
