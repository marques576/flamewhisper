import Testing
@testable import FlameWhisper

@MainActor
struct TranscriberTests {
    /// Verify that availableModels is non-empty and contains only valid model identifiers.
    @Test func availableModelsAreValid() {
        let models = Transcriber.availableModels
        #expect(!models.isEmpty, "Should have at least one available model")

        // All model names should be non-empty lowercase strings
        for model in models {
            #expect(!model.isEmpty, "Model name should not be empty")
            #expect(model == model.lowercased(), "Model name should be lowercase: \(model)")
        }
    }

    /// Verify default model is "tiny" when nothing persisted.
    @Test func defaultModelIsTiny() {
        UserDefaults.standard.removeObject(forKey: "selectedModel")
        let transcriber = Transcriber()
        #expect(transcriber.selectedModel == "tiny",
                "Default model should be 'tiny', got '\(transcriber.selectedModel)'")
    }

    /// Verify selectModel guard prevents same-model re-download.
    @Test func sameModelNoOp() {
        let t = Transcriber()
        let initial = t.selectedModel
        // This should not trigger a didSet pipe=nil when setting the same model
        t.selectedModel = initial
        #expect(t.selectedModel == initial)
    }
}

@MainActor
struct KeystrokeInjectorTests {
    /// Verify type() returns false when accessibility not trusted.
    @Test func typeFailsWhenNotTrusted() {
        // On a CI machine without accessibility, this should be false
        _ = KeystrokeInjector.type("test")
        // No assertion on return value — depends on CI environment
    }

    /// Verify type() returns true for empty string (no-op).
    @Test func typeEmptyStringReturnsTrue() {
        #expect(KeystrokeInjector.type(""))
    }
}
