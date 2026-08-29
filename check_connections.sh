#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   🔍 PHAROAH ERP - CLOUD & BACKEND CONNECTIVITY    ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Check Google Apps Script Cloud Relay
GAS_URL="https://script.google.com/macros/s/AKfycbyKFFt9WK-xB1qLRTD7M-b4jSlpCBoBfJ18x8FUP1wFBzbQ-dQgyjm1qPfvl2kQmaSl/exec"
echo -e "${YELLOW}[1/4] Checking Google Apps Script Backend...${NC}"
GAS_RESPONSE=$(curl -s -L -m 15 "$GAS_URL" 2>/dev/null)

if echo "$GAS_RESPONSE" | grep -q "Pharoah ERP Cloud Relay Engine"; then
    echo -e "  ${GREEN}✔ CONNECTED${NC}: Google Apps Script Relay is LIVE & Active!"
    echo -e "  ${GREEN}✔ Response:${NC} $GAS_RESPONSE"
else
    # Try alternate endpoint if URL typo in config
    ALT_URL="https://script.google.com/macros/s/AKfycbyKFFt9WK-xB1qLRTD7M-b4jSlpCBoBfJ18x8FUP1wFBzbQ-dQgyjm1qPfv12kQmaSl/exec"
    ALT_RESPONSE=$(curl -s -L -m 15 "$ALT_URL" 2>/dev/null)
    if echo "$ALT_RESPONSE" | grep -q "Pharoah ERP Cloud Relay Engine"; then
        echo -e "  ${GREEN}✔ CONNECTED (Alt Endpoint)${NC}: Google Apps Script Relay is LIVE!"
        echo -e "  ${GREEN}✔ Response:${NC} $ALT_RESPONSE"
    else
        echo -e "  ${RED}✖ FAILED${NC}: Google Apps Script se connection nahi hua."
        echo -e "  ${YELLOW}Raw output:${NC} ${GAS_RESPONSE:-'No response / Timeout'}"
    fi
fi
echo ""

# 2. Check Cloudflare Pages Deployment Live Status
CF_URL="https://pharoah-erp.pages.dev"
echo -e "${YELLOW}[2/4] Checking Cloudflare Pages Live URL ($CF_URL)...${NC}"
CF_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "$CF_URL" 2>/dev/null)

if [ "$CF_STATUS" -eq 200 ] || [ "$CF_STATUS" -eq 304 ]; then
    echo -e "  ${GREEN}✔ CONNECTED (HTTP $CF_STATUS)${NC}: Cloudflare Pages portal LIVE chal raha hai!"
else
    echo -e "  ${RED}✖ WARNING (HTTP $CF_STATUS)${NC}: Site reachable nahi hai ya deployment pending hai."
fi
echo ""

# 3. Check Cloudflare Wrangler Account Cache / Config
echo -e "${YELLOW}[3/4] Checking Cloudflare Wrangler Credentials in Repo...${NC}"
if [ -f ".wrangler/cache/pages.json" ] && [ -f ".wrangler/cache/wrangler-account.json" ]; then
    PROJECT_NAME=$(grep -o '"project_name": "[^"]*' .wrangler/cache/pages.json | cut -d'"' -f4)
    ACCOUNT_ID=$(grep -o '"account_id": "[^"]*' .wrangler/cache/pages.json | cut -d'"' -f4)
    echo -e "  ${GREEN}✔ FOUND${NC}: Project Name: ${GREEN}$PROJECT_NAME${NC} | Account ID: ${GREEN}$ACCOUNT_ID${NC}"
else
    echo -e "  ${YELLOW}⚠ NOTICE${NC}: .wrangler cache files nahi mili."
fi
echo ""

# 4. Check Google Clasp Setup
echo -e "${YELLOW}[4/4] Checking Google Clasp Configuration...${NC}"
if [ -f "google_backend/.clasp.json" ]; then
    SCRIPT_ID=$(grep -o '"scriptId": "[^"]*' google_backend/.clasp.json | cut -d'"' -f4)
    echo -e "  ${GREEN}✔ FOUND${NC}: Google Script ID: ${GREEN}$SCRIPT_ID${NC}"
else
    echo -e "  ${YELLOW}⚠ NOTICE${NC}: google_backend/.clasp.json nahi mila."
fi

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${BLUE}                  CHECK COMPLETED                   ${NC}"
echo -e "${BLUE}====================================================${NC}"
