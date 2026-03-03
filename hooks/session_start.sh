#!/usr/bin/env bash
# Checks for ffmpeg at session start.
# Outputs {} if found, {"systemMessage": "WARNING: ..."} if not.
# Always exits 0 so it never blocks session startup.

if command -v ffmpeg &>/dev/null && command -v ffprobe &>/dev/null; then
  echo '{}'
else
  MISSING=""
  command -v ffmpeg &>/dev/null || MISSING="ffmpeg"
  command -v ffprobe &>/dev/null || MISSING="${MISSING:+$MISSING, }ffprobe"
  echo "{\"systemMessage\": \"WARNING: claude-video plugin requires ffmpeg but could not find: ${MISSING}. Install with: brew install ffmpeg (macOS) or apt install ffmpeg (Linux). The /video command will not work until ffmpeg is installed.\"}"
fi

exit 0
