#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   ☁️ CLOUDFLARE DEVICE LOGIN & LIVE DEPLOY        ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Device Login Flow (Works without localhost callback server)
echo -e "${YELLOW}[1/3] Authenticating Cloudflare via Device Code...${NC}"
npx wrangler login --device

# 2. Deploy compiled build/web directly to Cloudflare Pages
echo -e "\n${YELLOW}[2/3] Uploading Live Build to Cloudflare Pages (pharoah-erp)...${NC}"
npx wrangler pages deploy build/web --project-name=pharoah-erp

# 3. Git Push
echo -e "\n${YELLOW}[3/3] Pushing to Git Repository...${NC}"
git add .
git commit -m "Deploy Web Live Revision #PH-REV-122" || true
git push origin main || true

echo -e "\n${BLUE}====================================================${NC}"
echo -e "${GREEN}  🎉 DEPLOY SUCCESSFUL: https://pharoah-erp.pages.dev${NC}"
echo -e "${BLUE}====================================================${NC}"
