# AGENTS.md — FlameWhisper

## Build & run

```bash
cd flamewhisper
swift build
.build/arm64-apple-macosx/debug/FlameWhisper
```

Depends on `WhisperKit` from `argmaxinc/argmax-oss-swift`. First build pulls the entire argmax package (~70 Swift files), second build is seconds.

## Entrypoints

- `FlameWhisperApp.swift` — `@main` app, `MenuBarExtra` UI, `AppState` singleton (recording/processing/downloading state), Fn-key global monitor, model + mic picker
- `AudioRecorder.swift` — `AVAudioEngine` tap → downsample to 16kHz mono Float32 array via `AVAudioConverter`
- `Transcriber.swift` — wraps `WhisperKit`, model download + load, `transcribe(audioArray:)` → joined text

No tests. No CI. Single executable target.

## Hard-earned gotchas

### Model loading
`WhisperKitConfig(model:)` does **not** load models into memory by default. `load` defaults to `nil`, and `loadModels()` is skipped when no local `modelFolder` is provided. Always pass `load: true`:

```swift
pipe = try await WhisperKit(WhisperKitConfig(model: selectedModel, load: true))
```

Without this, models are lazy-loaded on first `transcribe()` call, causing a multi-second delay.

### Audio device switching
To switch input device on macOS, the `AVAudioEngine` must be **prepared** before `inputNode.audioUnit` is non-nil. The property to set is `kAudioOutputUnitProperty_CurrentDevice` on **`kAudioUnitScope_Output`, element 1** (not Global/element 0):

```swift
engine.prepare()
AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_CurrentDevice,
    kAudioUnitScope_Output, 1, &deviceID, ...)
```

### CoreAudio device enumeration
`kAudioDevicePropertyStreamConfiguration` returns an `AudioBufferList`, not a simple `UInt32` channel count. Parse with `UnsafeMutableAudioBufferListPointer`. CFString properties (`kAudioObjectPropertyName`, `kAudioDevicePropertyDeviceUID`) are returned as retained `Unmanaged<CFString>?` — use `takeRetainedValue()`.

### Fn key monitoring
Uses `NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged)` watching `.function` modifier flag. Requires **Accessibility** permission (System Settings → Privacy → Accessibility). Recording is blocked while downloading or processing.

### Clipboard-only output
Transcription is placed on `NSPasteboard.general` only — no Cmd+V injection. The `KeystrokeInjector` was intentionally removed.

### Model download UI
`selectModel()` calls `prepareModel()` immediately, which downloads + loads the model. `isDownloading` state blocks recording during download. Menu bar shows spinner + "loading <model>...".

## Dependencies

- **WhisperKit** via SPM from `https://github.com/argmaxinc/argmax-oss-swift.git` (1.0.0+)
- **macOS 14.0+** required
- Swift 6 toolchain (Xcode 16+ or Command Line Tools)
- `whisperkit-cli` (homebrew) is **not** needed — FlameWhisper uses WhisperKit as a library
