#!/bin/bash
set -e

export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🧹 PURGING DART CACHE & FRESH DEPLOY (#127)     ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Kill background hanging processes
pkill -f "dart" 2>/dev/null || true
pkill -f "analysis_server" 2>/dev/null || true
sync

# 2. Complete cache removal (.dart_tool + build)
echo -e "${YELLOW}[1/4] Deleting corrupt .dart_tool and build cache...${NC}"
rm -rf .dart_tool build

# 3. Fresh packages get
echo -e "${YELLOW}[2/4] Fetching fresh Flutter dependencies...${NC}"
flutter pub get

# 4. Compile Web Workstation
echo -e "${YELLOW}[3/4] Compiling fresh Web Workstation (#PH-REV-127)...${NC}"
flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none --no-tree-shake-icons

echo -e "  ${GREEN}✔ Web compilation SUCCESSFUL!${NC}\n"

# 5. Direct Upload to Cloudflare Pages & Git Push
echo -e "${YELLOW}[4/4] Uploading build to Cloudflare Pages...${NC}"
npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

git add .
git commit -m "Fresh Rebuild & Live Deploy #PH-REV-127" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 DEPLOYED SUCCESSFULLY: https://pharoah-erp.pages.dev${NC}"
echo -e "${BLUE}====================================================${NC}"
