#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}      🔍 DETECTING & CONFIGURING FLUTTER SDK        ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

# 1. Check if flutter exists in common paths
FLUTTER_PATH=""
POSSIBLE_PATHS=(
  "$HOME/flutter/bin"
  "/workspaces/flutter/bin"
  "/usr/local/flutter/bin"
  "/opt/flutter/bin"
  "/sdks/flutter/bin"
)

for p in "${POSSIBLE_PATHS[@]}"; do
  if [ -f "$p/flutter" ]; then
    FLUTTER_PATH="$p"
    break
  fi
done

# If not found in standard paths, search system
if [ -z "$FLUTTER_PATH" ]; then
  FOUND=$(find /home/codespace /opt /usr/local -name "flutter" -type f -executable 2>/dev/null | grep "/bin/flutter$" | head -n 1)
  if [ -n "$FOUND" ]; then
    FLUTTER_PATH=$(dirname "$FOUND")
  fi
fi

# 2. If Flutter found, configure PATH
if [ -n "$FLUTTER_PATH" ]; then
  echo -e "  ${GREEN}✔ FOUND FLUTTER SDK AT:${NC} $FLUTTER_PATH"
  export PATH="$FLUTTER_PATH:$PATH"
  if ! grep -q "$FLUTTER_PATH" ~/.bashrc; then
    echo "export PATH=\"$FLUTTER_PATH:\$PATH\"" >> ~/.bashrc
  fi
else
  # 3. If not found, download and install Flutter 3.27.4
  echo -e "  ${YELLOW}⚠ Flutter SDK not found on system. Installing Flutter 3.27.4...${NC}"
  cd $HOME
  wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.4-stable.tar.xz
  tar -xf flutter_linux_3.27.4-stable.tar.xz > /dev/null 2>&1
  rm flutter_linux_3.27.4-stable.tar.xz
  export PATH="$HOME/flutter/bin:$PATH"
  echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
  echo -e "  ${GREEN}✔ Flutter 3.27.4 installed successfully in $HOME/flutter/bin!${NC}"
  cd /workspaces/New-ph || cd /workspaces/* || true
fi

# Configure git safe directory & disable analytics
git config --global --add safe.directory "*"
flutter config --no-analytics > /dev/null 2>&1

echo ""
echo -e "${GREEN}✔ Active Flutter Version:${NC}"
flutter --version

echo ""
echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}         🚀 RE-RUNNING BUILD & ANALYZER TEST        ${NC}"
echo -e "${BLUE}====================================================${NC}\n"

./test_web_build.sh
