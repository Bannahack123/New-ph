#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🔥 FORCE FRESH REBUILD & CLOUDFLARE UPLOAD      ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Clean old build folder
echo -e "${YELLOW}[1/4] Cleaning stale build cache...${NC}"
rm -rf build/web

# 2. Compile Fresh Web Workstation
echo -e "${YELLOW}[2/4] Compiling fresh Flutter Web bundle (#PH-REV-124)...${NC}"
flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none

# 3. Inject Cache-Buster timestamp in index.html
echo -e "${YELLOW}[3/4] Injecting anti-cache timestamp for Safari/Chrome...${NC}"
TS=$(date +%s)
sed -i "s/flutter_bootstrap.js/flutter_bootstrap.js?v=$TS/g" build/web/index.html 2>/dev/null || true

# 4. Force Wrangler Upload to Cloudflare Pages
echo -e "${YELLOW}[4/4] Uploading fresh files to Cloudflare Pages...${NC}"
npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

# 5. Git Commit & Push
git add .
git commit -m "Force Live Deploy #PH-REV-124 Fresh Build" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 DEPLOYED! Verify live at: https://pharoah-erp.pages.dev${NC}"
echo -e "${BLUE}====================================================${NC}"
