import SwiftUI

@main
struct ZimeApp: App {
    @State private var settings: TimerSettings
    @State private var timer: TimerEngine

    init() {
        let settings = TimerSettings()
        let timer = TimerEngine(focusMinutes: settings.focusMinutes, restMinutes: settings.restMinutes)
        timer.automaticallyContinue = settings.autoContinue
        _settings = State(initialValue: settings)
        _timer = State(initialValue: timer)
    }

    var body: some Scene {
        Window("Zime", id: "timer") {
            ContentView()
                .environment(settings)
                .environment(timer)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 480, height: 640)
        .commands {
            CommandGroup(replacing: .appSettings) {
                OpenSettingsButton()
            }
        }

        Window("設定", id: "settings") {
            SettingsView()
                .environment(settings)
        }
        .defaultSize(width: 430, height: 700)
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.suppressed)
    }
}

private struct OpenSettingsButton: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("設定…") { openWindow(id: "settings") }
            .keyboardShortcut(",", modifiers: .command)
    }
}
