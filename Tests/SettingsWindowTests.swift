import AppKit
import SwiftUI

@main
struct SettingsWindowTests {
    @MainActor
    static func main() {
        NSApplication.shared.setActivationPolicy(.prohibited)
        let domain = "com.uito.Zime.settings-tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        let settings = TimerSettings(defaults: defaults)
        precondition(settings.colorHex == TimerPalette.all[0].hex, "Default color must be the leftmost blue")
        precondition(settings.autoContinue && settings.soundEnabled && !settings.alwaysOnTop,
                     "Default switches must be on/on/off")
        precondition(!settings.showRemainingTime, "Remaining time is hidden by default")
        settings.colorHex = TimerPalette.all[1].hex
        settings.autoContinue = false
        settings.soundEnabled = false
        settings.alwaysOnTop = true
        settings.showRemainingTime = true
        let reloaded = TimerSettings(defaults: defaults)
        precondition(reloaded.colorHex == TimerPalette.all[1].hex, "Preserve saved colors")
        precondition(!reloaded.autoContinue && !reloaded.soundEnabled && reloaded.alwaysOnTop,
                     "Preserve saved switches")
        precondition(reloaded.showRemainingTime, "Preserve the remaining-time toggle")
        print("PASS: defaults and saved settings")

        let window = NSWindow(contentRect: NSRect(x: 50, y: 50, width: 260, height: 300),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        let host = TimerWindowBridge.WindowHostView()
        host.settings = settings
        window.contentView = host
        window.collectionBehavior.insert(.fullScreenPrimary)
        host.apply(request: settings.resizeRequest, floating: true)
        precondition(window.level == .floating, "Floating level stays enabled")
        precondition(window.collectionBehavior.contains(.managed), "Floating windows participate in Mission Control")
        precondition(!window.collectionBehavior.contains(.transient), "Mission Control must not hide the timer")
        precondition(!window.collectionBehavior.contains(.stationary), "Timer participates in the window overview")
        precondition(window.collectionBehavior.contains(.fullScreenPrimary), "Preserve unrelated window flags")
        host.apply(request: settings.resizeRequest, floating: false)
        precondition(window.level == .normal && window.collectionBehavior.contains(.managed),
                     "Disabling floating restores normal level and keeps Mission Control")
        print("PASS: floating window and Mission Control configuration")

        window.setContentSize(CGSize(width: 287, height: 333))
        precondition(settings.windowWidth == 287 && settings.windowHeight == 333,
                     "Resizing the timer updates the settings fields")
        let resizedSettings = TimerSettings(defaults: defaults)
        precondition(resizedSettings.windowWidth == 287 && resizedSettings.windowHeight == 333,
                     "Manually resized dimensions persist across launches")
        settings.applySize(WindowPreset.compact.size)
        host.apply(request: settings.resizeRequest, floating: false)
        precondition(window.contentRect(forFrameRect: window.frame).size == WindowPreset.compact.size,
                     "Preset resizing still works after manual resize")
        precondition(settings.windowWidth == 200 && settings.windowHeight == 240,
                     "Programmatic resize does not overwrite requested dimensions mid-update")
        let unrelatedWindow = NSWindow(contentRect: NSRect(x: 50, y: 50, width: 400, height: 400),
                                       styleMask: [.titled], backing: .buffered, defer: false)
        unrelatedWindow.setContentSize(CGSize(width: 600, height: 500))
        precondition(settings.windowWidth == 200 && settings.windowHeight == 240,
                     "Other windows cannot overwrite the timer's dimensions")
        print("PASS: manual resize synchronization, persistence, and preset resizing")

        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        precondition(TimerWindowReference.settingsArrowEdge(
            windowFrame: CGRect(x: 20, y: 100, width: 260, height: 300), visibleFrame: screen) == .leading,
            "Near the left screen edge, settings open to the right")
        precondition(TimerWindowReference.settingsArrowEdge(
            windowFrame: CGRect(x: 1160, y: 100, width: 260, height: 300), visibleFrame: screen) == .trailing,
            "Near the right screen edge, settings open to the left")
        let secondScreen = CGRect(x: -1440, y: 0, width: 1440, height: 900)
        precondition(TimerWindowReference.settingsArrowEdge(
            windowFrame: CGRect(x: -280, y: 100, width: 260, height: 300), visibleFrame: secondScreen) == .trailing,
            "Use the current display's bounds, including negative coordinates")
        precondition(TimerWindowReference.settingsArrowEdge(
            windowFrame: CGRect(x: 410, y: 100, width: 260, height: 300),
            visibleFrame: CGRect(x: 0, y: 0, width: 800, height: 600)) == .trailing,
            "When neither side fits, prefer the side with more space")
        print("PASS: adaptive settings placement at screen edges and on multiple displays")
    }
}
