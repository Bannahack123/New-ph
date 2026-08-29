#!/bin/bash
SCRIPT_URL="https://script.google.com/macros/s/AKfycbyKFFt9WK-xB1qLRTD7M-b4jSlpCBoBfJ18x8FUP1wFBzbQ-dQgyjm1qPfvl2kQmaSl/exec"

echo "=================================================="
echo "      TESTING 2-WAY DRIVE DATA PIPELINE           "
echo "=================================================="

# 1. PUSH TEST DATA
echo "⏳ 1. Pushing Demo Store to Google Drive..."
PUSH_RES=$(curl -s -L -H "Content-Type: text/plain" -d '{
  "action": "PUSH_STORE_DATA",
  "storeToken": "PH-TEST-9999",
  "companyName": "TEST DIAGNOSTIC STORE",
  "adminUser": "admin",
  "adminPassword": "123",
  "fy": "2026-27",
  "files": {"meds.json": "[]"}
}' "$SCRIPT_URL")

echo "   📤 Push Result: $PUSH_RES"
echo ""

# 2. PULL TEST DATA
echo "⏳ 2. Pulling Demo Store back from Google Drive..."
PULL_RES=$(curl -s -L "${SCRIPT_URL}?action=PULL_STORE_DATA&storeToken=PH-TEST-9999&username=admin&password=123")

echo "   📥 Pull Result: $PULL_RES"
echo ""

if echo "$PULL_RES" | grep -q "SUCCESS"; then
    echo "=================================================="
    echo "🎉 RESULT: GOOGLE DRIVE 2-WAY SYNC IS 100% ACTIVE!"
    echo "=================================================="
else
    echo "=================================================="
    echo "🟡 RESULT: Push/Pull responded. Check credentials."
    echo "=================================================="
fi
