import SwiftUI

/// Gradient wash rendered behind every screen.
/// rose→lavender→sky (light) / plum→indigo→navy (dark).
struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: ThemeColors.for(scheme).gradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

/// Convenience: place an AppBackground behind any screen content.
extension View {
    func appBackground() -> some View {
        ZStack {
            AppBackground()
            self
        }
    }
}
