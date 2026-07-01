import SwiftUI

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        let theme = ThemeColors.for(scheme)

        VStack(spacing: 0) {
            ZStack {
                Text("Settings").font(.headline).foregroundStyle(theme.ink)
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundStyle(theme.ink)
                            .frame(width: 40, height: 40)
                            .glassChrome(radius: 20)
                    }
                    .buttonStyle(.pressableScale)
                    Spacer()
                }
            }
            .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 12) {
                    appearancePanel(theme, settings: settings)
                    toggleRow("Sound cues", "Countdown beeps and interval chimes",
                              isOn: $settings.soundEnabled, theme: theme)
                    toggleRow("Haptics", "Vibration taps on interval changes",
                              isOn: $settings.hapticsEnabled, theme: theme)
                    alertPanel(theme, settings: settings)
                }
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 40)
            }
        }
        .appBackground()
    }

    private func appearancePanel(_ theme: ThemeColors, settings: AppSettings) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("APPEARANCE", theme)
            HStack(spacing: 8) {
                ForEach(ThemeSetting.allCases) { option in
                    let active = settings.theme == option
                    Button { settings.theme = option } label: {
                        HStack(spacing: 6) {
                            Image(systemName: option.icon).font(.system(size: 13))
                            Text(option.label).font(.subheadline.weight(active ? .semibold : .medium))
                        }
                        .foregroundStyle(active ? theme.ink : theme.ink.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(active ? theme.glassFill.opacity(1.6) : theme.glassFill.opacity(0.5)))
                        .overlay(Capsule().strokeBorder(theme.glassBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16).panel()
    }

    private func alertPanel(_ theme: ThemeColors, settings: AppSettings) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("ALERT SOUND", theme)
            Text("Played on every interval change — tap to preview")
                .font(.subheadline).foregroundStyle(theme.ink.opacity(0.5))
                .padding(.bottom, 4)
            ForEach(Array(AlertSounds.all.enumerated()), id: \.element.id) { i, sound in
                let active = settings.alertSound == sound.id
                Button {
                    settings.alertSound = sound.id
                    Cues.shared.previewAlert(sound.id)
                } label: {
                    HStack {
                        Text(sound.label)
                            .font(.body.weight(active ? .semibold : .medium))
                            .foregroundStyle(active ? theme.ink : theme.ink.opacity(0.6))
                        Spacer()
                        if active {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(hex: Palette.primary))
                        }
                    }
                    .padding(.vertical, 10)
                    .overlay(alignment: .top) {
                        if i > 0 { Divider().opacity(0.4) }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16).panel()
    }

    private func toggleRow(_ title: String, _ subtitle: String, isOn: Binding<Bool>, theme: ThemeColors) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold)).foregroundStyle(theme.ink)
                Text(subtitle).font(.subheadline).foregroundStyle(theme.ink.opacity(0.5))
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(Color(hex: Palette.primary))
        }
        .padding(16).panel()
    }

    private func sectionTitle(_ text: String, _ theme: ThemeColors) -> some View {
        Text(text).font(.caption.weight(.semibold)).tracking(2)
            .foregroundStyle(theme.ink.opacity(0.4))
    }
}
