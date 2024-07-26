/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditTextCapture

public enum FrameworksTextCaptureEvent: String, CaseIterable {
    case didCaptureText = "TextCaptureListener.didCaptureText"
}

fileprivate extension Event {
    init(_ event: FrameworksTextCaptureEvent) {
        self.init(name: event.rawValue)
    }
}

fileprivate extension Emitter {
    func hasListener(for event: FrameworksTextCaptureEvent) -> Bool {
        hasListener(for: event.rawValue)
    }
}

@available(*, deprecated)
open class FrameworksTextCaptureListener: NSObject, TextCaptureListener {
    private let emitter: Emitter

    public init(emitter: Emitter) {
        self.emitter = emitter
    }

    private var isEnabled = AtomicBool()
    private let textCapturedEvent = EventWithResult<Bool>(event: Event(.didCaptureText))

    public func enable() {
        if isEnabled.value { return }
        isEnabled.value = true
    }

    public func disable() {
        guard isEnabled.value else { return }
        isEnabled.value = false
    }

    public func finishDidCaptureText(enabled: Bool) {
        textCapturedEvent.unlock(value: enabled)
    }

    public func textCapture(_ textCapture: TextCapture,
                            didCaptureIn session: TextCaptureSession,
                            frameData: FrameData) {
        guard isEnabled.value, emitter.hasListener(for: .didCaptureText) else { return }
        defer { LastFrameData.shared.frameData = nil }
        LastFrameData.shared.frameData = frameData
        let enabled = textCapturedEvent.emit(on: emitter,
                                             payload: ["session": session.jsonString]) ?? true
        textCapture.isEnabled = enabled
    }
}
