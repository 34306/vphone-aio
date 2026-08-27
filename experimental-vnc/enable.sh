#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${1:-}"

if [ -z "$PROJECT_DIR" ]; then
  echo "Usage: $0 <path-to-vphone-cli>"
  exit 1
fi

if [ ! -d "$PROJECT_DIR/Sources" ]; then
  echo "ERROR: Sources directory not found: $PROJECT_DIR/Sources"
  exit 1
fi

copy_file() {
  local rel="$1"
  local src="$SCRIPT_DIR/$rel"
  local dst="$PROJECT_DIR/$rel"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "  updated: $rel"
}

echo "[vphone-aio] Applying experimental VNC source overrides..."
copy_file "Sources/vphone-cli/VPhoneCLI.swift"
copy_file "Sources/vphone-cli/VPhoneVNC.swift"
copy_file "Sources/vphone-cli/VPhoneVM.swift"
copy_file "Sources/VPhoneObjC/include/VPhoneObjC.h"
copy_file "Sources/VPhoneObjC/VPhoneObjC.m"

BOOT_SH="$PROJECT_DIR/boot.sh"
if [ -f "$BOOT_SH" ] && ! grep -q -- '--vnc-experimental' "$BOOT_SH"; then
  awk '
    {
      if ($0 ~ /--no-graphics/) {
        print "    --vnc-experimental \\"
      } else {
        print $0
      }
    }
  ' "$BOOT_SH" > "$BOOT_SH.tmp"
  mv "$BOOT_SH.tmp" "$BOOT_SH"
  chmod +x "$BOOT_SH"
  echo "  updated: boot.sh (added --vnc-experimental)"
fi

echo "[vphone-aio] Experimental VNC mode enabled."
