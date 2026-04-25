#!/bin/bash
#
# vphone-aio — All-in-one vPhone launcher
#
# Extracts vphone-cli.tar.zst (if needed), builds & boots the VM,
# starts iproxy tunnels for SSH and VNC, then waits.
# Press Ctrl+C to stop everything cleanly.
#
# Prerequisites:
#   - macOS with Xcode (swift, codesign)
#   - SIP/AMFI disabled (amfi_get_out_of_my_way=1)
#   - libimobiledevice (iproxy)  — brew install libimobiledevice
#   - zstd                       — brew install zstd
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARCHIVE="$SCRIPT_DIR/vphone-cli.tar.zst"
PROJECT="$SCRIPT_DIR/vphone-cli"

BOOT_PID=""
IPROXY_SSH_PID=""
IPROXY_VNC_PID=""

# ── Cleanup on exit ──────────────────────────────────────────────
cleanup() {
    echo ""
    echo "=========================================="
    echo "  Shutting down vPhone..."
    echo "=========================================="

    for pid_var in BOOT_PID IPROXY_SSH_PID IPROXY_VNC_PID; do
        pid="${!pid_var}"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
        fi
    done

    sleep 2

    for pid_var in BOOT_PID IPROXY_SSH_PID IPROXY_VNC_PID; do
        pid="${!pid_var}"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null
        fi
    done

    echo ""
    echo "  All processes stopped. Goodbye!"
    echo "=========================================="
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# ── Preflight checks ────────────────────────────────────────────
echo "=========================================="
echo "  vPhone — All-in-one Launcher"
echo "=========================================="
echo ""

missing=()
command -v swift   >/dev/null 2>&1 || missing+=("swift (Xcode)")
command -v iproxy  >/dev/null 2>&1 || missing+=("iproxy (brew install libimobiledevice)")

if [ ${#missing[@]} -gt 0 ]; then
    echo "ERROR: Missing required tools:"
    for m in "${missing[@]}"; do
        echo "  - $m"
    done
    exit 1
fi

ALL_SUFFIXES=(aa ab ac ad ae af ag)

REPO_URL="https://github.com/34306/vphone-aio/raw/refs/heads/main"

# ── Download missing parts ───────────────────────────────────────
download_missing_parts() {
    local need_download=false
    for suffix in "${ALL_SUFFIXES[@]}"; do
        local part_file="$SCRIPT_DIR/vphone-cli.tar.zst.part_${suffix}"
        if [ ! -f "$part_file" ]; then
            need_download=true
            break
        fi
    done

    if $need_download; then
        command -v wget >/dev/null 2>&1 || {
            echo "ERROR: wget not found. Install with: brew install wget"; exit 1
            exit 1
        }

        echo "       Some split parts are missing. Downloading..."
        echo ""
        for suffix in "${ALL_SUFFIXES[@]}"; do
            local part_file="$SCRIPT_DIR/vphone-cli.tar.zst.part_${suffix}"
            if [ ! -f "$part_file" ]; then
                echo "       Downloading vphone-cli.tar.zst.part_${suffix} ..."
                wget -q --show-progress -O "$part_file" \
                    "${REPO_URL}/vphone-cli.tar.zst.part_${suffix}?download=" || {
                    echo "ERROR: Failed to download part_${suffix}"
                    rm -f "$part_file"
                    exit 1
                }
            fi
        done
        echo ""
    fi
}

# ── Merge split parts & extract if needed ────────────────────────
if [ ! -d "$PROJECT" ]; then
    command -v zstd >/dev/null 2>&1 || {
        echo "ERROR: zstd not found. Install with: brew install zstd"
        exit 1
    }

    # Merge split parts if the full archive doesn't exist yet
    if [ ! -f "$ARCHIVE" ]; then
        echo "[1/4] Checking split parts..."
        download_missing_parts

        PARTS=("$SCRIPT_DIR"/vphone-cli.tar.zst.part_*)
        echo "[2/4] Merging ${#PARTS[@]} split parts into vphone-cli.tar.zst ..."
        cat "$SCRIPT_DIR"/vphone-cli.tar.zst.part_* > "$ARCHIVE"
        echo "       Done. ($(du -h "$ARCHIVE" | cut -f1))"
        echo ""

        echo "[3/4] Extracting vphone-cli.tar.zst ..."
    else
        echo "[1/4] vphone-cli.tar.zst already exists, skipping download & merge."
        echo ""
        echo "[3/4] Extracting vphone-cli.tar.zst ..."
    fi

    zstd -dc "$ARCHIVE" | tar xf - -C "$SCRIPT_DIR"
    echo "       Done."

    # Clean up the merged archive and split parts to save disk space
    rm -f "$ARCHIVE"
    rm -f "$SCRIPT_DIR"/vphone-cli.tar.zst.part_*
    echo "       Cleaned up archive and split parts to save space."
else
    echo "[1/4] vphone-cli/ already exists, skipping merge & extraction."
fi

echo ""

# ── Start iproxy tunnels ─────────────────────────────────────────
echo "[3/4] Starting iproxy tunnels ..."

iproxy 22222 22222 >/dev/null 2>&1 &
IPROXY_SSH_PID=$!
echo "       SSH : localhost:22222 -> device:22222"

iproxy 5901 5901 >/dev/null 2>&1 &
IPROXY_VNC_PID=$!
echo "       VNC : localhost:5901  -> device:5901"

# ── Build & Boot VM ──────────────────────────────────────────────
echo ""
echo "[4/4] Building and booting the VM ..."
echo ""
echo "=========================================="
echo ""
echo "  Connect via VNC : vnc://127.0.0.1:5901"
echo "  Connect via SSH : ssh -p 22222 root@127.0.0.1"
echo ""
echo "  Press Ctrl+C to stop everything."
echo ""
echo "=========================================="
echo ""

cd "$PROJECT"
./boot.sh
