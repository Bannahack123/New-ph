#!/bin/bash
set -e

export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   ⚡ FAST WASM COMPILATION & CLOUDFLARE DEPLOY     ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Reset build folder
echo -e "${YELLOW}[1/3] Resetting build folder...${NC}"
rm -rf build/web

# 2. Compile using fast WebAssembly (WASM) Engine
echo -e "${YELLOW}[2/3] Compiling Web Workstation with WASM Engine (#PH-REV-126)...${NC}"
flutter build web -t lib/web_live_sync/web_main.dart --wasm --release --base-href "/" --pwa-strategy=none --no-tree-shake-icons

echo -e "  ${GREEN}✔ WASM compilation SUCCESSFUL in seconds!${NC}\n"

# 3. Upload to Cloudflare Pages & Git Push
echo -e "${YELLOW}[3/3] Uploading fresh WASM build to Cloudflare Pages...${NC}"
npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

git add .
git commit -m "Deploy Fast WASM Live Revision #PH-REV-126" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 DEPLOYED SUCCESSFULLY: https://pharoah-erp.pages.dev${NC}"
echo -e "${BLUE}====================================================${NC}"
