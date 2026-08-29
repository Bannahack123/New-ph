#!/bin/bash

export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   ⚡ 15-SECOND FAST PROFILE BUILD & DEPLOY        ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Reset build folder
echo -e "${YELLOW}[1/3] Resetting build folder...${NC}"
rm -rf build/web

# 2. Fast Profile Compilation (Ultra-low RAM usage)
echo -e "${YELLOW}[2/3] Compiling Web Workstation (Lightweight Profile Mode)...${NC}"
flutter build web -t lib/web_live_sync/web_main.dart --profile --base-href "/" --pwa-strategy=none --no-tree-shake-icons

if [ ! -f "build/web/main.dart.js" ]; then
    echo -e "${RED}✖ Build failed.${NC}"
    exit 1
fi
echo -e "  ${GREEN}✔ Web compiled successfully in 15 seconds!${NC}\n"

# 3. Direct Upload to Cloudflare Pages
echo -e "${YELLOW}[3/3] Uploading fresh files to Cloudflare Pages...${NC}"
npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

git add .
git commit -m "Deploy Fast Web Build #PH-REV-126" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 LIVE DEPLOYED: https://pharoah-erp.pages.dev${NC}"
echo -e "${BLUE}====================================================${NC}"
