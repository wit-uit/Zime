import SwiftUI
import Combine

struct ContentView: View {
    @Environment(TimerSettings.self) private var settings
    @Environment(TimerEngine.self) private var timer
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scenePhase
    private let ticks = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    private var accent: Color { timer.phase == .focus ? settings.focusColor : settings.restColor }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 530 || geometry.size.width < 390
            let diameter = max(100, min(geometry.size.width - (compact ? 52 : 88),
                                        geometry.size.height - (compact ? 294 : 328), 440))
            VStack(spacing: 0) {
                header(compact: compact)
                Spacer(minLength: 10)
                phasePicker
                Spacer(minLength: 16)
                VisualDial(progress: timer.progress, color: accent, isRunning: timer.isRunning)
                    .frame(width: diameter, height: diameter)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(timer.phase.title)タイマー")
                    .accessibilityValue("残り\(timer.timeLabel)、\(timer.isRunning ? "計測中" : "停止中")")
                Spacer(minLength: 14)
                VStack(spacing: 7) {
                    if settings.showTime {
                        Text(timer.timeLabel)
                            .font(.system(size: compact ? 23 : 28, weight: .light, design: .rounded).monospacedDigit())
                            .contentTransition(.numericText(countsDown: true))
                    } else {
                        Text(statusTitle)
                            .font(.system(size: compact ? 14 : 16, weight: .medium))
                    }
                    Text(timer.phase == .focus ? "ひとつのことに、心を向ける。" : "ひと息ついて、またここから。")
                        .font(.system(size: 11))
                        .foregroundStyle(ZimeStyle.secondary)
                }
                .foregroundStyle(ZimeStyle.ink)
                .frame(height: compact ? 44 : 52)
                Spacer(minLength: 14)
                controls(compact: compact)
                Spacer(minLength: compact ? 16 : 24)
                footer
            }
            .padding(.horizontal, compact ? 23 : 32)
            .padding(.top, compact ? 10 : 17)
            .padding(.bottom, compact ? 16 : 23)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ZimeStyle.canvas)
            .background(TimerWindowBridge(settings: settings))
        }
        .frame(minWidth: 320, minHeight: 440)
        .preferredColorScheme(.light)
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

    private var statusTitle: String {
        if timer.isRunning { return timer.phase == .focus ? "集中の時間" : "休憩の時間" }
        return timer.isPristine ? "自分のペースで、はじめよう" : "少しだけ、一時停止"
    }

    private func header(compact: Bool) -> some View {
        HStack(alignment: .center) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("zime")
                    .font(.system(size: compact ? 23 : 27, weight: .medium, design: .serif))
                    .tracking(1)
                if !compact {
                    Text("余白を、つくる。")
                        .font(.system(size: 10))
                        .foregroundStyle(ZimeStyle.secondary)
                }
            }
            Spacer()
            Button { openWindow(id: "settings") } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .regular))
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.65), in: Circle())
                    .overlay(Circle().strokeBorder(ZimeStyle.line, lineWidth: 0.8))
            }
            .buttonStyle(.plain)
            .help("設定（⌘,）")
            .accessibilityLabel("設定を開く")
        }
        .foregroundStyle(ZimeStyle.ink)
    }

    private var phasePicker: some View {
        HStack(spacing: 3) {
            ForEach([TimerPhase.focus, .rest], id: \.self) { phase in
                Button { timer.select(phase) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: phase == .focus ? "circle.lefthalf.filled" : "leaf")
                            .font(.system(size: 11))
                        Text(phase.title).font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(timer.phase == phase ? ZimeStyle.ink : ZimeStyle.secondary)
                    .frame(width: 83, height: 31)
                    .background {
                        if timer.phase == phase {
                            Capsule().fill(.white)
                                .shadow(color: .black.opacity(0.04), radius: 3, y: 1)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(timer.phase == phase ? .isSelected : [])
                .help("\(phase.title)に切り替え（現在のタイマーをリセット）")
            }
        }
        .padding(4)
        .background(Color(timerHex: "ECEDE7"), in: Capsule())
    }

    private func controls(compact: Bool) -> some View {
        HStack(spacing: compact ? 18 : 23) {
            Button { timer.reset() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .foregroundStyle(ZimeStyle.secondary)
            .help("現在のタイマーをリセット（⌘R）")
            .accessibilityLabel("リセット")
            .keyboardShortcut("r", modifiers: .command)
            Button { timer.toggle() } label: {
                HStack(spacing: 9) {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(timer.isRunning ? "一時停止" : timer.isPristine ? "はじめる" : "再開する")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.white)
                .frame(width: compact ? 136 : 152, height: compact ? 44 : 48)
                .background(ZimeStyle.ink, in: Capsule())
            }
            .buttonStyle(SoftPressStyle())
            .keyboardShortcut(.space, modifiers: [])
            .help("開始・一時停止（スペース）")
            Button { timer.skip() } label: {
                Image(systemName: "forward.end")
                    .font(.system(size: 16))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .foregroundStyle(ZimeStyle.secondary)
            .help("\(timer.phase.next.title)に進む（⌘→）")
            .accessibilityLabel("\(timer.phase.next.title)に進む")
            .keyboardShortcut(.rightArrow, modifiers: .command)
        }
    }

    private var footer: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(settings.focusColor).frame(width: 5, height: 5)
                Text("勉強 \(settings.focusMinutes)分")
                Text("/").foregroundStyle(ZimeStyle.line)
                Circle().fill(settings.restColor).frame(width: 5, height: 5)
                Text("休憩 \(settings.restMinutes)分")
            }
            Spacer(minLength: 8)
            Text("\(timer.completedFocusSessions) セッション")
                .monospacedDigit()
                .help("アプリ起動後に完了した勉強の回数")
        }
        .font(.system(size: 10))
        .foregroundStyle(ZimeStyle.secondary)
        .padding(.top, 14)
        .overlay(alignment: .top) { Rectangle().fill(ZimeStyle.line).frame(height: 1) }
    }

    private func configureTimer() {
        timer.configure(focusMinutes: settings.focusMinutes, restMinutes: settings.restMinutes)
    }
}

struct VisualDial: View {
    let progress: Double
    let color: Color
    let isRunning: Bool

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.white, Color(timerHex: "E5E3DC")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Color(timerHex: "A9A695").opacity(0.20), radius: side * 0.05, x: 0, y: side * 0.04)
                    .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 1))
                Circle()
                    .fill(Color(timerHex: "F0EFE9"))
                    .overlay(Circle().strokeBorder(.black.opacity(0.055), lineWidth: 1.5))
                    .padding(side * 0.053)
                RemainingSector(progress: progress)
                    .fill(color.gradient)
                    .padding(side * 0.062)
                Rectangle()
                    .fill(Color(timerHex: "F8F7F2"))
                    .frame(width: max(1.5, side * 0.006), height: side * 0.438)
                    .offset(y: -side * 0.219)
                    .rotationEffect(.degrees((1 - progress) * 360))
                Circle()
                    .fill(Color(timerHex: "F6F5EF"))
                    .frame(width: side * 0.065, height: side * 0.065)
                    .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                Circle()
                    .fill(isRunning ? color : Color(timerHex: "CCCFC5"))
                    .frame(width: side * 0.018, height: side * 0.018)
            }
        }
    }
}

struct RemainingSector: Shape {
    var progress: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        if progress >= 0.999999 {
            path.addEllipse(in: rect)
        } else if progress > 0 {
            path.move(to: center)
            path.addArc(center: center, radius: radius,
                        startAngle: .degrees(-90 + (1 - progress) * 360),
                        endAngle: .degrees(270), clockwise: false)
            path.closeSubpath()
        }
        return path
    }
}

struct SoftPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
