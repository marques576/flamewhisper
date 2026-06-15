@preconcurrency import AVFoundation
import CoreAudio

final class AudioRecorder: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private var samples: [Float] = []
    private let sampleRate: Double = 16000
    private let maxSeconds: Double = 30
    var selectedDeviceUID: String?

    static func availableInputDevices() -> [(name: String, uid: String)] {
        var result: [(String, String)] = []

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress, 0, nil, &dataSize
        )

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress, 0, nil, &dataSize, &deviceIDs
        )

        for deviceID in deviceIDs {
            var inputAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreamConfiguration,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: kAudioObjectPropertyElementMain
            )

            var propSize: UInt32 = 0
            AudioObjectGetPropertyDataSize(deviceID, &inputAddress, 0, nil, &propSize)

            guard propSize > 0 else { continue }

            let rawBuf = UnsafeMutableRawPointer.allocate(byteCount: Int(propSize), alignment: 1)
            defer { rawBuf.deallocate() }
            AudioObjectGetPropertyData(deviceID, &inputAddress, 0, nil, &propSize, rawBuf)

            let bufList = rawBuf.bindMemory(to: AudioBufferList.self, capacity: 1)
            let buffers = UnsafeMutableAudioBufferListPointer(bufList)
            let hasChannels = buffers.contains { $0.mNumberChannels > 0 }

            guard hasChannels else { continue }

            var cfName: Unmanaged<CFString>? = nil
            var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectGetPropertyData(deviceID, &nameAddress, 0, nil, &nameSize, &cfName)
            let name = cfName?.takeRetainedValue() as String? ?? ""

            var cfUID: Unmanaged<CFString>? = nil
            var uidSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
            var uidAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectGetPropertyData(deviceID, &uidAddress, 0, nil, &uidSize, &cfUID)
            let uid = cfUID?.takeRetainedValue() as String? ?? ""
            if !name.isEmpty {
                result.append((name, uid))
            }
        }

        return result
    }

    func start() {
        samples = []
        engine.stop()
        engine.reset()

        let inputNode = engine.inputNode

        if let uid = selectedDeviceUID, let deviceID = deviceID(for: uid) {
            setInputDevice(deviceID, on: inputNode)
        }
        let nativeFormat = inputNode.outputFormat(forBus: 0)

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        ) else { return }

        guard let converter = AVAudioConverter(from: nativeFormat, to: targetFormat) else { return }

        inputNode.installTap(
            onBus: 0,
            bufferSize: 4096,
            format: nativeFormat
        ) { [weak self] inBuf, _ in
            guard let self, self.samples.count < Int(self.sampleRate * self.maxSeconds) else { return }

            let ratio = self.sampleRate / nativeFormat.sampleRate
            let outCap = AVAudioFrameCount(Double(inBuf.frameLength) * ratio + 1)

            guard let outBuf = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: outCap
            ) else { return }

            var err: NSError?
            converter.convert(to: outBuf, error: &err) { _, outStatus in
                outStatus.pointee = .haveData
                return inBuf
            }

            if err == nil, let ptr = outBuf.floatChannelData?[0] {
                let n = Int(outBuf.frameLength)
                for i in 0..<n {
                    self.samples.append(ptr[i])
                }
            }
        }

        do {
            try engine.start()
        } catch {
            print("audio engine failed: \(error)")
        }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }

    func getSamples() -> [Float] {
        samples
    }

    private func deviceID(for uid: String) -> AudioDeviceID? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyTranslateUIDToDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID()
        var cfUID = uid as CFString
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = withUnsafeMutablePointer(to: &cfUID) { ptr in
            AudioObjectGetPropertyData(
                AudioObjectID(kAudioObjectSystemObject),
                &propertyAddress, UInt32(MemoryLayout<CFString>.size), ptr, &size, &deviceID
            )
        }
        return status == noErr ? deviceID : nil
    }

    private func setInputDevice(_ deviceID: AudioDeviceID, on inputNode: AVAudioInputNode) {
        engine.prepare()
        guard let audioUnit = inputNode.audioUnit else {
            print("no audioUnit available for input node")
            return
        }
        var id = deviceID
        let status = AudioUnitSetProperty(
            audioUnit,
            kAudioOutputUnitProperty_CurrentDevice,
            kAudioUnitScope_Output,
            1,
            &id,
            UInt32(MemoryLayout<AudioDeviceID>.size)
        )
        if status != noErr {
            print("failed to set input device \(deviceID): \(status)")
        }
    }
}
