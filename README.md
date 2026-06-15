# FlameWhisper

Menu bar dictation app for macOS. Hold **Fn** (Globe key), speak, release — text lands on your clipboard. Built on [WhisperKit](https://github.com/argmaxinc/argmax-oss-swift).

## Build

```bash
cd flamewhisper
swift build
```

Requires macOS 14+, Xcode 16+ or Command Line Tools, Swift 6.

## Run

```bash
.build/arm64-apple-macosx/debug/FlameWhisper
```

A microphone icon appears in the menu bar.

## Usage

| Action | How |
|---|---|
| Dictate | Hold **Fn** key, speak, release |
| Change model | Menu bar → `model:` submenu |
| Change mic | Menu bar → `mic:` submenu |
| Quit | Menu bar → quit, or Cmd+Q from the dropdown |

Transcription is placed on the clipboard after each utterance — paste it anywhere.

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
- **Accessibility** — required for Fn key monitoring  
  System Settings → Privacy & Security → Accessibility → add `FlameWhisper`
  