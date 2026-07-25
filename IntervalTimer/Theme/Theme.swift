import SwiftUI

/// Appearance setting persisted in Settings (System / Light / Dark).
enum ThemeSetting: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "iphone"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }

    /// nil = follow the device (System).
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Colors for things a view modifier can't reach (icons, gradients, strokes,
/// placeholders). Mirrors the RN lib/theme.ts tokens. Resolve from the
/// environment color scheme: `ThemeColors.for(colorScheme)`.
struct ThemeColors {
    let dark: Bool
    let ink: Color
    let inkMuted: Color
    let inkFaint: Color
    /// Section kickers and other 45% labels.
    let inkLabel: Color
    let placeholder: Color
    let gradient: [Color]
    let glassFill: Color
    let glassBorder: Color
    let ringTrack: Color
    /// Card surfaces (workout rows, editor/settings groups, stat tiles).
    let cardFill: Color
    let cardBorder: Color
    let cardShadow: Color
    /// Accent (#A78BFA) and the tints/foregrounds derived from it.
    let accent: Color
    let accentText: Color
    let accentTint: Color
    let accentTintBorder: Color
    /// Foreground for glyphs/text sitting on a solid accent fill.
    let onAccent: Color
    let destructive: Color
    /// History streak hero.
    let flame: Color
    let streakTint: [Color]
    let streakBorder: Color

    static let light = ThemeColors(
        dark: false,
        ink: Color(hex: "#3B3556"),
        inkMuted: Color(hex: "#3B3556").opacity(0.5),
        inkFaint: Color(hex: "#3B3556").opacity(0.2),
        inkLabel: Color(hex: "#3B3556").opacity(0.45),
        placeholder: Color(hex: "#3B3556").opacity(0.3),
        gradient: [Color(hex: "#FFF1F2"), Color(hex: "#EDE9FE"), Color(hex: "#E0F2FE")],
        glassFill: Color.white.opacity(0.45),
        glassBorder: Color.white.opacity(0.85),
        ringTrack: Color(hex: "#3B3556").opacity(0.14),
        cardFill: Color.white.opacity(0.55),
        cardBorder: Color.white.opacity(0.85),
        cardShadow: Color(hex: "#3B3556").opacity(0.06),
        accent: Color(hex: Palette.primary),
        accentText: Color(hex: "#7C5CE0"),
        accentTint: Color(hex: Palette.primary).opacity(0.18),
        accentTintBorder: Color(hex: Palette.primary).opacity(0.5),
        onAccent: .white,
        destructive: Color(hex: "#E05B5B"),
        flame: Color(hex: "#F0913F"),
        streakTint: [Color(hex: "#FFB27A").opacity(0.30), Color(hex: Palette.primary).opacity(0.14)],
        streakBorder: Color(hex: "#FFB27A").opacity(0.6)
    )

    static let darkTheme = ThemeColors(
        dark: true,
        ink: Color(hex: "#EAE6F7"),
        inkMuted: Color(hex: "#EAE6F7").opacity(0.5),
        inkFaint: Color(hex: "#EAE6F7").opacity(0.2),
        inkLabel: Color(hex: "#EAE6F7").opacity(0.45),
        placeholder: Color(hex: "#EAE6F7").opacity(0.3),
        gradient: [Color(hex: "#221B36"), Color(hex: "#1C2038"), Color(hex: "#16222F")],
        glassFill: Color.white.opacity(0.08),
        glassBorder: Color.white.opacity(0.16),
        ringTrack: Color.white.opacity(0.15),
        cardFill: Color.white.opacity(0.075),
        cardBorder: Color.white.opacity(0.13),
        cardShadow: .clear,
        accent: Color(hex: Palette.primary),
        accentText: Color(hex: "#CDBDFC"),
        accentTint: Color(hex: Palette.primary).opacity(0.18),
        accentTintBorder: Color(hex: Palette.primary).opacity(0.5),
        onAccent: Color(hex: "#2A2140"),
        destructive: Color(hex: "#FFA1A1"),
        flame: Color(hex: "#FFB27A"),
        streakTint: [Color(hex: "#FFB27A").opacity(0.18), Color(hex: Palette.primary).opacity(0.10)],
        streakBorder: Color(hex: "#FFB27A").opacity(0.4)
    )

    static func `for`(_ scheme: ColorScheme) -> ThemeColors {
        scheme == .dark ? darkTheme : light
    }
}

extension EnvironmentValues {
    /// Convenience accessor so views can read resolved theme colors.
    var theme: ThemeColors {
        ThemeColors.for(colorScheme)
    }
}
