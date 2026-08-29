#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}      🔍 DEEP DIAGNOSTIC: LIVE CODE & CLOUDFLARE    ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Check Local Source Code
echo -e "${YELLOW}[1/4] Checking Local Source Code (web_top_bar.dart)...${NC}"
LOCAL_REV=$(grep -o "#PH-REV-[0-9]*" lib/web_live_sync/components/web_top_bar.dart 2>/dev/null)
if [ -n "$LOCAL_REV" ]; then
    echo -e "  ${GREEN}✔ Local Source Tag:${NC} ${GREEN}$LOCAL_REV${NC}"
else
    echo -e "  ${RED}✖ Tag not found in source code.${NC}"
fi
echo ""

# 2. Check Compiled Build Files
echo -e "${YELLOW}[2/4] Checking Compiled Bundle in build/web/...${NC}"
if [ -f "build/web/main.dart.js" ]; then
    BUILD_MATCH=$(grep -o "PH-REV-[0-9]*" build/web/main.dart.js | head -n 1)
    echo -e "  ${GREEN}✔ Compiled JS Bundle Tag:${NC} ${GREEN}#$BUILD_MATCH${NC}"
else
    echo -e "  ${RED}✖ build/web/main.dart.js nahi mila. Rebuilding required.${NC}"
fi
echo ""

# 3. Check Cloudflare Pages Deployments via Wrangler
echo -e "${YELLOW}[3/4] Checking Cloudflare Pages Live Deployments List...${NC}"
npx wrangler pages deployment list --project-name=pharoah-erp 2>/dev/null | head -n 10
echo ""

# 4. Check Live Web Server Output via curl
echo -e "${YELLOW}[4/4] Testing Live URL (https://pharoah-erp.pages.dev)...${NC}"
LIVE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "https://pharoah-erp.pages.dev" 2>/dev/null)
LIVE_DATE=$(curl -sI -m 10 "https://pharoah-erp.pages.dev" 2>/dev/null | grep -i "date:" | cut -d' ' -f2-)
CF_RAY=$(curl -sI -m 10 "https://pharoah-erp.pages.dev" 2>/dev/null | grep -i "cf-ray:" | tr -d '\r')

echo -e "  ${GREEN}✔ Live Status:${NC} HTTP $LIVE_STATUS"
echo -e "  ${GREEN}✔ Edge Ray ID:${NC} $CF_RAY"

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}                 DIAGNOSIS SUMMARY                  ${NC}"
echo -e "${BLUE}====================================================${NC}"

if [ -f "build/web/main.dart.js" ]; then
    echo -e "\n${YELLOW}⚡ Forcing Direct Wrangler Live Upload & Cloudflare Cache Invalidation...${NC}"
    npx wrangler pages deploy build/web --project-name=pharoah-erp --commit-dirty=true
fi
