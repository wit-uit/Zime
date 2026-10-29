import SwiftUI

struct SettingsView: View {
    @Environment(TimerSettings.self) private var settings
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        @Bindable var settings = settings
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("あなたのペースに。")
                        .font(.system(size: 23, weight: .medium, design: .serif))
                    Text("心地よく集中できる、自分だけのタイマー。")
                        .font(.system(size: 11))
                        .foregroundStyle(ZimeStyle.secondary)
                }

                section("時間", symbol: "clock") {
                    durationRow("勉強", value: $settings.focusMinutes, range: 1...180, color: settings.focusColor)
                    Divider().padding(.vertical, 5)
                    durationRow("休憩", value: $settings.restMinutes, range: 1...60, color: settings.restColor)
                    HStack(spacing: 6) {
                        timePreset("25 / 5", focus: 25, rest: 5)
                        timePreset("50 / 10", focus: 50, rest: 10)
                        timePreset("90 / 15", focus: 90, rest: 15)
                        Spacer()
                    }
                    .padding(.top, 9)
                    Text("計測途中の時間は維持し、次の回から反映します。")
                        .font(.system(size: 10))
                        .foregroundStyle(ZimeStyle.secondary)
                        .padding(.top, 7)
                }

                section("色", symbol: "paintpalette") {
                    HStack(spacing: 0) {
                        ForEach(TimerPalette.all) { palette in
                            Button { settings.focusHex = palette.hex } label: {
                                Circle().fill(Color(timerHex: palette.hex))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if settings.focusHex == palette.hex {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding(4)
                                    .overlay(Circle().strokeBorder(settings.focusHex == palette.hex ? Color(timerHex: palette.hex) : .clear, lineWidth: 1))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("勉強の色：\(palette.name)")
                            .accessibilityAddTraits(settings.focusHex == palette.hex ? .isSelected : [])
                            .help(palette.name)
                        }
                    }
                    .padding(.bottom, 10)
                    ColorPicker("勉強の色", selection: colorBinding(focus: true), supportsOpacity: false)
                    ColorPicker("休憩の色", selection: colorBinding(focus: false), supportsOpacity: false)
                        .padding(.top, 5)
                }

                section("ウィンドウ", symbol: "macwindow") {
                    HStack(spacing: 7) {
                        ForEach(WindowPreset.allCases) { preset in
                            Button { settings.applySize(preset.size) } label: {
                                VStack(spacing: 4) {
                                    Text(preset.title).font(.system(size: 12, weight: .medium))
                                    Text("\(Int(preset.size.width)) × \(Int(preset.size.height))")
                                        .font(.system(size: 9).monospacedDigit())
                                        .foregroundStyle(ZimeStyle.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(ZimeStyle.canvas, in: RoundedRectangle(cornerRadius: 9))
                                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(ZimeStyle.line))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    HStack(spacing: 8) {
                        Text("幅")
                        TextField("幅", value: $settings.windowWidth, format: .number.precision(.fractionLength(0)))
                            .frame(width: 51)
                            .accessibilityLabel("ウィンドウの幅")
                        Text("高さ")
                        TextField("高さ", value: $settings.windowHeight, format: .number.precision(.fractionLength(0)))
                            .frame(width: 51)
                            .accessibilityLabel("ウィンドウの高さ")
                        Spacer(minLength: 0)
                        Button("適用") {
                            settings.windowWidth = min(1200, max(320, settings.windowWidth))
                            settings.windowHeight = min(1200, max(440, settings.windowHeight))
                            settings.applySize()
                        }
                        .buttonStyle(.bordered)
                    }
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11))
                    .padding(.top, 12)
                    Toggle("最前面に表示", isOn: $settings.alwaysOnTop)
                        .padding(.top, 11)
                }

                section("動作", symbol: "switch.2") {
                    Toggle("勉強と休憩を自動で繰り返す", isOn: $settings.autoContinue)
                    Toggle("切り替わりを音で知らせる", isOn: $settings.soundEnabled)
                        .padding(.top, 8)
                    Toggle("残り時間を数字でも表示", isOn: $settings.showTime)
                        .padding(.top, 8)
                }

                HStack {
                    Text("変更は自動で保存されます。")
                        .font(.system(size: 10))
                        .foregroundStyle(ZimeStyle.secondary)
                    Spacer()
                    Button("完了") { dismissWindow(id: "settings") }
                        .buttonStyle(.borderedProminent)
                        .tint(ZimeStyle.ink)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(26)
        }
        .background(ZimeStyle.canvas)
        .foregroundStyle(ZimeStyle.ink)
        .font(.system(size: 12))
        .toggleStyle(.switch)
        .controlSize(.small)
        .tint(settings.focusColor)
        .frame(minWidth: 400, idealWidth: 430, maxWidth: 500, minHeight: 480, idealHeight: 700)
        .preferredColorScheme(.light)
    }

    private func section<Content: View>(_ title: String, symbol: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            Label(title, systemImage: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ZimeStyle.secondary)
            VStack(alignment: .leading, spacing: 3, content: content)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(ZimeStyle.line.opacity(0.8)))
        }
    }

    private func durationRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title)
            Spacer()
            TextField(title, value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 48)
                .accessibilityLabel("\(title)時間（分）")
                .onChange(of: value.wrappedValue) { _, newValue in
                    value.wrappedValue = min(range.upperBound, max(range.lowerBound, newValue))
                }
            Text("分").foregroundStyle(ZimeStyle.secondary)
            Stepper(title, value: value, in: range).labelsHidden()
                .accessibilityLabel("\(title)時間を調整")
        }
    }

    private func timePreset(_ title: String, focus: Int, rest: Int) -> some View {
        Button(title) {
            settings.focusMinutes = focus
            settings.restMinutes = rest
        }
        .buttonStyle(.bordered)
        .font(.system(size: 10).monospacedDigit())
        .help("勉強\(focus)分・休憩\(rest)分")
    }

    private func colorBinding(focus: Bool) -> Binding<Color> {
        Binding(get: { focus ? settings.focusColor : settings.restColor }, set: { color in
            if focus { settings.focusHex = color.timerHex }
            else { settings.restHex = color.timerHex }
        })
    }
}
