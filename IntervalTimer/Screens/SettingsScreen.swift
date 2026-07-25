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
                Text("Settings").font(.system(size: 17, weight: .semibold)).foregroundStyle(theme.ink)
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
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
                    appearanceCard(theme, settings: settings)
                    cueCard(theme, sound: $settings.soundEnabled, haptics: $settings.hapticsEnabled)
                    runStyleCard(theme, settings: settings)
                    alertCard(theme, settings: settings)
                }
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 40)
            }
        }
        .appBackground()
    }

    private func appearanceCard(_ theme: ThemeColors, settings: AppSettings) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            kicker("APPEARANCE", theme)
            HStack(spacing: 10) {
                ForEach(ThemeSetting.allCases) { option in
                    let active = settings.theme == option
                    Button { settings.theme = option } label: {
                        Text(option.label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(active ? theme.accentText : theme.inkMuted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Capsule().fill(active ? theme.accentTint : theme.cardFill))
                            .overlay(Capsule().strokeBorder(active ? theme.accentTintBorder : theme.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16).card()
    }

    /// Sound + haptics share one card, split by a hairline.
    private func cueCard(_ theme: ThemeColors, sound: Binding<Bool>, haptics: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            toggleRow("Sound cues", "Countdown beeps and interval chimes", isOn: sound, theme: theme)
            Divider().opacity(0.4).padding(.horizontal, 16)
            toggleRow("Haptics", "Vibration taps on interval changes", isOn: haptics, theme: theme)
        }
        .card()
    }

    private func runStyleCard(_ theme: ThemeColors, settings: AppSettings) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            kicker("RUN SCREEN", theme)
            Text("How the timer looks mid-workout")
                .font(.system(size: 15)).foregroundStyle(theme.inkMuted)
                .padding(.bottom, 8)
            HStack(spacing: 10) {
                ForEach(RunStyle.allCases) { style in
                    let active = settings.runStyle == style
                    Button { settings.runStyle = style } label: {
                        VStack(spacing: 10) {
                            styleGlyph(style)
                            Text(style.label)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(active ? theme.accentText : theme.inkMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(active ? theme.accentTint : theme.cardFill))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(active ? theme.accentTintBorder : theme.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("runStyle.\(style.rawValue)")
                }
            }
        }
        .padding(16).card()
    }

    @ViewBuilder
    private func styleGlyph(_ style: RunStyle) -> some View {
        switch style {
        case .flood:
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(hex: Palette.work))
                .frame(width: 34, height: 22)
        case .ring:
            Circle()
                .strokeBorder(Color(hex: Palette.work), lineWidth: 3)
                .frame(width: 22, height: 22)
        }
    }

    private func alertCard(_ theme: ThemeColors, settings: AppSettings) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            kicker("ALERT SOUND", theme)
            Text("Played on every interval change — tap to preview")
                .font(.system(size: 15)).foregroundStyle(theme.inkMuted)
                .padding(.top, 4).padding(.bottom, 4)
            ForEach(Array(AlertSounds.all.enumerated()), id: \.element.id) { i, sound in
                let active = settings.alertSound == sound.id
                Button {
                    settings.alertSound = sound.id
                    Cues.shared.previewAlert(sound.id)
                } label: {
                    HStack {
                        Text(sound.label)
                            .font(.system(size: 17, weight: active ? .semibold : .regular))
                            .foregroundStyle(active ? theme.ink : theme.ink.opacity(0.7))
                        Spacer()
                        if active {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.accent)
                        }
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .overlay(alignment: .top) {
                        if i > 0 { Divider().opacity(0.4) }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16).card()
    }

    private func toggleRow(_ title: String, _ subtitle: String, isOn: Binding<Bool>, theme: ThemeColors) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 17, weight: .semibold)).foregroundStyle(theme.ink)
                Text(subtitle).font(.system(size: 14)).foregroundStyle(theme.inkMuted)
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(theme.accent)
        }
        .padding(16)
    }

    private func kicker(_ text: String, _ theme: ThemeColors) -> some View {
        Text(text).font(.system(size: 11, weight: .semibold)).tracking(1.5)
            .foregroundStyle(theme.inkLabel)
    }
}
