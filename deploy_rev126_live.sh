#!/bin/bash
set -e

export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🚀 COMPILING & DEPLOYING: #PH-REV-126           ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Reset build directory
echo -e "${YELLOW}[1/3] Resetting build folder...${NC}"
rm -rf build/web

# 2. Fast Compile with valid O1 Optimization
echo -e "${YELLOW}[2/3] Compiling Flutter Web (O1 Valid Fast Mode)...${NC}"
flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none --no-tree-shake-icons --dart2js-optimization O1

echo -e "  ${GREEN}✔ Web compilation SUCCESSFUL!${NC}\n"

# 3. Upload to Cloudflare Pages & Git Push
echo -e "${YELLOW}[3/3] Uploading to Cloudflare Pages (pharoah-erp)...${NC}"
npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

git add .
git commit -m "Deploy Live Revision #PH-REV-126 Fast O1 Build" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 DEPLOYED SUCCESSFULLY: https://pharoah-erp.pages.dev${NC}"
echo -e "${BLUE}====================================================${NC}"
