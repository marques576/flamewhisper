import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppState.shared.installFnMonitor()
        Task {
            await AppState.shared.preloadModel()
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var isDownloading = false
    @Published var errorMessage: String?
    @Published var selectedMic: (name: String, uid: String)?

    let recorder = AudioRecorder()
    let transcriber = Transcriber()

    private init() {}

    func preloadModel() async {
        isDownloading = true
        do {
            try await transcriber.prepareModel()
        } catch {
            errorMessage = "failed to load model: \(error.localizedDescription)"
        }
        isDownloading = false
    }

    func startRecording() {
        guard !isRecording, !isProcessing, !isDownloading else { return }
        errorMessage = nil
        recorder.selectedDeviceUID = selectedMic?.uid
        isRecording = true
        recorder.start()
    }

    func stopAndTranscribe() {
        guard isRecording else { return }
        isRecording = false
        isProcessing = true
        recorder.stop()

        let audioData = recorder.getSamples()

        Task {
            do {
                let text = try await transcriber.transcribe(audioData)
                if !text.isEmpty {
                    await MainActor.run {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "no speech detected"
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            await MainActor.run {
                isProcessing = false
            }
        }
    }

    func selectModel(_ model: String) {
        guard model != transcriber.selectedModel else { return }
        transcriber.selectedModel = model
        errorMessage = nil
        isDownloading = true

        Task {
            do {
                try await transcriber.prepareModel()
            } catch {
                await MainActor.run {
                    errorMessage = "download failed: \(error.localizedDescription)"
                }
            }
            await MainActor.run {
                isDownloading = false
            }
        }
    }

    func installFnMonitor() {
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let fnHeld = event.modifierFlags.contains(.function)
            Task { @MainActor in
                guard let self else { return }
                if fnHeld && !self.isRecording && !self.isProcessing && !self.isDownloading {
                    self.startRecording()
                } else if !fnHeld && self.isRecording {
                    self.stopAndTranscribe()
                }
            }
        }
    }
}

@main
struct FlameWhisperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var appState = AppState.shared

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 4) {
                if let error = appState.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: 220, alignment: .leading)
                        .padding(.vertical, 2)
                    Divider()
                }

                if appState.isDownloading {
                    HStack {
                        ProgressView().scaleEffect(0.6).frame(width: 16, height: 16)
                        Text("loading \(appState.transcriber.selectedModel)...").font(.caption)
                    }
                    .padding(.vertical, 4)
                } else if appState.isProcessing {
                    HStack {
                        ProgressView().scaleEffect(0.6).frame(width: 16, height: 16)
                        Text("transcribing...").font(.caption)
                    }
                    .padding(.vertical, 4)
                } else if appState.isRecording {
                    HStack {
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Text("recording — release fn").font(.caption)
                    }
                    .padding(.vertical, 4)
                } else {
                    Text("hold fn to record").font(.caption)
                        .padding(.vertical, 4)
                }

                Divider()

                Menu("mic: \(appState.selectedMic?.name ?? "system default")") {
                    Button {
                        appState.selectedMic = nil
                    } label: {
                        HStack {
                            Text("system default")
                            if appState.selectedMic == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    Divider()
                    ForEach(AudioRecorder.availableInputDevices(), id: \.uid) { dev in
                        Button {
                            appState.selectedMic = dev
                        } label: {
                            HStack {
                                Text(dev.name)
                                if appState.selectedMic?.uid == dev.uid {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Menu("model: \(appState.transcriber.selectedModel)") {
                    ForEach(Transcriber.availableModels, id: \.self) { model in
                        Button {
                            appState.selectModel(model)
                        } label: {
                            HStack {
                                Text(model)
                                    .font(.system(.body, design: .monospaced))
                                if appState.transcriber.selectedModel == model {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Divider()

                Button("quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            .padding(8)
        } label: {
            if appState.isDownloading {
                Image(systemName: "arrow.down.circle")
            } else if appState.isProcessing {
                Image(systemName: "hourglass")
            } else if appState.isRecording {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
            } else {
                Image(systemName: "mic")
            }
        }
    }
}
