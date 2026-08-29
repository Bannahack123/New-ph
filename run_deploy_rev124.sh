#!/bin/bash

# Force include Flutter in PATH
export PATH="$HOME/flutter/bin:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🚀 COMPILING & DEPLOYING #PH-REV-124            ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Verify Flutter command
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}Downloading Flutter SDK...${NC}"
    cd $HOME
    wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.4-stable.tar.xz
    tar -xf flutter_linux_3.27.4-stable.tar.xz > /dev/null 2>&1
    rm flutter_linux_3.27.4-stable.tar.xz
    export PATH="$HOME/flutter/bin:$PATH"
    cd /workspaces/New-ph || cd /workspaces/* || true
fi

echo -e "  ${GREEN}✔ Flutter Active:${NC} $(flutter --version | head -n 1)"
echo ""

# 2. Build Fresh Production Web Bundle
echo -e "${YELLOW}[1/3] Compiling Web Workstation with normalized dates...${NC}"
flutter build web -t lib/web_live_sync/web_main.dart --release --base-href "/" --pwa-strategy=none

if [ $? -ne 0 ]; then
    echo -e "${RED}✖ Build failed. Check errors above.${NC}"
    exit 1
fi
echo -e "  ${GREEN}✔ Build successful in build/web!${NC}\n"

# 3. Direct Wrangler Deploy to Cloudflare Pages
echo -e "${YELLOW}[2/3] Uploading fresh bundle to Cloudflare Pages (pharoah-erp)...${NC}"
npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true

# 4. Push to Git
echo -e "\n${YELLOW}[3/3] Syncing with Git remote repository...${NC}"
git add .
git commit -m "Deploy Live Revision #PH-REV-124 with Universal imports & normalized dates" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 DEPLOYED! Check live at: https://pharoah-erp.pages.dev${NC}"
echo -e "${BLUE}====================================================${NC}"
