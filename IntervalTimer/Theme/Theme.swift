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
    let placeholder: Color
    let gradient: [Color]
    let glassFill: Color
    let glassBorder: Color
    let ringTrack: Color

    static let light = ThemeColors(
        dark: false,
        ink: Color(hex: "#3B3556"),
        inkMuted: Color(hex: "#3B3556").opacity(0.45),
        inkFaint: Color(hex: "#3B3556").opacity(0.2),
        placeholder: Color(hex: "#3B3556").opacity(0.3),
        gradient: [Color(hex: "#FFF1F2"), Color(hex: "#EDE9FE"), Color(hex: "#E0F2FE")],
        glassFill: Color.white.opacity(0.45),
        glassBorder: Color.white.opacity(0.85),
        ringTrack: Color.white.opacity(0.55)
    )

    static let darkTheme = ThemeColors(
        dark: true,
        ink: Color(hex: "#EAE6F7"),
        inkMuted: Color(hex: "#EAE6F7").opacity(0.45),
        inkFaint: Color(hex: "#EAE6F7").opacity(0.2),
        placeholder: Color(hex: "#EAE6F7").opacity(0.3),
        gradient: [Color(hex: "#221B36"), Color(hex: "#1C2038"), Color(hex: "#16222F")],
        glassFill: Color.white.opacity(0.08),
        glassBorder: Color.white.opacity(0.16),
        ringTrack: Color.white.opacity(0.12)
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
