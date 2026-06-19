import Foundation
@preconcurrency import WhisperKit

@MainActor
final class Transcriber: ObservableObject {
    private static let modelKey = "selectedModel"

    @Published var selectedModel: String {
        didSet {
            if selectedModel != oldValue {
                pipe = nil
            }
            UserDefaults.standard.set(selectedModel, forKey: Self.modelKey)
        }
    }

    @Published var isLoading = false

    private var pipe: WhisperKit?

    init() {
        if let saved = UserDefaults.standard.string(forKey: Self.modelKey),
           Self.availableModels.contains(saved) {
            selectedModel = saved
        } else {
            selectedModel = "tiny"
        }
    }

    static let availableModels = [
        "tiny", "tiny.en",
        "base", "base.en",
        "small", "small.en",
        "medium",
        "large-v3", "large-v3-v20240930_626MB",
    ]

    func prepareModel(
        onDownloadProgress: (@MainActor (Double) -> Void)? = nil,
        onLoadStateChange: (@MainActor (Bool) -> Void)? = nil
    ) async throws {
        guard pipe == nil else { return }
        isLoading = true
        defer { isLoading = false }

        // Step 1: download model with progress callbacks
        let modelFolder: URL = try await WhisperKit.download(
            variant: selectedModel,
            progressCallback: { progress in
                Task { @MainActor in
                    onDownloadProgress?(progress.fractionCompleted)
                }
            }
        )

        // Step 2: load model into memory — track loading state
        onLoadStateChange?(true)
        let newPipe = try await WhisperKit(
            modelFolder: modelFolder.path,
            load: true,
            download: false
        )
        pipe = newPipe
        onLoadStateChange?(false)
    }

    func transcribe(_ audioSamples: [Float]) async throws -> String {
        if pipe == nil {
            try await prepareModel()
        }

        guard let pipe else {
            throw NSError(domain: "FlameWhisper", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "WhisperKit not initialized"])
        }

        let result = try await pipe.transcribe(audioArray: audioSamples)
        return result.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
