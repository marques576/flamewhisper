import CoreGraphics
import ApplicationServices

enum KeystrokeInjector {
    /// Maximum UTF-16 code units a single CGEvent can carry via its unicode
    /// string payload (`CGEventKeyboardEventSetUnicodeString` limit).
    private static let maxChunkSize = 20

    /// Types `text` at the current insertion point of the frontmost
    /// application by synthesizing keyboard events.
    ///
    /// Requires Accessibility permission (same grant the Fn-key monitor
    /// uses). Returns `false` if the process is not Accessibility-trusted, in
    /// which case no events are posted. Safe to call from the main actor.
    @discardableResult
    static func type(_ text: String) -> Bool {
        guard !text.isEmpty else { return true }
        guard AXIsProcessTrusted() else { return false }

        let units = Array(text.utf16)
        var index = 0
        while index < units.count {
            var end = Swift.min(index + maxChunkSize, units.count)
            // Never split a UTF-16 surrogate pair across chunks: if the last
            // unit we'd take is a high surrogate and a low surrogate follows,
            // leave the high surrogate for the next chunk. Backing up (rather
            // than extending) keeps every chunk within the 20-unit CGEvent
            // limit so the OS doesn't truncate and re-split the pair.
            if end < units.count, isHighSurrogate(units[end - 1]) {
                end -= 1
            }
            let count = end - index

            units.withUnsafeBufferPointer { buffer in
                guard let base = buffer.baseAddress else { return }
                let chunkPtr = base.advanced(by: index)

                let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true)
                event?.keyboardSetUnicodeString(stringLength: count, unicodeString: chunkPtr)
                event?.post(tap: .cghidEventTap)

                let upEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false)
                upEvent?.keyboardSetUnicodeString(stringLength: count, unicodeString: chunkPtr)
                upEvent?.post(tap: .cghidEventTap)
            }

            index = end
        }
        return true
    }

    private static func isHighSurrogate(_ unit: UInt16) -> Bool {
        unit >= 0xD800 && unit <= 0xDBFF
    }
}
