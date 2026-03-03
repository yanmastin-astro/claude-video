#!/usr/bin/env bash
# Extract frames from a video file using ffmpeg.
# Usage: extract_frames.sh <absolute_video_path>
# Prints the cache directory path to stdout on success.
# Exits non-zero on error.

set -euo pipefail

MAX_FRAMES=40

# --- Validate input ---
if [[ $# -lt 1 ]]; then
  echo "Usage: extract_frames.sh <video_path>" >&2
  exit 1
fi

VIDEO="$1"

if [[ ! -f "$VIDEO" ]]; then
  echo "Error: File not found: $VIDEO" >&2
  exit 1
fi

if ! command -v ffmpeg &>/dev/null; then
  echo "Error: ffmpeg is not installed." >&2
  exit 1
fi

if ! command -v ffprobe &>/dev/null; then
  echo "Error: ffprobe is not installed." >&2
  exit 1
fi

# --- Setup cache directory ---
BASENAME="$(basename "${VIDEO%.*}")"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
CACHE_BASE="${HOME}/.claude/claude-video/cache"
OUT_DIR="${CACHE_BASE}/${BASENAME}-${TIMESTAMP}"
FRAMES_DIR="${OUT_DIR}/frames"

mkdir -p "$FRAMES_DIR"

# --- Get video duration ---
DURATION="$(ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 "$VIDEO" 2>/dev/null || echo "0")"
DURATION="${DURATION%.*}"
DURATION="${DURATION:-0}"

# --- Scene detection pass ---
ffmpeg -i "$VIDEO" \
  -vf "select='gt(scene,0.3)',scale=iw:ih" \
  -vsync vfr \
  -q:v 3 \
  "${FRAMES_DIR}/frame_%04d.jpg" \
  -y 2>/dev/null || true

FRAME_COUNT="$(find "$FRAMES_DIR" -name "frame_*.jpg" | wc -l | tr -d ' ')"

EXTRACTION_METHOD="scene_detection"

# --- Fallback to time-based if scene detection didn't give a good count ---
if [[ "$FRAME_COUNT" -lt 3 || "$FRAME_COUNT" -gt "$MAX_FRAMES" ]]; then
  # Clear previous frames
  rm -f "${FRAMES_DIR}"/frame_*.jpg

  # Calculate interval: 1 frame every N seconds, N = max(5, duration/40)
  if [[ "$DURATION" -gt 0 ]]; then
    INTERVAL=$(( DURATION / MAX_FRAMES ))
    [[ "$INTERVAL" -lt 5 ]] && INTERVAL=5
  else
    INTERVAL=5
  fi

  EXTRACTION_METHOD="time_${INTERVAL}s"

  ffmpeg -i "$VIDEO" \
    -vf "fps=1/${INTERVAL},scale=iw:ih" \
    -q:v 3 \
    "${FRAMES_DIR}/frame_%04d.jpg" \
    -y 2>/dev/null

  FRAME_COUNT="$(find "$FRAMES_DIR" -name "frame_*.jpg" | wc -l | tr -d ' ')"
fi

# --- Cap at MAX_FRAMES ---
if [[ "$FRAME_COUNT" -gt "$MAX_FRAMES" ]]; then
  # Sort and remove trailing frames
  mapfile -t ALL_FRAMES < <(find "$FRAMES_DIR" -name "frame_*.jpg" | sort)
  for (( i=MAX_FRAMES; i<${#ALL_FRAMES[@]}; i++ )); do
    rm -f "${ALL_FRAMES[$i]}"
  done
  FRAME_COUNT="$MAX_FRAMES"
fi

if [[ "$FRAME_COUNT" -eq 0 ]]; then
  echo "Error: No frames extracted from video." >&2
  exit 1
fi

# --- Build frames array for metadata ---
mapfile -t FRAME_FILES < <(find "$FRAMES_DIR" -name "frame_*.jpg" | sort)

FRAMES_JSON="["
for (( i=0; i<${#FRAME_FILES[@]}; i++ )); do
  [[ $i -gt 0 ]] && FRAMES_JSON+=","
  FRAMES_JSON+="\"${FRAME_FILES[$i]}\""
done
FRAMES_JSON+="]"

# --- Write metadata.json ---
cat > "${OUT_DIR}/metadata.json" <<EOF
{
  "video_path": "${VIDEO}",
  "extraction_method": "${EXTRACTION_METHOD}",
  "frame_count": ${FRAME_COUNT},
  "duration_seconds": ${DURATION},
  "cache_dir": "${OUT_DIR}",
  "frames_dir": "${FRAMES_DIR}",
  "frames": ${FRAMES_JSON}
}
EOF

# Output the cache directory (captured by the /video command)
echo "$OUT_DIR"
