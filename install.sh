#!/usr/bin/env bash
# install.sh — Install claude-video into Claude Code
# Usage: ./install.sh

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
CACHE_DIR="${CLAUDE_DIR}/claude-video/cache"

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

# --- Install command and agent into Claude Code directories ---
mkdir -p "${CLAUDE_DIR}/commands" "${CLAUDE_DIR}/agents"

ln -sf "${PLUGIN_DIR}/commands/video.md" "${CLAUDE_DIR}/commands/video.md"
echo -e "${GREEN}✓ /video command installed:${NC} ~/.claude/commands/video.md"

ln -sf "${PLUGIN_DIR}/agents/video-analyzer.md" "${CLAUDE_DIR}/agents/video-analyzer.md"
echo -e "${GREEN}✓ video-analyzer agent installed:${NC} ~/.claude/agents/video-analyzer.md"

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Usage:"
echo "  /video ~/Desktop/demo.mp4"
echo "  /video ~/Movies/lecture.mp4 Summarize the key points"
echo "  /video /tmp/recording.mov What is happening in this video?"
echo ""
echo "Cache location: ${CACHE_DIR}"
