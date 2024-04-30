/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditTextCapture

public class TextCaptureModule: NSObject, FrameworkModule {

    private let textCaptureListener: FrameworksTextCaptureListener
    private let textCaptureDeserializer: TextCaptureDeserializer

    private var context: DataCaptureContext?

    private var modeEnabled = true

    private var dataCaptureView: DataCaptureView?

    private var textCaptureOverlay: TextCaptureOverlay?

    public init(textCaptureListener: FrameworksTextCaptureListener,
                deserializer: TextCaptureDeserializer = TextCaptureDeserializer()) {
        self.textCaptureListener = textCaptureListener
        self.textCaptureDeserializer = deserializer
    }

    private var textCapture: TextCapture? {
        willSet {
            textCapture?.removeListener(textCaptureListener)
        }
        didSet {
            textCapture?.addListener(textCaptureListener)
        }
    }

    public let defaults: DefaultsEncodable = TextCaptureDefaults.shared

    public func addListener() {
        textCaptureListener.enable()
    }

    public func removeListener() {
        textCaptureListener.disable()
    }

    public func finishDidCaptureText(enabled: Bool) {
        textCaptureListener.finishDidCaptureText(enabled: enabled)
    }

    public func didStart() {
        textCaptureDeserializer.delegate = self
        DeserializationLifeCycleDispatcher.shared.attach(observer: self)
        Deserializers.Factory.add(textCaptureDeserializer)
    }

    public func didStop() {
        textCaptureDeserializer.delegate = nil
        DeserializationLifeCycleDispatcher.shared.detach(observer: self)
        Deserializers.Factory.remove(textCaptureDeserializer)
        textCaptureListener.disable()
    }

    public func setModeEnabled(enabled: Bool) {
        modeEnabled = enabled
        textCapture?.isEnabled = enabled
    }

    public func isModeEnabled() -> Bool {
        return textCapture?.isEnabled == true
    }

    public func updateModeFromJson(modeJson: String, result: FrameworksResult) {
        guard let mode = textCapture else {
            result.success(result: nil)
            return
        }
        do {
            try textCaptureDeserializer.updateMode(mode, fromJSONString: modeJson)
            result.success(result: nil)
        } catch {
            result.reject(error: error)
        }
    }

    public func applyModeSettings(modeSettingsJson: String, result: FrameworksResult) {
        guard let mode = textCapture else {
            result.success(result: nil)
            return
        }
        do {
            let settings = try textCaptureDeserializer.settings(fromJSONString: modeSettingsJson)
            mode.apply(settings)
            result.success(result: nil)
        } catch {
            result.reject(error: error)
        }
    }

    public func updateOverlay(overlayJson: String, result: FrameworksResult) {
        guard let overlay = self.textCaptureOverlay else {
            result.success(result: nil)
            return
        }
                
        do {
            try textCaptureDeserializer.update(overlay, fromJSONString: overlayJson)
            result.success(result: nil)
        } catch {
            result.reject(error: error)
        }
    }
}

extension TextCaptureModule: TextCaptureDeserializerDelegate {
    public func textCaptureDeserializer(_ deserializer: TextCaptureDeserializer,
                                        didStartDeserializingMode mode: TextCapture,
                                        from JSONValue: JSONValue) {}

    public func textCaptureDeserializer(_ deserializer: TextCaptureDeserializer,
                                        didFinishDeserializingMode mode: TextCapture,
                                        from JSONValue: JSONValue) {
        if JSONValue.containsKey("enabled") {
            mode.isEnabled = JSONValue.bool(forKey: "enabled")
        } else {
            mode.isEnabled = modeEnabled
        }
        textCapture = mode
    }

    public func textCaptureDeserializer(_ deserializer: TextCaptureDeserializer,
                                        didStartDeserializingSettings settings: TextCaptureSettings,
                                        from JSONValue: JSONValue) {}

    public func textCaptureDeserializer(_ deserializer: TextCaptureDeserializer,
                                        didFinishDeserializingSettings settings: TextCaptureSettings,
                                        from JSONValue: JSONValue) {}

    public func textCaptureDeserializer(_ deserializer: TextCaptureDeserializer,
                                        didStartDeserializingOverlay overlay: TextCaptureOverlay,
                                        from JSONValue: JSONValue) {}

    public func textCaptureDeserializer(_ deserializer: TextCaptureDeserializer,
                                        didFinishDeserializingOverlay overlay: TextCaptureOverlay,
                                        from JSONValue: JSONValue) {
        self.textCaptureOverlay = overlay
    }
}

extension TextCaptureModule: DeserializationLifeCycleObserver {
    public func dataCaptureContext(deserialized context: DataCaptureContext?) {
        self.context = context
    }

    public func didDisposeDataCaptureContext() {
        self.context = nil
        self.dataCaptureView = nil

    }

    public func dataCaptureView(deserialized view: DataCaptureView?) {
        self.dataCaptureView = view
        
        
        guard let dcView = view, let overlay = textCaptureOverlay else {
            return
        }
        
        dcView.addOverlay(overlay)
    }

    public func dataCaptureContext(addMode modeJson: String) throws {
        if JSONValue(string: modeJson).string(forKey: "type") != "textCapture" {
            return
        }

        guard let dcContext = self.context else {
            return
        }

        let mode = try textCaptureDeserializer.mode(fromJSONString: modeJson, with: dcContext)
        dcContext.addMode(mode)
    }

    public func dataCaptureContext(removeMode modeJson: String) {
        if  JSONValue(string: modeJson).string(forKey: "type") != "textCapture" {
            return
        }

        guard let dcContext = self.context else {
            return
        }

        guard let mode = self.textCapture else {
            return
        }
        dcContext.removeMode(mode)
        self.textCapture = nil
    }

    public func dataCaptureContextAllModeRemoved() {
        self.textCapture = nil
        removeCurrentOverlay()
    }

    public func dataCaptureView(addOverlay overlayJson: String) throws {
        if  JSONValue(string: overlayJson).string(forKey: "type") != "textCapture" {
            return
        }

        guard let mode = self.textCapture else {
            return
        }

        try dispatchMainSync {
            let overlay = try textCaptureDeserializer.overlay(fromJSONString: overlayJson, withMode: mode)
            self.dataCaptureView?.addOverlay(overlay)
        }
    }

    public func dataCaptureView(removeOverlay overlayJson: String) {
        if  JSONValue(string: overlayJson).string(forKey: "type") != "textCapture" {
            return
        }

        removeCurrentOverlay()
    }

    public func dataCaptureViewRemoveAllOverlays() {
        removeCurrentOverlay()
    }

    private func removeCurrentOverlay() {
        guard let overlay = self.textCaptureOverlay else {
            return
        }

        dispatchMainSync {
            self.dataCaptureView?.removeOverlay(overlay)
        }
        self.textCaptureOverlay = nil
    }
}
