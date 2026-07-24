import SwiftUI

struct RootTabView: View {
    @State private var selection = 0
    @Environment(\.colorScheme) private var scheme
    @Namespace private var highlightNS

    var body: some View {
        let theme = ThemeColors.for(scheme)
        ZStack {
            AppBackground()
            TabView(selection: $selection) {
                WorkoutsScreen().tag(0)
                HistoryScreen().tag(1)
            }
            .background(Color.clear)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .overlay(alignment: .bottom) { bottomBar(theme) }
        }
    }

    private func bottomBar(_ theme: ThemeColors) -> some View {
        HStack(spacing: 4) {
            tabButton(0, icon: "bolt.fill", label: "Workouts", theme)
            tabButton(1, icon: "calendar", label: "History", theme)
        }
        .padding(6)
        // Animates the matched-geometry highlight for both tap and page-swipe
        // selection changes (swipes mutate `selection` outside withAnimation).
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: selection)
        .glassChrome(radius: 30)
        .padding(.bottom, 6)
    }

    private func tabButton(_ index: Int, icon: String, label: String, _ theme: ThemeColors) -> some View {
        let active = selection == index
        return Button {
            withAnimation(.easeInOut(duration: 0.25)) { selection = index }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                Text(label).font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(active ? theme.accentText : theme.inkMuted)
            .frame(width: 132, height: 44)
            .background {
                if active {
                    Capsule().fill(theme.accentTint)
                        .matchedGeometryEffect(id: "tabHighlight", in: highlightNS)
                }
            }
            // Transparent frame area isn't hit-testable by default — without
            // this, taps land only on the icon/text glyphs.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
