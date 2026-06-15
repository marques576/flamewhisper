import Foundation
import WhisperKit

@MainActor
final class Transcriber: ObservableObject {
    @Published var selectedModel: String = "tiny" {
        didSet {
            if selectedModel != oldValue {
                pipe = nil
            }
        }
    }

    @Published var isLoading = false

    private var pipe: WhisperKit?

    static let availableModels = [
        "tiny", "tiny.en",
        "base", "base.en",
        "small", "small.en",
        "medium",
        "large-v3", "large-v3-v20240930_626MB",
    ]

    func prepareModel() async throws {
        guard pipe == nil else { return }
        isLoading = true
        defer { isLoading = false }
        pipe = try await WhisperKit(WhisperKitConfig(model: selectedModel, load: true))
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
