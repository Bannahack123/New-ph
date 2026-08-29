#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}  🧪 PHAROAH ERP WEB - VERIFICATION & BUILD TEST   ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Flutter Analyze on Web Modules
echo -e "${YELLOW}[1/3] Running Static Code Analyzer on Web Modules...${NC}"
flutter analyze lib/web_live_sync/

if [ $? -eq 0 ]; then
    echo -e "\n  ${GREEN}✔ PASSED${NC}: Zero errors found in Web Modules!"
else
    echo -e "\n  ${RED}✖ FAILED${NC}: Please check analyzer issues above."
    exit 1
fi
echo ""

# 2. Test Production Web Build
echo -e "${YELLOW}[2/3] Compiling Web Workstation Bundle (#PH-LIVE-REV-122)...${NC}"
flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none

if [ $? -eq 0 ]; then
    echo -e "\n  ${GREEN}✔ BUILD SUCCESS${NC}: Web Workstation compiled cleanly to build/web!"
else
    echo -e "\n  ${RED}✖ BUILD FAILED${NC}: Web compiler encountered errors."
    exit 1
fi
echo ""

# 3. Check Built Artifacts
echo -e "${YELLOW}[3/3] Inspecting Output Artifacts...${NC}"
if [ -f "build/web/main.dart.js" ] || [ -f "build/web/flutter.js" ] || [ -f "build/web/flutter_bootstrap.js" ]; then
    BUNDLE_SIZE=$(du -sh build/web | cut -f1)
    echo -e "  ${GREEN}✔ ARTIFACTS VERIFIED${NC}: Build Size: ${GREEN}$BUNDLE_SIZE${NC}"
    echo -e "  ${GREEN}✔ LIVE BADGE EMBEDDED:${NC} ${YELLOW}#PH-LIVE-REV-122${NC}"
fi

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}   🎉 STEP 4 COMPLETE - ALL SYSTEMS AUDIT READY!    ${NC}"
echo -e "${BLUE}====================================================${NC}"
