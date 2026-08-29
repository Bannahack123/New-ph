#!/bin/bash
set -e

export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   ⚡ 10-SECOND FAST BUILD & DEPLOY (#PH-REV-126)  ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Clear stale build
echo -e "${YELLOW}[1/3] Resetting build folder...${NC}"
rm -rf build/web

# 2. Ultra-Fast O0 Compilation (Only 300MB RAM, 10 Seconds)
echo -e "${YELLOW}[2/3] Compiling Web Workstation (O0 Ultra-Fast Mode)...${NC}"
flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none --no-tree-shake-icons --dart2js-optimization=O0

echo -e "  ${GREEN}✔ Web compilation SUCCESSFUL in 10 seconds!${NC}\n"

# 3. Direct Upload to Cloudflare Pages & Git Push
echo -e "${YELLOW}[3/3] Uploading build to Cloudflare Pages...${NC}"
npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

git add .
git commit -m "Deploy Superfast Web Revision #PH-REV-126" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 LIVE DEPLOYED: https://pharoah-erp.pages.dev${NC}"
echo -e "${BLUE}====================================================${NC}"
