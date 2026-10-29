import SwiftUI

struct SettingsView: View {
    @Environment(TimerSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        VStack(spacing: 14) {
            VStack(spacing: 9) {
                durationRow("勉強", value: $settings.focusMinutes, range: 1...180)
                durationRow("休憩", value: $settings.restMinutes, range: 1...60)
            }
            .padding(12)
            .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 7) {
                Text("色").frame(width: 38, alignment: .leading)
                ForEach(TimerPalette.all) { palette in
                    Button { settings.colorHex = palette.hex } label: {
                        Circle().fill(Color(timerHex: palette.hex))
                            .frame(width: 21, height: 21)
                            .overlay {
                                if settings.colorHex == palette.hex {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold)).foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(palette.name)
                    .accessibilityAddTraits(settings.colorHex == palette.hex ? .isSelected : [])
                    .help(palette.name)
                }
                Spacer(minLength: 0)
                ColorPicker("カスタムカラー", selection: Binding(
                    get: { settings.color }, set: { settings.colorHex = $0.timerHex }
                ), supportsOpacity: false)
                .labelsHidden()
                .help("カスタムカラー")
            }

            HStack(spacing: 7) {
                Text("サイズ").frame(width: 38, alignment: .leading)
                HStack(spacing: 0) {
                    ForEach(WindowPreset.allCases) { preset in
                        Button { settings.applySize(preset.size) } label: {
                            Text(preset.title)
                                .frame(maxWidth: .infinity)
                                .frame(height: 26)
                                .background(isSelected(preset) ? .white : .clear, in: RoundedRectangle(cornerRadius: 5))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(preset.title)、\(Int(preset.size.width))×\(Int(preset.size.height))")
                        .accessibilityAddTraits(isSelected(preset) ? .isSelected : [])
                        .help("\(Int(preset.size.width)) × \(Int(preset.size.height))")
                    }
                }
                .padding(3)
                .background(ZimeStyle.line.opacity(0.65), in: RoundedRectangle(cornerRadius: 7))
            }

            HStack(spacing: 7) {
                Text("幅・高さ").frame(width: 48, alignment: .leading)
                TextField("幅", value: $settings.windowWidth, format: .number.precision(.fractionLength(0)))
                    .accessibilityLabel("幅")
                Text("×").foregroundStyle(ZimeStyle.secondary)
                TextField("高さ", value: $settings.windowHeight, format: .number.precision(.fractionLength(0)))
                    .accessibilityLabel("高さ")
                Button(action: applySize) {
                    Image(systemName: "checkmark").frame(width: 23, height: 18)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("サイズを適用")
                .help("適用")
            }
            .textFieldStyle(.roundedBorder)
            .onSubmit(applySize)

            Divider()
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading),
                                GridItem(.flexible(), alignment: .leading)], spacing: 8) {
                Toggle("自動切替", isOn: $settings.autoContinue)
                Toggle("終了音", isOn: $settings.soundEnabled)
                Toggle("最前面", isOn: $settings.alwaysOnTop)
                Toggle("残り時間", isOn: $settings.showRemainingTime)
            }
            .toggleStyle(.checkbox)
        }
        .padding(16)
        .frame(width: 304)
        .fixedSize(horizontal: false, vertical: true)
        .background(ZimeStyle.canvas)
        .foregroundStyle(ZimeStyle.ink)
        .font(.system(size: 11))
        .controlSize(.small)
        .tint(settings.color)
        .preferredColorScheme(.light)
    }

    private func durationRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack(spacing: 7) {
            Text(title)
            Spacer()
            TextField(title, value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 44)
                .accessibilityLabel("\(title)時間（分）")
                .onChange(of: value.wrappedValue) { _, newValue in
                    value.wrappedValue = min(range.upperBound, max(range.lowerBound, newValue))
                }
            Text("分").foregroundStyle(ZimeStyle.secondary)
            Stepper(title, value: value, in: range).labelsHidden()
                .accessibilityLabel("\(title)時間を調整")
        }
    }

    private func isSelected(_ preset: WindowPreset) -> Bool {
        settings.windowWidth == preset.size.width && settings.windowHeight == preset.size.height
    }

    private func applySize() {
        settings.windowWidth = min(1200, max(180, settings.windowWidth))
        settings.windowHeight = min(1200, max(220, settings.windowHeight))
        settings.applySize()
    }
}
