#!/usr/bin/env bash
# install.sh — Register claude-video as a local Claude Code plugin
# Usage: ./install.sh

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
CACHE_DIR="${CLAUDE_DIR}/claude-video/cache"
PLUGINS_CONFIG="${CLAUDE_DIR}/plugins/config.json"

# --- Colors ---
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}claude-video installer${NC}"
echo "Plugin source: ${PLUGIN_DIR}"
echo ""

# --- Check for ffmpeg ---
if command -v ffmpeg &>/dev/null && command -v ffprobe &>/dev/null; then
  FFMPEG_VERSION="$(ffmpeg -version 2>&1 | head -1 | awk '{print $3}')"
  echo -e "${GREEN}✓ ffmpeg found:${NC} ${FFMPEG_VERSION}"
else
  MISSING=""
  command -v ffmpeg &>/dev/null || MISSING="ffmpeg"
  command -v ffprobe &>/dev/null || MISSING="${MISSING:+$MISSING, }ffprobe"
  echo -e "${YELLOW}⚠ Warning: ${MISSING} not found.${NC}"
  echo "  The /video command requires ffmpeg. Install it first:"
  echo "    macOS:  brew install ffmpeg"
  echo "    Linux:  sudo apt install ffmpeg"
  echo ""
fi

# --- Make scripts executable ---
chmod +x "${PLUGIN_DIR}/scripts/extract_frames.sh"
chmod +x "${PLUGIN_DIR}/hooks/session_start.sh"
echo -e "${GREEN}✓ Scripts made executable${NC}"

# --- Create cache directory ---
mkdir -p "$CACHE_DIR"
echo -e "${GREEN}✓ Cache directory created:${NC} ${CACHE_DIR}"

# --- Register plugin in ~/.claude/plugins/config.json ---
mkdir -p "${CLAUDE_DIR}/plugins"

if [[ -f "$PLUGINS_CONFIG" ]]; then
  # Read existing config
  EXISTING="$(cat "$PLUGINS_CONFIG")"
else
  EXISTING='{"plugins":[]}'
fi

# Check if already registered
if echo "$EXISTING" | grep -q "\"${PLUGIN_DIR}\""; then
  echo -e "${GREEN}✓ Plugin already registered at:${NC} ${PLUGIN_DIR}"
else
  # Use Python to safely update the JSON (available on macOS/Linux by default)
  python3 - <<PYEOF
import json, sys

config_path = "${PLUGINS_CONFIG}"
plugin_dir = "${PLUGIN_DIR}"

try:
    with open(config_path) as f:
        config = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    config = {"plugins": []}

if not isinstance(config.get("plugins"), list):
    config["plugins"] = []

# Remove any existing entry for this plugin (by path or name)
config["plugins"] = [
    p for p in config["plugins"]
    if p.get("path") != plugin_dir and p.get("name") != "claude-video"
]

config["plugins"].append({
    "name": "claude-video",
    "path": plugin_dir,
    "enabled": True
})

with open(config_path, "w") as f:
    json.dump(config, f, indent=2)

print("registered")
PYEOF

  echo -e "${GREEN}✓ Plugin registered in:${NC} ${PLUGINS_CONFIG}"
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Usage:"
echo "  /video ~/Desktop/demo.mp4"
echo "  /video ~/Movies/lecture.mp4 Summarize the key points"
echo "  /video /tmp/recording.mov What is happening in this video?"
echo ""
echo "Cache location: ${CACHE_DIR}"
