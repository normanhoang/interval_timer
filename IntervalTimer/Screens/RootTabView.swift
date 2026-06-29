import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            WorkoutsScreen()
                .tabItem { Label("Workouts", systemImage: "bolt.fill") }
            HistoryScreen()
                .tabItem { Label("History", systemImage: "calendar") }
        }
    }
}
