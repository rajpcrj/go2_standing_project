#!/usr/bin/env bash
# Version-aware git commit and push.
#
# Usage:
#   ./commit_github.sh --success                                    # v1, v2, v3 ...
#   ./commit_github.sh --failure                                    # v0.1, v0.2, v1.1 ...
#   ./commit_github.sh --comments "A simple comment" --success
#   ./commit_github.sh --comments "A simple comment" --failure

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION_FILE="${SCRIPT_DIR}/version.txt"

# --- Parse arguments ---
MODE=""
COMMENT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --success|--failure)
            MODE="$1"
            shift
            ;;
        --comments)
            if [[ $# -lt 2 ]]; then
                echo "[ERROR] --comments requires a value"
                exit 1
            fi
            COMMENT="$2"
            shift 2
            ;;
        *)
            echo "Usage: $0 [--comments \"message\"] --success | --failure"
            exit 1
            ;;
    esac
done

if [[ -z "$MODE" ]]; then
    echo "Usage: $0 [--comments \"message\"] --success | --failure"
    exit 1
fi

# --- Read / initialize version ---
if [ ! -f "$VERSION_FILE" ]; then
    touch "$VERSION_FILE"
    CURRENT="0"
else
    # Get version from the last non-empty line: "v2.1: some comment" → "2.1"
    LAST_LINE=$(grep -v '^\s*$' "$VERSION_FILE" | tail -1)
    if [[ -z "$LAST_LINE" ]]; then
        CURRENT="0"
    else
        # Strip leading "v" and trailing ": comment"
        CURRENT="${LAST_LINE#v}"
        CURRENT="${CURRENT%%:*}"
    fi
fi

# Parse into major and minor
if [[ "$CURRENT" == *.* ]]; then
    MAJOR="${CURRENT%.*}"
    MINOR="${CURRENT#*.}"
else
    MAJOR="$CURRENT"
    MINOR="0"
fi

# --- Compute new version ---
if [[ "$MODE" == "--success" ]]; then
    NEW_VERSION="$((MAJOR + 1))"
else
    NEW_VERSION="${MAJOR}.$((MINOR + 1))"
fi

TAG="v${NEW_VERSION}"

# --- Append new entry to version.txt ---
if [[ -n "$COMMENT" ]]; then
    ENTRY="${TAG}: ${COMMENT}"
else
    ENTRY="${TAG}"
fi
echo "$ENTRY" >> "$VERSION_FILE"

# --- Stage everything ---
cd "$SCRIPT_DIR"
git add -A

# Nothing staged?
if git diff --cached --quiet; then
    echo "[WARN] No file changes detected. Only version bump will be committed."
    git add "$VERSION_FILE"
    if git diff --cached --quiet; then
        echo "[INFO] Nothing to commit at all. Exiting."
        exit 0
    fi
fi

# --- Build commit message ---
COMMIT_MSG="$ENTRY"

# --- Commit ---
git commit -m "$(cat <<EOF
${COMMIT_MSG}

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"

# --- Tag the commit ---
if git tag "$TAG" 2>/dev/null; then
    echo "[INFO] Tagged as ${TAG}"
else
    echo "[WARN] Tag ${TAG} already exists — skipping tag."
fi

# --- Push commit + tag ---
git push origin master
git push origin "$TAG" 2>/dev/null || echo "[WARN] Could not push tag (may already exist remotely)."

echo ""
echo "[INFO] v${CURRENT} → ${TAG} pushed to GitHub"
