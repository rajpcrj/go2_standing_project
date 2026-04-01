#!/usr/bin/env bash
# Delegates to start_isaac_lab.sh for one-time local setup.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/start_isaac_lab.sh"
