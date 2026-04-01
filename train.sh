#!/usr/bin/env bash
# Run training locally, then automatically evaluate and record a video.
# Isaac Sim reinitializes for the evaluation step — this is unavoidable since
# train.py and play.py each own their own simulation session.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISAACLAB_PATH="${ISAACLAB_PATH:-/media/raj/New_Volume_G/isaacsim/ilab1/IsaacLab}"
INIT_MARKER="${SCRIPT_DIR}/.isaac_initialized"

# Initialize on first run
if [ ! -f "${INIT_MARKER}" ]; then
    echo "[INFO] First run detected — initializing via start_isaac_lab.sh..."
    "${SCRIPT_DIR}/start_isaac_lab.sh"
fi

# --- Training ---
echo "[INFO] Starting training with ISAACLAB_PATH=${ISAACLAB_PATH}"
"${ISAACLAB_PATH}/isaaclab.sh" -p "${SCRIPT_DIR}/scripts/rsl_rl/train.py" \
    --task=Template-Rob6323-Go2-Direct-v0 \
    --headless \
    "$@"

# --- Find the checkpoint from the run that just finished ---
LOG_DIR="${SCRIPT_DIR}/logs/rsl_rl/go2_flat_direct"
LATEST_DIR=$(ls -td "${LOG_DIR}"/*/  2>/dev/null | head -n 1 || true)

if [ -z "${LATEST_DIR:-}" ]; then
    echo "[WARN] No training run found under ${LOG_DIR} — skipping evaluation."
    exit 0
fi

LATEST_DIR="${LATEST_DIR%/}"
CHECKPOINT="${LATEST_DIR}/model_499.pt"

if [ ! -f "${CHECKPOINT}" ]; then
    echo "[WARN] Checkpoint not found at ${CHECKPOINT} — skipping evaluation."
    exit 0
fi

# --- Evaluation + video recording ---
echo ""
echo "[INFO] Training complete. Running evaluation (Isaac Sim will reinitialize)..."
echo "[INFO] Checkpoint: ${CHECKPOINT}"
"${ISAACLAB_PATH}/isaaclab.sh" -p "${SCRIPT_DIR}/scripts/rsl_rl/play.py" \
    --task=Template-Rob6323-Go2-Direct-v0 \
    --checkpoint "${CHECKPOINT}" \
    --video \
    --video_length 1000 \
    --headless

echo ""
echo "[INFO] Done. Video saved to: ${LATEST_DIR}/videos/play/"
