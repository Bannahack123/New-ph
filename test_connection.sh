#!/bin/bash

# URLs
CLOUDFLARE_URL="https://pharoah-erp.pages.dev"
SCRIPT_URL="https://script.google.com/macros/s/AKfycbyKFFt9WK-xB1qLRTD7M-b4jSlpCBoBfJ18x8FUP1wFBzbQ-dQgyjm1qPfvl2kQmaSl/exec"

echo "=================================================="
echo "   PHAROAH ERP • LIVE CLOUD DIAGNOSTIC ENGINE     "
echo "=================================================="
echo ""

# 1. TEST CLOUDFLARE PAGES
echo "⏳ 1. Checking Cloudflare Web Portal..."
CF_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -L "$CLOUDFLARE_URL")

if [ "$CF_STATUS" == "200" ]; then
    echo "🟢 [CLOUDFLARE PAGES]: ONLINE (HTTP $CF_STATUS)"
    echo "   🔗 URL: $CLOUDFLARE_URL"
else
    echo "🔴 [CLOUDFLARE PAGES]: FAILED (HTTP $CF_STATUS)"
    echo "   Check Cloudflare Pages dashboard or deployment."
fi

echo ""
echo "--------------------------------------------------"

# 2. TEST GOOGLE APPS SCRIPT RELAY
echo "⏳ 2. Checking Google Apps Script Relay Engine..."
SCRIPT_RESPONSE=$(curl -s -L "$SCRIPT_URL")

if echo "$SCRIPT_RESPONSE" | grep -q "ACTIVE"; then
    echo "🟢 [GOOGLE APPS SCRIPT]: CONNECTED & ACTIVE"
    echo "   📡 Response: $SCRIPT_RESPONSE"
else
    echo "🔴 [GOOGLE APPS SCRIPT]: OFFLINE OR ERROR"
    echo "   Raw Response: $SCRIPT_RESPONSE"
fi

echo ""
echo "--------------------------------------------------"

# 3. TEST GOOGLE DRIVE STORE SCAN
echo "⏳ 3. Testing Google Drive Live Sync Data..."
DRIVE_SCAN=$(curl -s -L "${SCRIPT_URL}?action=LIST_ALL_STORES")

if echo "$DRIVE_SCAN" | grep -q "SUCCESS"; then
    echo "🟢 [GOOGLE DRIVE SYNC]: HEALTHY & READY"
    echo "   📦 Synced Stores Info: $DRIVE_SCAN"
else
    echo "🟡 [GOOGLE DRIVE SYNC]: NO STORES SCANNED OR RE-AUTH REQUIRED"
    echo "   Details: $DRIVE_SCAN"
fi

echo ""
echo "=================================================="
echo "                 DIAGNOSTIC COMPLETE              "
echo "=================================================="
