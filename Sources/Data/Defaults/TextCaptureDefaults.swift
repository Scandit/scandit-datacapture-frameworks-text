/*
 * This file is part of the Scandit Data Capture SDK
 *
 * Copyright (C) 2023- Scandit AG. All rights reserved.
 */

import ScanditFrameworksCore
import ScanditTextCapture

@available(*, deprecated)
struct TextCaptureDefaults: DefaultsEncodable {
    private let recommendedCameraSettings: CameraSettingsDefaults
    private let textCaptureOverlayDefaults: TextCaptureOverlayDefaults
    private let textCaptureSettingsDefaults: TextCaptureSettingsDefaults

    init(recommendedCameraSettings: CameraSettingsDefaults,
         textCaptureOverlayDefaults: TextCaptureOverlayDefaults,
         textCaptureSettingsDefaults: TextCaptureSettingsDefaults) {
        self.recommendedCameraSettings = recommendedCameraSettings
        self.textCaptureOverlayDefaults = textCaptureOverlayDefaults
        self.textCaptureSettingsDefaults = textCaptureSettingsDefaults
    }

    public static var shared: TextCaptureDefaults = {
        .init(recommendedCameraSettings:  CameraSettingsDefaults(
                cameraSettings: TextCapture.recommendedCameraSettings),
              textCaptureOverlayDefaults: TextCaptureOverlayDefaults(
                defaultBrush: EncodableBrush(brush: TextCaptureOverlay.defaultBrush)
              ),
              textCaptureSettingsDefaults: TextCaptureSettingsDefaults(
                settings: try! TextCaptureSettings(jsonString: "{}")
              )
        )
    }()

    func toEncodable() -> [String: Any?] {
        [
            "RecommendedCameraSettings": recommendedCameraSettings.toEncodable(),
            "TextCaptureOverlay": textCaptureOverlayDefaults.toEncodable(),
            "TextCaptureSettings": textCaptureSettingsDefaults.toEncodable()
        ]
    }
}

struct TextCaptureOverlayDefaults: DefaultsEncodable {
    let defaultBrush: EncodableBrush

    func toEncodable() -> [String: Any?] {
        [
            "Brush": defaultBrush.toEncodable()
        ]
    }
}

@available(*, deprecated)
struct TextCaptureSettingsDefaults: DefaultsEncodable {
    let settings: TextCaptureSettings

    func toEncodable() -> [String: Any?] {
        [
            "recognitionDirection": settings.recognitionDirection.jsonString,
            "duplicateFilter": Int(settings.duplicateFilter * 1000)
        ]
    }
}
