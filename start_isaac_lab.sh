#!/usr/bin/env bash
# One-time initialization: sets up Isaac Lab (clones + installs if needed)
# and installs the Go2 package into its Python environment.
# On success, writes .isaac_initialized so train.sh skips this next time.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default to the existing local install. Override with: export ISAACLAB_PATH=...
ISAACLAB_PATH="${ISAACLAB_PATH:-/media/raj/New_Volume_G/isaacsim/ilab1/IsaacLab}"
INIT_MARKER="${SCRIPT_DIR}/.isaac_initialized"

# --- Step 1: Clone IsaacLab only if not present ---
if [ ! -d "${ISAACLAB_PATH}" ]; then
    echo "[INFO] IsaacLab not found at ${ISAACLAB_PATH}. Cloning..."
    git clone https://github.com/isaac-sim/IsaacLab.git "${ISAACLAB_PATH}"
    echo "[INFO] Running IsaacLab installer (this takes ~30 min on first run)..."
    cd "${ISAACLAB_PATH}"
    ./isaaclab.sh --install
else
    echo "[INFO] IsaacLab already present at ${ISAACLAB_PATH} — skipping clone/install."
fi

# --- Step 2: Install the Go2 task package ---
echo "[INFO] Installing rob6323_go2 package into Isaac Lab Python env..."
"${ISAACLAB_PATH}/isaaclab.sh" -p -m pip install -e "${SCRIPT_DIR}/source/rob6323_go2"

mkdir -p "${SCRIPT_DIR}/logs"

# Write marker so train.sh skips initialization on future runs
touch "${INIT_MARKER}"

echo ""
echo "[INFO] Done. ISAACLAB_PATH=${ISAACLAB_PATH}"
echo "[INFO] Run ./train.sh to start training."
