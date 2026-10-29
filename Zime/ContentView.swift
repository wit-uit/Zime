import SwiftUI
import Combine

struct ContentView: View {
    @Environment(TimerSettings.self) private var settings
    @Environment(TimerEngine.self) private var timer
    @Environment(\.scenePhase) private var scenePhase
    @State private var showsSettings = false
    @State private var windowReference = TimerWindowReference()
    private let ticks = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            let diameter = max(100, min(geometry.size.width - 32,
                                        geometry.size.height - (settings.showRemainingTime ? 120 : 100)))
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    settingsButton
                }
                .frame(height: 24)
                Spacer(minLength: 0)
                VStack(spacing: 5) {
                    if settings.showRemainingTime {
                        Text(timer.timeLabel)
                            .font(.system(size: 10, weight: .regular, design: .rounded).monospacedDigit())
                            .foregroundStyle(ZimeStyle.secondary)
                            .accessibilityLabel("残り\(timer.timeLabel)")
                    }
                    TimelineView(.animation(minimumInterval: 1.0 / 60,
                                            paused: !timer.isPreparing || !timer.isRunning)) { context in
                        VisualDial(fraction: timer.dialFraction(at: context.date),
                                   color: settings.color, isRunning: timer.isRunning)
                    }
                    .frame(width: diameter, height: diameter)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(timer.phase.title)タイマー")
                    .accessibilityValue("残り\(timer.timeLabel)、\(timer.isRunning ? "計測中" : "停止中")")
                }
                Spacer(minLength: 0)
                controls.padding(.top, 12)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ZimeStyle.canvas)
            .background(TimerWindowBridge(settings: settings, windowReference: windowReference))
        }
        .frame(minWidth: 180, minHeight: 220)
        .preferredColorScheme(.light)
        .focusedSceneValue(\.timerSettingsPresentation, $showsSettings)
        .onReceive(ticks) { timer.tick(now: $0) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { timer.tick() }
        }
        .onChange(of: settings.focusMinutes) { _, _ in configureTimer() }
        .onChange(of: settings.restMinutes) { _, _ in configureTimer() }
        .onChange(of: settings.autoContinue) { _, value in timer.automaticallyContinue = value }
        .onChange(of: timer.completedPhases) { _, _ in
            if settings.soundEnabled { NSSound(named: "Glass")?.play() }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button { timer.reset() } label: {
                Image(systemName: "arrow.counterclockwise").frame(width: 24, height: 30)
            }
            .help("リセット（⌘R）")
            .accessibilityLabel("リセット")
            .keyboardShortcut("r", modifiers: .command)

            Button { timer.toggle() } label: {
                Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(ZimeStyle.ink, in: Circle())
            }
            .buttonStyle(SoftPressStyle())
            .keyboardShortcut(.space, modifiers: [])
            .accessibilityLabel(timer.isRunning ? "一時停止" : "開始")
            .help("開始・一時停止（スペース）")

            Button { timer.skip() } label: {
                Image(systemName: "forward.end").frame(width: 24, height: 30)
            }
            .help("\(timer.phase.next.title)へ（⌘→）")
            .accessibilityLabel("\(timer.phase.next.title)に進む")
            .keyboardShortcut(.rightArrow, modifiers: .command)

        }
        .font(.system(size: 13))
        .foregroundStyle(ZimeStyle.secondary)
        .buttonStyle(.plain)
    }

    private var settingsButton: some View {
        Button { showsSettings.toggle() } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 13))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .foregroundStyle(ZimeStyle.secondary)
        .help("設定（⌘,）")
        .accessibilityLabel("設定を開く")
        .popover(isPresented: $showsSettings, attachmentAnchor: .rect(.bounds),
                 arrowEdge: windowReference.settingsArrowEdge) {
            SettingsView()
                .environment(settings)
        }
    }

    private func configureTimer() {
        timer.configure(focusMinutes: settings.focusMinutes, restMinutes: settings.restMinutes)
    }
}

private struct TimerSettingsPresentationKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var timerSettingsPresentation: Binding<Bool>? {
        get { self[TimerSettingsPresentationKey.self] }
        set { self[TimerSettingsPresentationKey.self] = newValue }
    }
}

struct VisualDial: View {
    let fraction: Double
    let color: Color
    let isRunning: Bool

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.white, Color(timerHex: "E5E3DC")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Color(timerHex: "A9A695").opacity(0.18), radius: side * 0.045, y: side * 0.03)
                    .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1))
                Circle()
                    .fill(Color(timerHex: "F0EFE9"))
                    .overlay(Circle().strokeBorder(.black.opacity(0.045), lineWidth: 1))
                    .padding(side * 0.053)
                DialSector(fraction: fraction)
                    .fill(color.gradient)
                    .padding(side * 0.062)
                Rectangle()
                    .fill(Color(timerHex: "F8F7F2"))
                    .frame(width: max(1.2, side * 0.006), height: side * 0.438)
                    .offset(y: -side * 0.219)
                    .rotationEffect(.degrees(-fraction * 360))
                Circle()
                    .fill(Color(timerHex: "F6F5EF"))
                    .frame(width: side * 0.065, height: side * 0.065)
                    .shadow(color: .black.opacity(0.1), radius: 1.5, y: 1)
                Circle()
                    .fill(isRunning ? color : Color(timerHex: "CCCFC5"))
                    .frame(width: side * 0.018, height: side * 0.018)
            }
        }
    }
}

struct DialSector: Shape {
    var fraction: Double

    func path(in rect: CGRect) -> Path {
        let fraction = min(1, max(0, fraction))
        var path = Path()
        if fraction >= 1 {
            path.addEllipse(in: rect)
        } else if fraction > 0 {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            path.move(to: center)
            path.addArc(center: center, radius: min(rect.width, rect.height) / 2,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 - fraction * 360),
                        clockwise: true)
            path.closeSubpath()
        }
        return path
    }
}

struct SoftPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
