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

# ── Merge split parts & extract if needed ────────────────────────
if [ ! -d "$PROJECT" ]; then
    command -v zstd >/dev/null 2>&1 || {
        echo "ERROR: zstd not found. Install with: brew install zstd"
        exit 1
    }

    # Merge split parts if the full archive doesn't exist yet
    if [ ! -f "$ARCHIVE" ]; then
        PARTS=("$SCRIPT_DIR"/vphone-cli.tar.zst.part_*)
        if [ ${#PARTS[@]} -eq 0 ] || [ ! -f "${PARTS[0]}" ]; then
            echo "ERROR: No vphone-cli.tar.zst or split parts found."
            echo "Make sure vphone-cli.tar.zst.part_* files are next to this script."
            exit 1
        fi

        echo "[1/5] Merging ${#PARTS[@]} split parts into vphone-cli.tar.zst ..."
        cat "$SCRIPT_DIR"/vphone-cli.tar.zst.part_* > "$ARCHIVE"
        echo "       Done. ($(du -h "$ARCHIVE" | cut -f1))"
        echo ""

        echo "[2/5] Extracting vphone-cli.tar.zst ..."
    else
        echo "[1/5] vphone-cli.tar.zst already exists, skipping merge."
        echo ""
        echo "[2/5] Extracting vphone-cli.tar.zst ..."
    fi

    zstd -dc "$ARCHIVE" | tar xf - -C "$SCRIPT_DIR"
    echo "       Done."

    # Clean up the merged archive to save disk space
    rm -f "$ARCHIVE"
    echo "       Cleaned up archive to save space."
else
    echo "[1/5] vphone-cli/ already exists, skipping merge & extraction."
fi

echo ""

# ── Build & Boot VM ──────────────────────────────────────────────
echo "[3/5] Building and booting the VM ..."
echo ""

cd "$PROJECT"
./boot.sh &
BOOT_PID=$!

# ── Wait for VM to become reachable ──────────────────────────────
echo ""
echo "[4/5] Waiting for VM to boot (up to 3 minutes) ..."

MAX_WAIT=180
ELAPSED=0
READY=false

while [ $ELAPSED -lt $MAX_WAIT ]; do
    if ! kill -0 "$BOOT_PID" 2>/dev/null; then
        echo ""
        echo "ERROR: VM process exited unexpectedly."
        exit 1
    fi

    if nc -z -w2 192.168.65.32 22222 2>/dev/null; then
        READY=true
        break
    fi

    sleep 5
    ELAPSED=$((ELAPSED + 5))
    printf "\r       Waiting... %ds / %ds" "$ELAPSED" "$MAX_WAIT"
done

echo ""

if [ "$READY" = true ]; then
    echo "       VM is up!"
else
    echo "       WARNING: Timed out, starting tunnels anyway."
fi

# ── Start iproxy tunnels ─────────────────────────────────────────
echo ""
echo "[5/5] Starting iproxy tunnels ..."

iproxy 22222 22222 >/dev/null 2>&1 &
IPROXY_SSH_PID=$!
echo "       SSH : localhost:22222 -> device:22222"

iproxy 5901 5901 >/dev/null 2>&1 &
IPROXY_VNC_PID=$!
echo "       VNC : localhost:5901  -> device:5901"

# ── All done ─────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo ""
echo "  vPhone is READY!"
echo ""
echo "  Connect via VNC : vnc://127.0.0.1:5901"
echo "  Connect via SSH : ssh -p 22222 root@127.0.0.1"
echo ""
echo "  Press Ctrl+C to stop everything."
echo ""
echo "=========================================="

wait "$BOOT_PID" 2>/dev/null || true
