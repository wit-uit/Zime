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
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 260, height: 300)
        .commands {
            CommandGroup(replacing: .appSettings) {
                OpenSettingsButton()
            }
        }
    }
}

private struct OpenSettingsButton: View {
    @FocusedValue(\.timerSettingsPresentation) private var presentation
    var body: some View {
        Button("設定…") { presentation?.wrappedValue = true }
            .keyboardShortcut(",", modifiers: .command)
            .disabled(presentation == nil)
    }
}
