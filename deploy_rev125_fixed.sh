#!/bin/bash

export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🚀 COMPILING & DEPLOYING LIVE: #PH-REV-125      ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Enable RAM Swap to prevent exit code -15
echo -e "${YELLOW}[1/4] Configuring RAM swap memory...${NC}"
sudo fallocate -l 4G /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1M count=4096 2>/dev/null
sudo chmod 600 /swapfile 2>/dev/null
sudo mkswap /swapfile 2>/dev/null
sudo swapon /swapfile 2>/dev/null || true

# 2. Reset build cache
echo -e "${YELLOW}[2/4] Cleaning previous build cache...${NC}"
rm -rf build/web

# 3. Compile Web Workstation with O1 Fast RAM mode
echo -e "${YELLOW}[3/4] Compiling Flutter Web (#PH-REV-125)...${NC}"
export DART_VM_OPTIONS="--old_gen_heap_size=2048"
flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none --dart2js-optimization=O1 --no-tree-shake-icons

if [ ! -f "build/web/main.dart.js" ]; then
    echo -e "${RED}✖ Compilation failed. Check logs.${NC}"
    exit 1
fi
echo -e "  ${GREEN}✔ Web compilation successful!${NC}\n"

# 4. Direct Upload to Cloudflare Pages
echo -e "${YELLOW}[4/4] Uploading to Cloudflare Pages (pharoah-erp)...${NC}"
npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

# 5. Git Commit & Push
git add .
git commit -m "Deploy Live Revision #PH-REV-125 Fix Sale Register" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 DEPLOYED! Live at: https://pharoah-erp.pages.dev${NC}"
echo -e "${BLUE}====================================================${NC}"
