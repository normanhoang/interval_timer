import SwiftUI

/// Chrome/control surface (header buttons, run controls, tab pill).
/// Native Liquid Glass on iOS 26+, frosted material fallback below.
struct GlassChrome: ViewModifier {
    var radius: CGFloat = 20
    var bordered: Bool = true
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let theme = ThemeColors.for(scheme)
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: radius))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
                .overlay {
                    if bordered {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(theme.glassBorder, lineWidth: 0.5)
                    }
                }
        }
    }
}

/// Static content panel (workout cards, stat panels, rows). Translucent
/// fill + hairline border — NOT native glass (which draws an un-disableable rim).
struct Panel: ViewModifier {
    var radius: CGFloat = 24
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let theme = ThemeColors.for(scheme)
        content
            .background(theme.glassFill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(theme.glassBorder, lineWidth: 1)
            }
    }
}

extension View {
    func glassChrome(radius: CGFloat = 20, bordered: Bool = true) -> some View {
        modifier(GlassChrome(radius: radius, bordered: bordered))
    }

    func panel(radius: CGFloat = 24) -> some View {
        modifier(Panel(radius: radius))
    }
}
