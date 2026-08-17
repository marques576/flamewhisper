<img src="packaging/macos/header.png" alt="FlameWhisper" width="100%" />

Speech-to-text accessibility tool for macOS (Apple Silicon). Runs local inference of OpenAI Whisper models optimized for MLX via [WhisperKit](https://github.com/argmaxinc/argmax-oss-swift). Hold **Fn** (Globe key), speak, release and text will appear where your cursor is.

## Install

Builds a release `.app` and installs it into `/Applications`:

```bash
git clone https://github.com/marques576/flamewhisper.git && cd flamewhisper && ./scripts/install.sh
```

The script runs [`scripts/package-app.sh`](scripts/package-app.sh) (release build + ad-hoc codesign), copies the app to `/Applications`, and reveals it in Finder.

1. **First launch**: right-click the app → **Open** (Gatekeeper dialog → Open)
2. Grant **Microphone** permission when prompted
3. Grant **Accessibility** permission for Fn key monitoring and typing at the cursor:  
   System Settings → Privacy & Security → Accessibility → add `FlameWhisper`

A microphone icon appears in the menu bar when running. Press and hold the Fn key to record.

On first launch, the default model is downloaded automatically (a few hundred MB) — this can take a few minutes depending on your connection.


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
  
