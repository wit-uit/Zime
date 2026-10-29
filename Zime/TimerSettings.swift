import SwiftUI
import Observation

struct TimerPalette: Identifiable {
    let id: String
    let name: String
    let hex: String

    static let all: [TimerPalette] = [
        .init(id: "marine", name: "マリン", hex: "7199A2"),
        .init(id: "cocoa", name: "ココア", hex: "B79B85"),
        .init(id: "cherry", name: "チェリー", hex: "C86B69"),
        .init(id: "lilac", name: "ライラック", hex: "A79BBC"),
        .init(id: "sage", name: "セージ", hex: "8EAA92"),
        .init(id: "midnight", name: "ミッドナイト", hex: "52657F")
    ]
}

enum WindowPreset: String, CaseIterable, Identifiable {
    case compact, standard, large
    var id: String { rawValue }
    var title: String {
        switch self {
        case .compact: "小"
        case .standard: "中"
        case .large: "大"
        }
    }
    var size: CGSize {
        switch self {
        case .compact: CGSize(width: 200, height: 240)
        case .standard: CGSize(width: 260, height: 300)
        case .large: CGSize(width: 320, height: 360)
        }
    }
}

@MainActor @Observable
final class TimerSettings {
    private let defaults: UserDefaults
    var focusMinutes: Int { didSet { defaults.set(focusMinutes, forKey: "focusMinutes") } }
    var restMinutes: Int { didSet { defaults.set(restMinutes, forKey: "restMinutes") } }
    var colorHex: String { didSet { defaults.set(colorHex, forKey: "colorHex") } }
    var autoContinue: Bool { didSet { defaults.set(autoContinue, forKey: "autoContinue") } }
    var soundEnabled: Bool { didSet { defaults.set(soundEnabled, forKey: "soundEnabled") } }
    var alwaysOnTop: Bool { didSet { defaults.set(alwaysOnTop, forKey: "alwaysOnTop") } }
    var windowWidth: Double { didSet { defaults.set(windowWidth, forKey: "windowWidth") } }
    var windowHeight: Double { didSet { defaults.set(windowHeight, forKey: "windowHeight") } }
    var resizeRequest = 0

    var color: Color { Color(timerHex: colorHex) }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            "focusMinutes": 25, "restMinutes": 5,
            "autoContinue": true, "soundEnabled": true,
            "alwaysOnTop": false,
            "windowWidth": 260.0, "windowHeight": 300.0
        ])
        focusMinutes = min(180, max(1, defaults.integer(forKey: "focusMinutes")))
        restMinutes = min(60, max(1, defaults.integer(forKey: "restMinutes")))
        colorHex = defaults.string(forKey: "colorHex") ?? defaults.string(forKey: "focusHex") ?? "7199A2"
        autoContinue = defaults.bool(forKey: "autoContinue")
        soundEnabled = defaults.bool(forKey: "soundEnabled")
        alwaysOnTop = defaults.bool(forKey: "alwaysOnTop")
        windowWidth = min(1200, max(180, defaults.double(forKey: "windowWidth")))
        windowHeight = min(1200, max(220, defaults.double(forKey: "windowHeight")))
        // Apply the compact layout once to existing installations, preserving
        // subsequent custom sizes and all other preferences.
        if !defaults.bool(forKey: "compactLayoutV2") {
            windowWidth = 260
            windowHeight = 300
            defaults.set(260.0, forKey: "windowWidth")
            defaults.set(300.0, forKey: "windowHeight")
            defaults.set(true, forKey: "compactLayoutV2")
        }
    }

    func applySize(_ size: CGSize? = nil) {
        if let size {
            windowWidth = size.width
            windowHeight = size.height
        }
        resizeRequest += 1
    }
}

extension Color {
    init(timerHex: String) {
        let value = UInt64(timerHex, radix: 16) ?? 0x7199A2
        self.init(.sRGB, red: Double((value >> 16) & 255) / 255,
                  green: Double((value >> 8) & 255) / 255,
                  blue: Double(value & 255) / 255, opacity: 1)
    }

    var timerHex: String {
        let rgb = NSColor(self).usingColorSpace(.sRGB) ?? .gray
        return String(format: "%02X%02X%02X", Int((rgb.redComponent * 255).rounded()),
                      Int((rgb.greenComponent * 255).rounded()), Int((rgb.blueComponent * 255).rounded()))
    }
}

enum ZimeStyle {
    static let canvas = Color(timerHex: "F7F6F2")
    static let ink = Color(timerHex: "3F4542")
    static let secondary = Color(timerHex: "858981")
    static let line = Color(timerHex: "E7E7E0")
}
