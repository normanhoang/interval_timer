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
            VStack(spacing: 2) {
                Image(systemName: icon).font(.system(size: 20))
                Text(label).font(.caption2.weight(.medium))
            }
            .foregroundStyle(active ? Color(hex: Palette.primary) : theme.inkMuted)
            .frame(width: 116, height: 46)
            .background {
                if active {
                    Capsule().fill(Color(hex: Palette.primary).opacity(0.18))
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
