---
description: Feed a local video file into Claude as visual context using ffmpeg frame extraction
argument-hint: <path/to/video.mp4> [optional question]
allowed-tools: Bash, Read, Task
---

Parse the arguments to extract the video path and optional question:

```
ARGUMENTS: $ARGUMENTS
```

**Step 1 — Parse arguments**

Split `$ARGUMENTS` on the first whitespace token:
- `VIDEO_PATH` = first token
- `USER_QUESTION` = remaining tokens (default: "Please analyze this video and describe what you see.")

If no `VIDEO_PATH` was provided, show this usage and stop:
```
Usage: /video <path/to/video.mp4> [optional question]

Examples:
  /video ~/Desktop/demo.mp4
  /video /tmp/recording.mov What is happening in this video?
  /video ~/Movies/lecture.mp4 Summarize the key points covered
```

**Step 2 — Validate the file**

Expand `~` in the path to the absolute home directory path. Check that the file exists using the Bash tool:
```bash
test -f "<expanded_path>" && echo "EXISTS" || echo "NOT_FOUND"
```

If not found, report:
```
Error: Video file not found: <path>
Please provide an absolute or home-relative path to a video file.
```
Then stop.

**Step 3 — Extract frames**

Run the extraction script via Bash, capturing stdout as the cache directory:
```bash
bash "${HOME}/.claude/claude-video/extract_frames.sh" "<ABS_VIDEO_PATH>"
```

If the exit code is non-zero or stdout is empty, report the error output to the user and stop.

**Step 4 — Read metadata and report to user**

Read `<CACHE_DIR>/metadata.json` using the Read tool.

Report to the user:
```
Extracted <frame_count> frames using <extraction_method> method.
Cache: <cache_dir>

Spawning video-analyzer to examine the frames...
```

**Step 5 — Spawn video-analyzer subagent**

Use the Task tool to spawn the `video-analyzer` agent with this prompt (fill in the actual values):

```
Video file: <video_path>
Metadata file: <cache_dir>/metadata.json
Frame count: <frame_count>
Extraction method: <extraction_method>

User's question: <USER_QUESTION>

Instructions: Read metadata.json first to get the full list of frame paths, then read each frame image in order using the Read tool. After examining all frames, answer the user's question.
```

**Step 6 — Relay the response**

Output the subagent's response verbatim to the user.
