# claude-video

A Claude Code plugin that feeds local video files into Claude as visual context via ffmpeg frame extraction.

Adds a `/video` slash command that:
1. Extracts frames from a local video using ffmpeg (scene detection, with time-based fallback)
2. Spawns a `video-analyzer` subagent that reads each frame and answers your question

No Docker, no YouTube, no cloud uploads — entirely local.

Inspired by [claude-vision](https://github.com/ellyseum/claude-vision).

---

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- [ffmpeg](https://ffmpeg.org/) with ffprobe

```bash
# macOS
brew install ffmpeg

# Ubuntu / Debian
sudo apt install ffmpeg
```

---

## Installation

```bash
git clone https://github.com/yanmastin/claude-video.git ~/Workspace/claude-video
cd ~/Workspace/claude-video && ./install.sh
```

The installer:
- Checks for ffmpeg and warns if missing
- Creates `~/.claude/claude-video/cache/` for extracted frames
- Registers the plugin in `~/.claude/plugins/config.json`

---

## Usage

```
/video <path/to/video.mp4> [optional question]
```

**Examples:**

```
/video ~/Desktop/demo.mp4
/video ~/Movies/lecture.mp4 Summarize the key points covered
/video /tmp/recording.mov What is happening in this video?
```

After the initial analysis, you can ask follow-up questions — the frames remain in context for the duration of the subagent session.

---

## How it works

1. **`/video` command** parses the path and question, runs `extract_frames.sh`, reads the metadata, and spawns the `video-analyzer` subagent.

2. **`extract_frames.sh`** uses ffmpeg's scene-detection filter (`select='gt(scene,0.3)'`) to pick visually distinct frames. If that yields fewer than 3 or more than 40 frames, it falls back to time-based extraction (1 frame every N seconds, capped at 40 frames). Results are saved to `~/.claude/claude-video/cache/<name>-<timestamp>/`.

3. **`video-analyzer` agent** reads `metadata.json` to get the frame list, reads each frame image using Claude's native image reading, builds a temporal narrative, and answers the question.

---

## Cache

Extracted frames are stored at:
```
~/.claude/claude-video/cache/<videoname>-<timestamp>/
    frames/
        frame_0001.jpg
        frame_0002.jpg
        ...
    metadata.json
```

Each run creates a new timestamped directory. Clean up manually as needed.

---

## Project structure

```
claude-video/
├── .claude-plugin/
│   └── plugin.json          Plugin manifest
├── commands/
│   └── video.md             /video slash command
├── agents/
│   └── video-analyzer.md    Frame-reading subagent
├── scripts/
│   └── extract_frames.sh    ffmpeg extraction logic
├── hooks/
│   ├── hooks.json           SessionStart hook declaration
│   └── session_start.sh     ffmpeg presence check
├── install.sh               One-shot installer
└── README.md
```

---

## License

MIT
