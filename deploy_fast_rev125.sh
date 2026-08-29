#!/bin/bash
set -e

export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🚀 FAST RAM-SAFE COMPILE & DEPLOY (#PH-REV-125) ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Clean background tasks & flush RAM
echo -e "${YELLOW}[1/4] Freeing Codespaces RAM...${NC}"
pkill -f "analysis_server" 2>/dev/null || true
pkill -f "dart_language_server" 2>/dev/null || true
sync
echo 3 | sudo tee /proc/sys/vm/drop_caches 2>/dev/null || true

# 2. Reset build directory
echo -e "${YELLOW}[2/4] Resetting build folder...${NC}"
rm -rf build/web

# 3. Fast Compile with --optimization-level=1 (No RAM Crash)
echo -e "${YELLOW}[3/4] Compiling Flutter Web with Optimization Level 1...${NC}"
flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none --no-tree-shake-icons --optimization-level=1

echo -e "  ${GREEN}✔ Web compilation SUCCESSFUL!${NC}\n"

# 4. Upload to Cloudflare Pages & Git
echo -e "${YELLOW}[4/4] Uploading to Cloudflare Pages (pharoah-erp)...${NC}"
npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

git add .
git commit -m "Deploy Live Revision #PH-REV-125 (Optimization Level 1)" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 DEPLOY COMPLETE: https://pharoah-erp.pages.dev${NC}"
echo -e "${BLUE}====================================================${NC}"
