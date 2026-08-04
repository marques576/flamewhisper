# FlameWhisper

Speech-to-text accessibility tool for macOS (Apple Silicon). Runs local inference of OpenAI Whisper models optimized for MLX via [WhisperKit](https://github.com/argmaxinc/argmax-oss-swift). Hold **Fn** (Globe key), speak, release and text will appear where your cursor is.

## Download

Get the latest from [GitHub Releases](https://github.com/marques576/flamewhisper/releases).

**Drag-install (recommended):** download `FlameWhisper.dmg`, double-click to open it, then drag `FlameWhisper.app` onto the **Applications** folder shortcut.

1. Download `FlameWhisper.dmg`
2. Open it and drag `FlameWhisper.app` to the **Applications** folder link
3. **First launch**: right-click the app → **Open** (Gatekeeper dialog → Open)
4. Grant **Microphone** permission when prompted
5. Grant **Accessibility** permission for Fn key monitoring and typing at the cursor:  
   System Settings → Privacy & Security → Accessibility → add `FlameWhisper`

Prefer a plain zip? Download `FlameWhisper.zip` instead — unzip and drag `FlameWhisper.app` to `/Applications`.

A microphone icon appears in the menu bar when running. Press and hold the Fn key to record.

Requires macOS 14+ (Apple Silicon).

## Building from source

```bash
git clone https://github.com/marques576/flamewhisper.git
cd flamewhisper
swift build
.build/arm64-apple-macosx/debug/FlameWhisper
```

Requires Xcode 16+ or Command Line Tools, Swift 6.

## Usage

| Action | How |
|---|---|
| Dictate | Hold **Fn** key, speak, release |
| Change model | Menu bar → `model:` submenu |
| Change mic | Menu bar → `mic:` submenu |
| Quit | Menu bar → quit, or Cmd+Q from the dropdown |

Transcription is typed at the frontmost app's cursor after each utterance. Keep the target app focused while dictation finishes.

## Models

Available via the model submenu:

| Model | Size | Notes |
|---|---|---|
| `tiny` | ~40MB | Fastest, least accurate |
| `tiny.en` | ~40MB | English-only tiny |
| `base` | ~140MB | Balanced |
| `base.en` | ~140MB | English-only base |
| `small` | ~460MB | Better accuracy |
| `small.en` | ~460MB | English-only small |
| `medium` | ~1.5GB | High accuracy |
| `large-v3` | ~3GB | Best accuracy |
| `large-v3-v20240930_626MB` | ~626MB | Compressed large-v3 |

Models download on first selection — a spinner appears while loading.

## Permissions

- **Microphone** — prompted on first recording
- **Accessibility** — required for Fn key monitoring and typing at the cursor  
  System Settings → Privacy & Security → Accessibility → add `FlameWhisper`
  
