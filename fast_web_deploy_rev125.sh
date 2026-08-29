#!/bin/bash

export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}  ⚡ FAST WEB BUILD (O1 RAM-OPTIMIZED) & DEPLOY     ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Clean previous build folder
echo -e "${YELLOW}[1/3] Resetting build folder...${NC}"
rm -rf build/web

# 2. Fast Compile using O1 Optimization (No RAM Crash)
echo -e "${YELLOW}[2/3] Compiling Flutter Web (Fast O1 Mode)...${NC}"
flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none --dart2js-optimization=O1 --no-tree-shake-icons

if [ $? -ne 0 ]; then
    echo -e "\n  ${RED}✖ Build failed.${NC}"
    exit 1
fi
echo -e "  ${GREEN}✔ Compiled successfully in build/web!${NC}\n"

# 3. Deploy to Cloudflare Pages
echo -e "${YELLOW}[3/3] Uploading fresh build to Cloudflare Pages...${NC}"
npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

git add .
git commit -m "Deploy Web Fast Build #PH-REV-125" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 DEPLOYED! Check live: https://pharoah-erp.pages.dev${NC}"
echo -e "${BLUE}====================================================${NC}"
