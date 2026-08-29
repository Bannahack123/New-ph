#!/bin/bash

export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🧹 FLUSHING RAM & DEPLOYING #PH-REV-125         ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Free memory from background processes & flush Linux RAM caches
echo -e "${YELLOW}[1/4] Freeing system RAM & flushing caches...${NC}"
pkill -f "analysis_server" 2>/dev/null || true
pkill -f "dart_language_server" 2>/dev/null || true
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches 2>/dev/null || true
free -m

# 2. Clean previous build artifacts
echo -e "\n${YELLOW}[2/4] Resetting build folder...${NC}"
rm -rf build/web

# 3. Compile Web Workstation with O1 Fast Mode
echo -e "\n${YELLOW}[3/4] Compiling Flutter Web with full RAM allocation...${NC}"
flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none --no-tree-shake-icons --dart2js-optimization=O1

if [ ! -f "build/web/main.dart.js" ]; then
    echo -e "\n${RED}✖ Compilation failed. Check terminal output above.${NC}"
    exit 1
fi
echo -e "  ${GREEN}✔ Web compilation SUCCESSFUL!${NC}\n"

# 4. Direct Upload to Cloudflare Pages
echo -e "${YELLOW}[4/4] Uploading fresh build to Cloudflare Pages...${NC}"
npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

git add .
git commit -m "Deploy Live Revision #PH-REV-125 (Clean RAM Build)" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 DEPLOYED! Verify live at: https://pharoah-erp.pages.dev${NC}"
echo -e "${BLUE}====================================================${NC}"
